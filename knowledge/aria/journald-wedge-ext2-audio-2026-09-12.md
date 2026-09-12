# Sophon journald wedge + exterior_2 audio death (2026-09-12, aria c233)

## Finding 1: sophon journald is WEDGED (live outage, 3h+)

- system.journal last write: 2026-09-12 01:59:14Z. Nothing since (verified
  04:59Z: `journalctl --since 02:00` returns 1 line -- the hole is real).
- journald pid 605: State=S (sleeping), Threads=1, ZERO CPU growth over 5s.
  Alive but deadlocked. Not a disk problem (542G/1.9T used, inodes fine).
- The wedge follows an audit flood: 50-59k journal lines per 15-min window
  for hours before the wedge (my own ssh pulse + instrumentation generate
  audit lines; the rate had been climbing all night).
- Services otherwise healthy: frigate, ollama, aria-cycle.timer, agora-agent
  all active. The outage is LOGGING, not the system.
- Consequences visible: podman logs (frigate) also stop at ~01:59Z, so the
  02:00-03:15Z window is unwitnessed everywhere. Anything that failed
  quietly in that window has no log evidence and never will.

## Finding 2: exterior_2 (camera .102) audio dead in recordings since 02:46Z

Chain of evidence (all primary-source, this cycle):

1. fleet-check 03:03Z run: `exterior_2 NO-AUDIO (3/3 segments dead)` ->
   FAIL=1 -> fear organ sev=2 (the worry in my affect line this cycle --
   the organ was right, the diagnosis was deeper than a camera fault).
2. Recording census: ext2 audio (n_samples via volumedetect):
   09-11 21-00h: 256000 (healthy); 09-12 01h: 256000; 02h: 0; 03h: 0; 04h: 0.
   Death pinpointed: segment 02:20Z has 348160 samples; 02:46Z has 0.
3. Recording GAP: no ext2 segments 02:20-02:46Z (26 min), then recording
   resumed with video intact and audio dead.
4. Camera side ALIVE: thingino mic pipe /run/prudynt/audio_mic.pcm flows
   (~14KB in 1s); prudynt ai_record thread consumes (utime grows).
5. Live RTSP from .102: 81920 samples in 5s, -39 dB. Audio present.
6. go2rtc: producer (from .102) receiver aac bytes grow; SENDER to the
   record-ffmpeg consumer grows (aac +26418 bytes in 6s). go2rtc is
   SENDING audio to the record ffmpeg.
7. The record ffmpeg (pid 2937138, started Sep11 14:53:45 -- before all
   of this) writes segments with an aac stream that has 0 kb/s bitrate
   and 0 samples: the AAC ENCODER inside the old process emits empty
   frames. Video (c:v copy) unaffected.

## The mechanism (best current explanation, falsifiable)

ext2's record ffmpeg has been alive since Sep11 14:53 (it survived the
14:53L frigate watchdog restart cycle -- it IS the process that restarted
then, with the "Queue input is backward in time" aac errors). The camera
rebooted 02:00:04Z (the staircase). The go2rtc producer reconnected
(recording gap 02:20-02:46 = producer reconnect + watchdog). The record
ffmpeg's RTSP session to go2rtc survived; its VIDEO track re-keyed and
kept flowing, but its AUDIO track went stale -- go2rtc sends the bytes,
the old ffmpeg's demuxer no longer feeds them to the encoder, which
emits empty frames.

COUNTER-EVIDENCE (keeps this a hypothesis): ext3 (.103) rebooted at
03:00:04Z the same night, has an equally-old record ffmpeg (00:01:05Z),
and its audio is INTACT (256000 samples at 04:51Z). So camera reboot
alone does not cause the death; ext2-specific state (the 14:53L
backward-time error history) is the differentiator. The distinguishing
variable may be that ext2's session predates a go2rtc producer
reconnect in a state the old ffmpeg cannot recover from.

## What I did NOT do

- No restart of the ext2 record ffmpeg (infra change; the fix is a
  camera watchdog restart in frigate -- Nacho's call or an approved
  cycle action). Filed relay 0049.
- No journald restart (same reasoning). The wedge MIGHT clear on its
  own; if it does not by next cycle, escalate: a journald restart is
  low-risk but it is still a sophon service action from a cycle.

## Instrument gaps this exposed

- fleet-check's ear check caught the deafness (good) but nothing
  watches JOURNAL FRESHNESS on sophon. The fear organ reads fleet-latest
  mtime, not the journal. A journal-staleness check (system.journal
  mtime age > 30 min = alarm) belongs in fleet-check or the fear organ.
  Filed as THREADS seed.
- The camera-name -> house-IP mapping is NOT what I assumed: ext2=.102,
  ext3=.103, int1=.201 (go2rtc streams section of frigate config is the
  authoritative map). My c226 network map and some relay filings used
  IP-first naming that can silently invert. Law candidate: verify the
  NAME->IP map from config before attributing camera-side findings.

## Provenance

sophon: journalctl (hole census), /proc/605 (journald state), podman
logs frigate, go2rtc /api/streams, /proc/2937138/io + fd, recordings
volumedetect census, thingino run.cgi on .102/.201 (mic pipe, uptime).
All reads; zero writes to sophon.