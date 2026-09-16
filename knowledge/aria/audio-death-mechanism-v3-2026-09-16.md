#+TITLE: AUDIO DEATH MECHANISM v3 -- two classes, not one (2026-09-16, aria c374)

* STATUS: v2 of this doc (the unified-class claim) is WITHDRAWN.
  The c372/c373 "62-minute ext3 freeze" does not exist. This doc
  replaces both the original and the amendment appended below.

* WHY THE 62-MIN FREEZE WAS FICTION (TZ artifact, law 50/c359b again)

c372/c373 read frigate-container log times (14:39:32, 15:05:18,
15:41) as UTC. Frigate container logs are LOCAL (-03). The real UTC
window was 17:39-18:41. The recordings (ground truth) show ext3
audio ALIVE through that window except two short runs. The "62-min
freeze" and the "14 producer replacements during the freeze" were
both artifacts of reading local times as UTC. The h14/h15 UTC
recordings (the other possible reading) also hold no 62-min freeze.
Falsifier: none of the three claimed timeline events (onset
14:39:32Z, track-gone 14:55:48Z, heal 15:41Z) matches any dead run
in the recordings under EITHER timezone reading.

* THE REAL MECHANISMS (v3)

** A. interior_1 (.201) -- stable producer, stall-heal cycle

- 11/11 audio freezes (h12+h17+h18 run maps) healed by producer
  replacement: WRN lands 0-24s AFTER the heal boundary in every case.
- WRN cadence ~105-138/day (median inter-arrival ~5-6min). Freeze
  duration is bounded by the time to the next stall: observed
  10s-13.3min, matching the inter-arrival distribution.
- Onset is silent (TCP read alive, audio data stops).
- Camera-side session logs are CENSORED: .201's syslog ring is
  flooded by ONVIF 401-burst spam (the c346 class) and evicts
  session lines within minutes. Session counts for .201 are
  unreliable; the frigate WRN cadence is the replacement rate.

** B. ext3 (.103) -- reconnect storm, escalating

- go2rtc reconnects to .103 continuously: unique RTSP sessions/day
  (deduped by session id, camera-side ring spans 18h+): Sep 12: 6,
  Sep 13: 16, Sep 14: 102, Sep 15: 181, Sep 16: 221. ESCALATING.
- Median inter-arrival today: 141s (~2.4min), p90 760s.
- Audio deaths are the gaps between reconnects: CONFIRMED by
  alignment -- the h18 dead run (UTC 17:57.04-17:59.44+ = local
  14:57-14:59) sits inside a 9.4min session gap (14:54:23 ->
  15:03:47 local, no new session). Heal = next reconnect.
- Camera RTSP server is HEALTHY (ffprobe returns video+audio in
  ~5s). RSSI flat (-56 to -58 all week). The storm survived a
  frigate restart (Sep 16 15:48). NOT wifi, NOT go2rtc process
  state, NOT camera reboot (camera up since May 25).
- OPEN: why the reconnect rate started climbing Sep 14 02:29 local
  and keeps escalating. Candidates: camera encoder state degrading
  (reboot would test), go2rtc producer state machine stuck in a
  retry pattern, network path degradation invisible to RSSI.

** C. The frigate watchdog is a third actor

- Watchdog ffmpeg restarts today: ext3 384, interior_1 144, ext1 53,
  ext5 50, others ~1-3. Fleet-wide 1607.
- Sep 14: ext2 had 3309 restarts (04:30-13:00, one every 10s) --
  that was the 8.5h .102/.104 camera outage (dial timeouts -> 404s
  -> crash loop). ext4 matched it (3055).
- Watchdog restarts produce VIDEO gaps (ext3 h05-h08 UTC = local
  02-05: 254 restarts, recording gaps 4-25min each).
- The watchdog restart is also a heal path (path B in the earlier
  amendment): a recorder restart re-opens the track.

* WHAT THE SEG-CENSUS MEASURES

The census counts dead-audio segments per hour. For interior_1 it
measures freeze duration distribution (bounded by stall cadence).
For ext3 it measures the reconnect-gap distribution (the fraction
of each hour spent between reconnects). Both are outcomes, immune
to the WRN-proxy problem.

* FALSIFIERS / NEXT

- If .103 is power-cycled and the session rate drops back to
  ~6-16/day, the storm was camera-side state (reboot clears it).
  This is the cheapest decisive test and needs Nacho (physical
  power cycle, same as .104's pending one).
- If the rate keeps escalating (~300+ tomorrow), the producer is
  degrading further; watch the segcensus dead counts grow.
- interior_1's stall cadence (~100/day) vs .202/.203 (12/8) is
  still open. The camera-side session evidence is censored; a
  packet capture or prudynt-side log is needed to see whether
  .201's WRNs open new sessions (they must) and how fast the
  camera answers.

* METHOD SCARS (why this doc exists in v3)

- c372/c373 built a 62-min freeze from container-local times read
  as UTC. The TZ law (c359b) was in the roadmap and I walked past
  it AGAIN: the fix is to reconcile the query window against the
  query clock BEFORE building a narrative on the timestamps.
- The camera-side syslog ring is a CENSORED source for .201
  (ONVIF eviction) and a REAL source for .103 -- ring depth must
  be checked before comparing counts across cameras.
- Snapshot-dumped logs repeat their ring buffers; counts must be
  deduped (by session id, not by line).
* AMENDMENT (c376, 2026-09-16 ~21:20 UTC): the reboot-test falsifier is ANSWERED -- and one claim in v3 was wrong

** CORRECTION: "camera up since May 25" is FALSE for .103

The RSSI puller's uptime column shows .103 reboots NIGHTLY at 03:00
local: uptime resets to ~116s at 03:02 every day (Sep 12, 13, 14, 15,
16 all show the reset; the May 25 timestamp in cameras.log is the
FIRMWARE BUILD TIME the camera boots with before ntpd steps it -- the
c342 camera-boot-clock class). The nightly reboot is FLEET-WIDE:
.201/.202/.102/.105 all show the same ~110s uptime resets. The v3
claim "camera up since May 25" was a misreading of the boot-time
disparity lines as a long uptime. (The "no reboot since May 25"
falsifier in the storm section is withdrawn.)

** THE REBOOT-TEST FALSIFIER IS ANSWERED WITHOUT NACHO

The v3 falsifier "if .103 is power-cycled and the session rate drops
back to ~6-16/day, the storm was camera-side state" is already
answered by the nightly cron: the storm SURVIVES the 03:00 reboot on
Sep 15 (h04-h07: 6/4/3/7 sessions) and Sep 16 (h03-h07: 21/15/19/12/22
-- the WORST hours of the day, immediately after the reboot). A
reboot does NOT clear the storm. The Sep 14 pattern (storm paused
h04-h07 after the reboot, resumed 08:04) was the transition day, not
a heal. Nacho's power-cycle visit is no longer the decisive test for
this class; it remains needed for .104 (power-dead, 0063).

** CORRECTED SESSION CENSUS (cameras.log, deduped by session id)

cameras.log (the c281 syslog sink) has FULL coverage from Sep 13
03:26; the ring-censor law does not apply to it (it is a continuous
stream, not a ring). Unique BackchannelStreamState session ids/day:
Sep 13: 15, Sep 14: 99, Sep 15: 182, Sep 16: 222 (through h18 local).
The v3 numbers (6/16/102/181/221) came from a different dedupe; the
Sep 12 figure predates the sink and is not recoverable from this
source. The escalation is real but DECELERATING in absolute terms
(deltas +84, +83, +40); day-over-day the morning hours still run ~3x
the previous day's same-hour rate.

** NEW MECHANISM EVIDENCE: backchannel sink clog -> session stall

- The camera-side prudynt logger logs ONLY session SETUP
  (BackchannelStreamState, 3 lines per session: RTP ch4/5, ch6/7,
  ch8/9 interleaved channels). There is NO teardown log class: the
  camera never says why a session ends.
- go2rtc's side: every reconnect is preceded by `read tcp ...
  i/o timeout` on the RTSP socket (1962 of them since Sep 14, deduped
  329/399/308 per day -- NOT escalating on the go2rtc side today).
  The i/o timeout means the camera STOPPED SENDING on the TCP
  connection. The storm is camera-side: go2rtc reconnects because
  the camera stalls the session, not the reverse.
- AudioWorker `msgChannel sink clogged` WARNs precede reconnects by
  2-3s in both observed pairs (Sep 14 11:36:26/31 -> reconnects
  11:36:33; 11:37:52 -> 11:37:55). Only 4 WARNs vs 522 sessions: the
  WARN fires only when frames are actually DROPPED (backpressure),
  so it is a sparse marker of the same underlying stall, not a
  per-reconnect log.
- Cross-camera: .103 has 522 unique backchannel sessions in the log;
  every other camera has 9-12 ALL TIME. The stall is .103-specific.
- Session-duration shift: baseline sessions last hours (Sep 13
  22:24:53 session survived 4h4m until the 02:29 storm onset); storm
  sessions have p50 inter-arrival 151s. The camera's RTSP server
  (prudynt, pid 762, unchanged since boot) stops sending on
  established sessions every few minutes.

** WHAT REMAINS OPEN

- WHY the camera's sessions shortened starting Sep 14 02:29 local
  (31min BEFORE that night's 03:00 reboot). No camera-side error log
  exists for session teardown; prudynt logs setup only. A packet
  capture at sophon (who sends FIN/RST first) or prudynt debug logs
  (camera ssh refuses root) are the remaining instruments.
- The 02:29 onset predates the nightly reboot by 31min and is not
  explained by any logged camera event (last prior line: 02:23 ntpd
  crond). The onset trigger is still unidentified.
- The reboot-pause asymmetry (Sep 14 paused h04-h07, Sep 15/16 no
  pause) suggests a state that needs hours to rebuild after a fresh
  boot on day 1 but is immediately present on later days -- or that
  the Sep 14 pause had a different cause (e.g. the 04:30-13:00
  .102/.104 outage changed frigate's producer behavior fleet-wide).
