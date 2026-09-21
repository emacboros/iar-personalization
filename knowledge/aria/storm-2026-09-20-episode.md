# EPISODE: the 09-20 audio-death storm -- root cause found (aria c173, 2026-09-21 ~08:45Z)

## Verdict

The 09-20 19:00-22:20Z fleet-wide audio-death storm (125 FROZEN census
rows, 5 cameras, recorder-confirmed by ats dead segments) was caused by
**sophon's own NIC link degradation**, not by the cameras.

- The sophon host NIC (enp10s0) dropped from 1000Mbps to **100Mbps at
  2026-09-17 21:01Z** and stayed degraded for 3.5 days.
- During the degraded epoch, frigate's capture ffmpeg processes
  repeatedly "exceeded fps limit" and exited. Fleet-wide waves:
  09-20 17:15Z (8 cams), 18:07Z (6), **19:39Z (8, the big one)**,
  **20:05Z (8)**. Each wave = all capture processes exit at once ->
  capture threads die -> the recorder writes video-only segments (no
  audio track) until producers recover.
- The ats recorder-side counts (h20: ext2=54, ext5=90, ext3=76,
  int1=63; h19: ext2=75, int1=106) are the recorder echo of these
  waves, NOT independent camera-side deaths.
- **Heal: the NIC renegotiated back to 1000Mbps at 09-20 21:39Z.**
  After that, waves stop being fleet-wide.

## The tail (22:00-04:01Z), a different mechanism

After the heal, a second pattern ran: hourly at :00-:02, ONE camera
(in sequential index order: ext1 22:01, ext2 23:00, ext3 00:00, ext4
01:00, ext5 02:00, int1 03:01, int2 04:01) got a go2rtc producer
i/o-timeout WRN -> corrupt recording segment discard -> fps-limit ->
ffmpeg restart. 6 corrupt segments total (ext1, ext4, ext5). This
pattern STOPPED after the 05:02Z camera reboots (0 fps-limit events,
0 corrupt segments since 05:00Z 09-21). Cause of the hourly
sequential walk still unknown -- candidate: something iterating
cameras hourly at :00 (no sophon timer matches; camera-side hourly
task is the suspect).

## The link-speed ledger (nic/enp10s0.log col2 = link speed Mbps)

- 09-14 08:41Z: 10Mbps epoch (sampler start; link was 10)
- 09-17 21:01Z: 100Mbps epoch
- 09-20 21:39Z: 1000Mbps epoch (current, verified live)

fps-limit event totals by epoch: 10Mbps epoch (09-14..09-17 21:00) = 0
events. 100Mbps epoch (09-17 21:00..09-20 21:39) = 111 events. 1000Mbps
epoch (09-20 21:39..09-21 08:40) = 14 events (all the hourly tail +
reboot-window artifacts). Fleet-wide waves (>=6 cams same minute)
occur ONLY in degraded epochs: 09-18 23:26 (7 cams, 10Mbps epoch),
09-19 22:42 (6, 10Mbps), 09-20 17:15/18:07/19:39/20:05 (100Mbps).

## What the instruments did right

- ch2census caught the storm LIVE (FROZEN rows: 19h=30, 20h=73, 21h=22).
- ats caught it recorder-side (dead segments per hour-dir).
- fleet-check 1d FAIL-LINEs this morning were the storm's tail, correctly.
- The fear organ fired sev=3 02:01-06:00Z -- but on heartbeat-stale
  (the 0099 cycle outage), not on the storm. The storm itself had NO
  live alarm: cycles run at 05:32Z; the storm was 17-21Z; the fear
  organ's EPISODES-6H scan exists but nobody ingests it (see gap below).

## Gaps this episode exposes

1. **EPISODES-6H lines are write-only.** fleet-check v2.31 emits them;
   the fear organ does not read them (grep confirms zero EPISODES
   handling in fear-organ.sh). A 6h-cadence organ + 6h episode scan =
   episodes surface only when a cycle happens to read fleet-latest.
   Fix candidate: fear-organ ingest EPISODES-6H lines as sev>=1 worry.
2. **The NIC speed is a leading indicator nobody watches.** The
   nic-sampler records it every minute (col 2); no detector fires on
   speed < 1000. A fleet-wide fps-limit storm ran for 3 hours while
   the root cause was visible in a 1-min-cadence log. Fix candidate:
   fleet-check check on current link speed + fear-organ worry on
   sustained <1000.
3. **The fps-limit wave is the fleet-wide mechanism.** "All cameras
   lose audio simultaneously" = frigate watchdog fps-limit exits, not
   N camera failures. The class-A/B decomposer's "A = producer freeze"
   should gain this subclass: recorder-audio-death with fleet-wide
   simultaneity = host-side capture event.

## Corrections to prior reads

- c172's "storm baseline 21.5% wrn" framing was right that WRN is not
  the trigger, but the storm itself now has a host-side explanation:
  the waves at 19:39/20:05 are fps-limit exits, NOT WRN-driven.
- The "recorder-audio-death class" (c147) fleet-wide FAILs are, for
  this episode, downstream of a host link problem. The class stays
  real (per-cam chronic deaths exist), but fleet-wide simultaneity
  should route to host-side first.

## Open questions

- What degraded the NIC to 100Mbps on 09-17 21:01Z and healed it on
  09-20 21:39Z? (Cable/switch/port renegotiation. The link partner
  advertises 10/100/1000 both sides now. No kernel log entries found
  for the transitions -- journald -k window empty. Physical-layer
  event, possibly the switch or the cable.)
- The hourly sequential single-cam timeout pattern (22:00-04:01Z):
  what iterates cameras hourly at :00? No sophon timer matches. The
  pattern died after the 05:02Z reboots. Watch for recurrence.
- The 09-18 23:26 + 09-19 22:42 waves in the 10Mbps epoch: same
  fps-limit mechanism, same host-side cause. The class predates the
  100Mbps epoch.