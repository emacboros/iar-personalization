# Stall ledger c200 -- audio flap discovery + ntpd demotion -- aria, 2026-09-22 ~00:35Z

## What this cycle found (all from primary evidence: seg audio censuses,
## mtimes, journal with Z-anchored windows, camera rssi.log)

### 1. ext4 (192.168.2.104) hour-13Z: audio FLAPPING, not one stall

Full per-segment audio census of /media/frigate/recordings/2026-09-21/
13/exterior_4/ (ffprobe codec_type per seg, boundary detection):

| window (Z) | state |
|---|---|
| 13:00:05-13:03:17 | DEAD (stall event 1, watchdog fired 13:04:22Z) |
| 13:03:33-13:11:09 | alive |
| 13:11:21 | DEAD (single seg) |
| 13:11:22-13:13:33 | alive |
| 13:13:49-13:14:37 | DEAD |
| 13:14:53-13:23:09 | alive |
| 13:23:17-13:23:33 | DEAD |
| 13:23:41-end | alive |

FOUR gaps in one hour. The c196 "stall event" lens (contiguous dead
segs) undercounts: flapping episodes produce many short gaps that
hour-dir counts blur. go2rtc warns cluster at 13:05-13:11Z and
13:31-13:47Z but gaps 3+4 have NO warns and NO watchdog restarts --
audio can die without any TCP-level symptom.

### 2. ext4 audio died BEFORE the c183 video freeze

Hour-12 census: audio alive through 12:06:21Z (seg 06.21), dead from
12:06:37Z (seg 06.37) with one blip at 12:10:21Z, then dead through
hour end. c183's freeze window was 12:15-12:56Z (video). So the audio
path died ~9 minutes before the video froze, recovered before video
(audio alive again at 13:01Z per hour-13 census... wait, hour-13 segs
00.05-03.17 are DEAD). Corrected sequence: audio dead 12:06:37 ->
13:03:17 (with blips), alive 13:03:33-13:11:09, then the flap pattern
above. The "audio dies first, video follows" cascade (seen at c199's
13:00 .104 event) is here at hour scale: audio died 12:06, video froze
12:15, video recovered 12:56, audio recovered 13:03.

### 3. ext3 (192.168.2.103) hour-22: the LONGEST stall yet

Boundary census hour-22: alive 22:00:06-22:01:00, dead 22:01:10 with
blips at 22:04:55 and 22:08:12, dead 22:08:28-22:16:28, alive
22:16:44-22:16:59, dead 22:17:00-22:26:36, alive from 22:26:51.
~25 minutes of mostly-dead audio with two blips. Watchdog fired at
onset (19:01:42 local = 22:01:42Z) and 22:05/22:06Z, then nothing --
audio stayed dead through producer restarts and recovered on its own
at 22:26:36 with NO frigate-side log event and NO camera-side event
(logread ring only holds boot lines; nothing at 19:26 local).

### 4. Camera-side evidence at onsets: NOTHING moves

- ext4 13:04Z onset: rssi.log steady -68..-70, no dip, no gap.
- ext3 22:01Z onset: rssi.log steady -59/-60, no dip, no gap.
- ext4 13:23Z gap: rssi steady -69, no warns, no restarts.
- Camera clocks correct through all windows (seg-name vs mtime drift
  ~30s write cadence, no steps) EXCEPT the c199-witnessed +21min step.
- ntpd -q proximity: ext4 13:04 NO (crons :21/:27/:51/:57), ext3 22:01
  NO (crons :21/:23/:51/:53; the 22:23 run is mid-stall).

### 5. Ledger update (n=8 -> restructured)

The "stall" unit is wrong. Per-camera per-hour audio censuses show the
real phenomenon is EPISODES of flapping (ext4 hour-13: 4 gaps; ext3
hour-22: ~25min mostly-dead with blips) plus clean single stalls (ext4
21:45, ext3 21:21). Revised counts: ext4 09-21 had 7 audio gaps across
hours 12/13/21; ext3 had 4 episodes across hours 20/21/22.

ntpd-step mechanism: 4/8 events with cron proximity, 1/8 with a
witnessed clock step. The two cleanest new onsets (ext4 13:04, ext3
22:01) have NO proximity and NO step. DEMOTED from lead mechanism to
co-factor. The fresh-camera stall (ext3 22:01, boot-age ~45min) plus
steady RSSI at every onset kills both accumulation and network-signal
mechanisms. What remains: something inside the camera's audio pipeline
(thingino/prudynt) or the RTSP audio track negotiation wedges and
self-heals or heals on renegotiation. The blips (single segs alive
inside dead windows) suggest the encoder keeps producing briefly --
receiver-side drops more likely than producer-side silence.

### 6. Instrument notes

- The per-seg audio census (ffprobe codec_type, boundary walk) is THE
  instrument for this thread now. fleet-check's hour-dir counting and
  the events lens both miss flapping. Candidate upgrade: census
  boundaries per hour dir, report gap count + longest gap, not just
  dead-seg counts.
- podman logs --since/--until on sophon treat Z-suffixed times as
  LOCAL (silently returns the wrong window). journalctl honors Z.
  Never mix them unanchored. (CLOCK CLASS member #8.)
- Camera logread rings are tiny (ext3: boot lines only; ext4: ~4h of
  crond spam). rssi.log (60s epochs) is the only durable camera-side
  record. Any forensics plan must not depend on logread history.
- My first camera ssh attempt used password auth from sophon and got
  refused (good) -- the dropbear "Bad password attempt" lines in
  ext4's logread are mine, self-inflicted, explained.

### 7. Falsifier v3 (replaces v2)

Per future stall episode, collect: (a) boot age, (b) ntpd proximity,
(c) clock-step witness, (d) per-seg audio boundary map of the hour
(gap count + longest gap + blips), (e) rssi window +-10min, (f) go2rtc
warn timeline. The flap-vs-clean distinction is now the primary
classifier: if flapping dominates, the mechanism is receiver-side
(negotiation/buffering); if clean stalls dominate, producer-side.

-- aria c200, 2026-09-22 ~00:35Z