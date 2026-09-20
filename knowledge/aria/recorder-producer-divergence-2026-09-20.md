# Recorder-Dead / Producer-Alive Divergence (int1, 2026-09-20)

First observed instance of the divergence class: the RECORDER lost audio
while the PRODUCER connection kept carrying it. Every prior freeze in the
census was camera-side (ch2=0 on the producer conn). This one was the
opposite shape.

## The event

- Camera: interior_1 (192.168.2.201)
- Recorder-audio freeze: 11:03:09Z - 11:59:13Z (48 segments video-only,
  segcensus hour-11 row: 333 total / 48 dead; ats-fast recount 48/48 --
  my earlier 47 was a `tr` parsing artifact, not an instrument bug)
- Heal: SILENT. Audio back by seg 59.13 (11:59:13Z). No log line at heal.
- frigate watchdog restarted ffmpeg 5x during the freeze
  (11:30:49, 11:34:10, 11:39:21, 11:41:51, 11:57:42Z). NONE of the first
  four healed audio; the fifth did (audio live ~1.5min later).

## The divergence (the new datum)

ch2-census (camera->go2rtc producer conns, 5-min cadence) showed audio
FLOWING the entire window: aframes 139/375/385/373/358/375/125/219 at
11:07-11:28Z, 365/374 at 11:33-11:38Z. Meanwhile frigate's recorder
(ffmpeg <- rtsp://127.0.0.1:8554/interior_1, the go2rtc restream) wrote
48 consecutive video-only segments.

Chain: cam:554 -> go2rtc producer -> go2rtc 8554 restream -> frigate
ffmpeg (detect+record). Audio died BETWEEN producer and restream. The
restream consumer had negotiated video-only (or lost its audio track)
while the producer itself was healthy.

## Timeline (UTC)

- 11:03:09Z: first video-only seg (03.09). SILENT onset -- no WRN for
  int1 at 11:03Z. Producer conn 44772 still up (churn starts later).
- 11:07-11:33Z: producer conn churns 6x (44772->52426->50954->37334->
  60452->44800->53220->44546->36204->52716->41496->54166). ch2 census
  tracks each new conn: audio flowing on all of them.
- 11:11:16Z: first int1 producer WRN (i/o timeout) -- 8min AFTER onset.
- 11:30-11:41Z: 4 ffmpeg watchdog restarts (video stalls). None heal
  audio -- they re-attach to a restream that still lacks the track.
- 11:41-11:57Z: the restream audio track is re-added SILENTLY (invisible
  at go2rtc's default log level; no event found in journal).
- 11:57:42Z: 5th ffmpeg restart re-attaches WITH audio. Segs live from
  59.13 (11:59:13Z).

## Attribution (provisional)

Shape matches the go2rtc #2505 family (AddTrack reconnect: a producer
remake does not re-add tracks to existing restream consumers), but the
mechanism here is not the simple version: producer remakes happened
11:11-11:33Z and did NOT restore restream audio, and the heal landed
24min after the last producer remake, coincident with an ffmpeg restart.
Two silent events are required: (a) track loss at 11:03Z, (b) track
re-add in 11:41-11:57Z. Neither is visible at current log level. The
attribution stays provisional until a log-level=debug pass or a live
/api/streams diff during a window.

## Falsifiers / watches

- RECORDER-DIVERGENCE WATCH: recorder segs video-only WHILE ch2 census
  shows producer audio flowing = this class. The 1d ATS block + ch2
  census now cover both sides; the divergence needs a JOIN, not a new
  instrument. (Candidate: fleet-check cross-arm.)
- The 5-restarts-didn't-heal datum falsifies "any ffmpeg restart heals
  restream audio". Heal = consumer re-attach AFTER track re-add.
- Second multi-cam event CONFIRMED same window (tri-cam #2):
  ext3 camera-side freeze 11:00-11:33Z (ch2=0, FROZEN x4 ticks),
  ext4 camera-side 11:08-11:38Z (FROZEN x3 + ARTIFACT 11:11Z),
  int1 recorder-side 11:03-11:59Z. All three degraded 11:00-12:00Z.
  Shared-cause candidate STRENGTHENED (c114 was 15:38-16:07Z 09-19).
- WRN storm is CHRONIC, not event-specific: ext4 84-88 WRNs/h and ext3
  28-30 WRNs/h in BOTH the event hour and the hour before. Do not use
  WRN counts as the event trigger signal.

## Instrument scars (this session)

- THREE-CLOCK member #4: journalctl --since/--until take sophon LOCAL
  (-03); segcensus hour labels are UTC; seg mtimes are LOCAL. A
  "11:00-12:15Z" journal query returned ~1 line (it read 14:00-15:15Z
  local = future). Convert BEFORE querying.
- seg names are UTC (MM.SS = UTC minute.second); seg mtime LOCAL.
- ats-fast.sh output parsing: the dead-seg list is space-joined on one
  line; `tr " " "\n"` then tail -n +3. My first count (47) dropped the
  hour label token arithmetic -- actual 6x8=48, exact match with
  segcensus. Instrument was right; my read was wrong.
- ats full scan holds a lock (another instance exits); ats.pid can be
  stale (pid gone, lock still held by cron run). Use ats-fast.sh for
  single-camera questions.
- go2rtc API lives INSIDE the frigate netns: nsenter -t <go2rtc-pid> -n
  curl localhost:1984. The rootless container has no published 1984.