# interior_2 producer-audio-freeze -- second instance of the silent-freeze class

Cycle c381, 2026-09-17 ~04:00Z. Found via the standing falsifier watch
(c374: ext2 self-heal watch + producers.log accumulation), not via an
alarm: fleet-latest 03:00Z showed int2 NO-AUDIO 3/3 + producer-audio-freeze
WATCH run 1, and I pulled the thread to root-cause it same-cycle.

## The finding

interior_2 (.202) audio died at **02:47:11Z Sep 17 = 23:47:11 local Sep 16**,
mid-stream, with zero frigate log lines about interior_2 in any window I
queried (20:00 local Sep 16 -> now). Video kept flowing the whole time.
Evidence chain:

- Recorder segments (host-side ffprobe, ground truth):
  - h00 UTC (21-22 local): 225/225 WITH audio
  - h01 UTC (22-23 local): 234/234 WITH audio
  - h02 UTC (23-00 local): 176 WITH / 49 WITHOUT -- death inside this hour
  - h03 UTC (00-01 local): 225/225 video-only
  - h04 UTC (01-02 local, partial): 21/21 video-only
  - First no-audio seg: 47.11.mp4 (02:47:11Z); last with audio: 46.47.mp4
    (02:46:47Z). Death is sharp, between those two segment boundaries.
- frigate.db recordings table: int2 rows CONTINUOUS through the death
  (529 recordings since 00:53Z, no gap) -- recorder healthy, writing
  video-only segments. DB-BEFORE-DERIVED held: the recordings table
  agreed with the filesystem once I probed the right hour dir.
- go2rtc producer: 6069, alive, SDP advertises 1 video + 4 audio tracks
  (AAC x2, PCMU, PCMA). Producer replaced 5715->6069 between the h00
  probe (22:33 local) and h01 probe (23:05 local) -- BEFORE the death.
  The new producer ran ~40 min with audio, then its audio froze at
  23:47 local while video continued.
- fleet-check 03:00Z: "producer audio stuck (delta=0B/4s), video flowing
  (49542B), recorder segments 0 samples" -- the bytes-delta instrument
  sees the freeze directly.

## The instrument gap: producers.log verifies the OFFER, not the DELIVERY

The segcensus puller's producers.log row for h02 (probed 00:05 local,
18 min AFTER the death) says `interior_2 6069 audio-yes` -- while the
segcensus row in the SAME RUN says `225 49` (49 dead). Two instruments,
same service, same hour, disagreeing. The producers.log probe reads the
go2rtc producer's SDP, which is negotiated at connect time and frozen:
it advertises audio tracks forever, whether or not audio RTP packets
flow. SDP-yes is a claim about the offer; the segcensus is a measurement
of the delivery. LAW 50 family (verify what the instrument actually
measures), new member: **SDP-ADVERTISED != PACKETS-FLOWING**.

Fix (next cycle, my instrument): producers.log should either (a) do the
bytes-delta check fleet-check does, or (b) cross-reference its own
segcensus result and emit a STALE flag when sdp-audio-yes coexists with
recorder-side dead segments. Option (b) is nearly free -- the puller
already has both numbers in hand.

## Class status

This is the SECOND confirmed silent producer-audio-freeze:
- ext1 (.101): Sep 16 (0073, answered observation-only; healed ~12:41-15:00Z)
- int2 (.202): Sep 17 02:47Z, OPEN at cycle close

Class shape: camera's audio path dies mid-stream (prudynt encoder or
upstream), RTSP session stays up, video flows, frigate watchdog sees
video => declares healthy, no error logged anywhere. Only the recorder
segments (or a bytes-delta probe) can see it. Heal path per c374
experience: frigate watchdog restart (ext5 needed it; producer
replacement alone did NOT heal ext5) -- but here the producer was
already fresh (6069 born before the death), so a producer replacement
would predictably NOT heal. The remaining heal paths: camera reboot or
frigate restart. Both are infrastructure actions = Nacho's under the
observation-only ruling (0073/0075).

## Falsifiers (armed)

1. **.202 nightly reboot** (if it reboots at 03:00 local like the
   fleet): 06:00Z. If audio returns in h04/h05 UTC segs -> camera
   runtime state, self-healing class. If not -> deeper (power-cycle
   class, like .104).
2. **fleet-feed 06:00Z**: escalates WATCH run 1 -> PRODUCER-AUDIO-FROZEN
   run 2 (2nd consecutive run).
3. **segcensus h03 row** (puller was mid-run at cycle close): will show
   int2 225 225 -- completing the h03 evidence.
4. **producers.log h03 row**: predicted to say audio-yes again (SDP) --
   the contradiction repeats until the probe is fixed.

## Method notes (what made this fast, what wasted calls)

- The TZ law fired AGAIN (c374's law): sophon journal is LOCAL -03,
  frigate internal timestamps are UTC, recordings hour-dirs are UTC.
  I burned ~15 calls querying journal windows in the wrong clock before
  reconciling. The law is in the roadmap; the miss was applying it to
  the PODMAN LOGS layer too (podman logs timestamps = frigate UTC;
  journalctl timestamps = local). THREE clocks on one box now: journal
  local, frigate UTC, recordings-dir UTC.
- Loop-guard fired 5x (same-arg x3 + chain x2) during the log-window
  enumeration. The right tool was ONE batched pull of the full frigate
  log to /tmp + local grep -- which is what finally answered everything.
  The INSTRUMENT-TAX cousin: LOG-PULL-TAX. Pull the whole log once,
  grep locally; never enumerate journalctl windows one query at a time.
- su - nacho needed for podman (rootless); runuser/sudo -u fail on
  chdir. machinectl shell works. Keep the recipe.
## Amendment (c382, 2026-09-17 ~04:45Z): falsifier 1 timing CORRECTED + camera-side audio verified ALIVE

The c381 falsifier said "if .202 takes its 03:00-local reboot". WRONG
TIMING. The cameras reboot on a STAGGERED cron schedule, one per hour:

- .201: `0 6 * * * reboot -f` (06:00Z = 03:00 local)
- .202: `0 7 * * * reboot -f` (07:00Z = 04:00 local)
- .203: `0 8 * * * reboot -f` (08:00Z = 05:00 local)

Verified three ways: crontab on each camera, /proc/uptime arithmetic
(.202 booted 2026-09-16 07:00:10Z, uptime 78381s at 04:46:31Z), and
the rssi.log uptime column (monotonic within each boot epoch, resets
at the daily reboot). The reboot line has no aria marker -- it predates
my 09-11 cron additions (ntpd + rssi are marked). Deliberate stagger
design: never all three down at once.

Consequences for the falsifier schedule:
- fleet-feed 06:00Z run2: escalates WATCH -> PRODUCER-AUDIO-FROZEN
  (as predicted -- the freeze is still live at that point).
- int2 reboots 07:00Z. Producer 6069 dies with the connection; frigate
  reconnects; new producer born.
- segcensus h07 row (10:05Z pull) + fleet-feed 09:00Z: if audio returns
  in h07+ segments -> camera-runtime state, self-healing class, case
  CLOSES as self-healed. If still dead -> power-cycle class (like
  .104), escalate.

### New evidence this cycle (strengthens the go2rtc-side freeze theory)

1. **Camera-side audio is ALIVE right now.** Fresh RTSP connection to
   .202 (ffmpeg -map 0:a, 8s): 249KiB of audio decoded, no errors.
   The camera's prudynt encoder is producing audio fine. The freeze is
   in go2rtc producer 6069's audio receiver, not the camera.
2. **bytes_recv delta confirms**: producer 6069's video receiver grew
   47086352 -> 47133145 (+46793 in 20s) while the audio receiver sat
   frozen at 11998063 bytes across the same window. Video flows, audio
   does not, TCP session alive (no read-timeout since 01:59:39Z).
3. **No log trace of the death anywhere**: frigate journal (0 int2
   lines since 15:48 local restart), go2rtc log endpoint (7 read-timeout
   lines for .202 in 10h, NONE at 02:47Z), camera logread (only
   DayNight switches; prudynt PID 764 unchanged since May 25 boot).
   The audio receiver froze silently -- same shape as ext1 (0073).
4. **Producer 6069 born ~01:05-01:31Z** (5715->6069 between h00 and h01
   probes; the 01:31:06Z read-timeout is the likely replacement
   trigger). It ran ~75-100 min with healthy audio, then froze at
   02:47:11Z. Producer born BEFORE death => replacement-won't-heal
   CONFIRMED for this instance (ext5 class). Heal paths: camera reboot
   (07:00Z today, free) or frigate restart (Nacho).
5. **h04 partial census**: 183/183 video-only (through 04:40Z). The
   freeze is 1h53m old and holding.

### Instrument note (v1.2 STALE flag is live)

The segcensus-puller v1.2 STALE cross-reference landed this cycle
(commit 1153d07b, sophon tree pulled). Next producers.log rows for
int2 will carry STALE-ALL (audio-yes + full-hour dead) until the
reboot heals. The h03 row (probed 04:05Z) was the last 5-field row.
