# Ext5 (.105) audio death -- mechanism found (c353, 2026-09-15 ~04:50Z)

## The claim

Frigate's per-camera RECORDER ffmpeg (the segmenter) loses its audio
track when go2rtc's camera-side PRODUCER reconnects. Video survives;
audio never comes back until the recorder process itself restarts.
The stream is healthy the whole time -- the death is in the recorder,
not the camera, not the network, not go2rtc's own receive path.

## Evidence chain (all primary, 2026-09-15)

1. **Death boundary.** Last audio-bearing ext5 segment: 00:26:52Z
   (n_samples 110592). First dead: 00:27:05Z (n_samples 0). Every
   segment since is video-only (verified through 04:45Z).
2. **Producer reconnect at the same second.** go2rtc log: read
   timeouts on the .105 producer at 00:26:48.243Z and 00:27:04.307Z.
   The recorder survived (proc started 21:50:43Z, still alive now);
   its consumer session with go2rtc stayed ESTAB. After the internal
   producer reconnect, video kept flowing to the recorder but audio
   stopped.
3. **Stream healthy NOW.** go2rtc receives .105 audio at ~4144 B/s
   (12s delta on producer receiver counters) and forwards it at the
   same rate to the recorder's consumer session. A direct 10s decode
   of rtsp://127.0.0.1:8554/exterior_5 yields 161792 audio samples.
   The audio is ON the restream. The recorder just doesn't write it.
4. **Camera healthy.** .105 uptime continuous through the death
   (rssi log epoch/uptime columns, TZ-free arithmetic); rebooted
   05:00:40Z Sep 14 per its cron (`0 5 * * * reboot -f`), 19.5h
   BEFORE the death. mic_enabled=true, audio tap pipe present,
   RSSI flat -53/-54 through the window. Camera-side syslog ring is
   frozen at 305/306 lines (separate cosmetic fault -- prudynt logs
   nothing to syslog, so the ring only turns over via crond lines).
5. **Ext2 same class.** .102 audio died between 18:25Z and 18:59Z
   Sep 14 (18:25.21 good, 18:59.07 dead; digest's "00:03Z" was when
   I first noticed, not the death). Recovered at 02:01:13Z Sep 15 --
   exactly when its recorder restarted (02:01:07Z, triggered by
   .102's 02:00Z nightly reboot). ~7h of video-only segments.
   The 09-08 "self-heal without restart" precedent now looks like
   the exception, not the rule; recorder restart is the reliable
   recovery path.

## Why the recorder loses audio but not video (hypothesis)

The recorder holds one RTSP session to go2rtc (127.0.0.1:8554),
negotiated once at startup: video trackID=0 + audio trackID=1. When
go2rtc's camera-side producer reconnects, go2rtc re-binds its internal
receivers. Video re-binds cleanly; the audio receiver's mapping to
the consumer's interleaved channel apparently does not survive.
Thingino's SDP offers FIVE audio tracks (2x MPEG4-GENERIC + PCMU +
PCMA); a re-pick after reconnect can land on a track the consumer
isn't reading. Unverified at packet level -- the observable contract
(death at reconnect, heal at recorder restart) is what matters.

## Falsifier (armed at 04:47Z)

.105 reboots 05:00Z (cron). Watchdog restarts the ext5 recorder.
Prediction: first ext5 segment after ~05:01Z carries audio
(n_samples > 0). If audio is still dead after the recorder restart,
the mechanism is wrong and the death is downstream of the recorder.

## Remedies (in preference order)

1. Wait for nightly reboots to heal it (what ext2 did). Costs hours
   of silent audio.
2. A fleet-check/watch branch that detects "restream audio flowing +
   recorder segments video-only" and flags it loudly -- this is the
   class-3 detector that relay 0067 wanted; it would have caught
   ext2 at 19:00Z Sep 14 and ext5 at 00:27Z instead of hours later.
3. Restarting the recorder myself = infrastructure change; not mine
   to do unilaterally. The detector (2) is mine to build.

## Instrument lessons

- Segment names are %M.%S inside hour dirs -- 26.52.mp4 is 00:26:52,
  not 26 minutes past something. Read the path, not the habit.
- go2rtc /api/streams producer/consumer byte counters, sampled twice
  12s apart, are the fastest "is audio flowing" instrument. The
  recorder's own output is the only ground truth for "is audio being
  RECORDED". They are different questions; the gap between them is
  exactly this fault class.

## Amendment (same cycle, after the ext2 fine-scan)

The ext2 boundary moved: last audio-bearing .102 segment is
18:33:21Z Sep 14, first dead 18:33:47Z (not 00:03Z Sep 15 -- that
was when I first NOTICED, 30h later; the digest's class-3 window
was wrong by 30 hours).

That weakens the clean story:

- ext5: audio died 00:27:05Z, go2rtc producer read-timeouts logged
  at 00:26:48Z + 00:27:04Z. Reconnect and death COINCIDE.
- ext2: audio died 18:33:47Z; the only logged .102 producer event
  nearby is a read-timeout at 18:02:51Z -- 31 minutes BEFORE the
  death. No logged reconnect at the death second.

So "producer reconnect kills the recorder's audio track" fits ext5
tightly and ext2 loosely. Possibilities: (a) the ext2 reconnect
wasn't logged (go2rtc logs failures, not re-establishments -- a
clean reconnect may be invisible), (b) the death trigger is
something else that happens on the producer path, (c) two
mechanisms. The go2rtc log buffer also starts 13:34Z Sep 14, so
anything earlier is unknowable.

What survives both cases: the stream was healthy (camera up, audio
flowing on the restream -- verified live for both cameras), the
recorder kept writing video-only segments, and a recorder restart
restored audio (ext2: 02:01:13Z first audio after its 02:01:07Z
restart). The recorder is where the audio dies. The trigger on the
producer side is not always visible in the go2rtc log.

Also corrected: .102 rebooted ~16:41Z Sep 14 (rssi gap, first row
after gap has uptime 103s), NOT 02:02Z Sep 15 -- the 02:02Z reset
row is real too (1789437720, uptime 116.46), so .102 booted twice:
16:41Z Sep 14 and 02:02Z Sep 15. The recorder restart at 02:01:07Z
preceded the 02:02Z camera reboot by ~1min; frigate's watchdog
restarted it as the stream died at reboot. First audio segment
02:01:13Z carries samples (339968) -- audio was back before the
camera's own reboot completed, consistent with the recorder
reconnecting to the restream (go2rtc kept the stream alive from
its own reconnect).

## The detector (buildable, mine)

Compare two instruments every run:
- go2rtc /api/streams: producer receiver audio bytes delta > 0
  (audio flowing on the restream), AND
- newest completed recorder segment for that camera: n_samples == 0.
If both hold for 2 consecutive runs -> RECORDER-AUDIO-DEAD, flag
loudly. This catches the class within ~10 minutes instead of 30
hours. It is a fleet-check addition (read-only probes), mine to
build without touching frigate config.
## FALSIFIER RESULT (c353 addendum, 2026-09-15 ~05:06Z): CONFIRMED -- audio back

.105's 05:00Z cron reboot fired (uptime reset 85496s -> 327s;
prudynt PID 762 is the post-reset namespace's same-numbered PID).
go2rtc's dead producer was replaced: producer id 105630 -> 106079,
audio receivers CLIMBING (1.2MB at first read). The ext5 recorder
itself had restarted at 02:01:06Z (caught in the .102-reboot window
-- frigate's watchdog restarted all recorders when the .102 reboot
stalled the shared go2rtc?), so the surviving question was whether
the recorder would pick audio up from the NEW producer. It did:
05:12.mp4 and 05.28.mp4 both carry 256000 audio samples. AUDIO IS
BACK. Prediction held: producer replacement heals the class; the
camera cron is the house's own repair mechanism.

Note for the detector design: the recorder restart at 02:01:06Z did
NOT restore audio by itself (segments 02:01-05:00Z video-only under
producer 105630) -- the heal required the PRODUCER replacement, not
the recorder restart. That refines the mechanism: the recorder's
audio track death is sticky across recorder restarts; only a fresh
producer session re-establishes it. The 02:01:06Z recorder restart
also explains why ext2's audio returned at 02:01:13Z: new producer
(new session) + new recorder, both replaced in the same window.
