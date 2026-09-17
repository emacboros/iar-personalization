# ext5 h19 window + fleet re-verification against the unified mechanism (c20, 2026-09-17)

## What this cycle did

The roadmap carried a parked thread: "EXT5 H19 WINDOW (c378): 102 dead
17:00-18:00, no event found." This cycle pulled the ext5 evidence and
closed it, and in doing so re-verified the c19 unified audio-freeze
mechanism against every ext5 freeze in the 09-16/09-17 window.

## The ext5 freeze inventory (09-16 17:00Z -> 09-17 12:00Z)

All times UTC unless marked local. Seg names are LOCAL (-03); seg dirs
are UTC. WRN timestamps from go2rtc /api/log (via podman exec, the
machinectl file-redirect path writes to a different /tmp).

| freeze (UTC) | length | heal event | evidence |
|---|---|---|---|
| 19:12:53-19:14:27 | ~2 min | read-timeout reconnect 19:14:57.937 | segs 12.35-14.27 local dead (8 real segs); seg 14.43 (mtime 19:15:08) alive |
| 21:42:05-22:30:37 | ~49 min | read-timeout reconnect 22:30:48.473 | segs 42.05 (h21) through 30.20 (h22) dead; 30.37+ alive; WRN between the two writes |
| 04:36-04:54 blips (09-17) | seconds | reconnects 04:36:54-04:54:23 | 1-dead segs at minutes 37/39/47/54 |
| 05:00-05:01 (09-17) | ~1 min | reconnects 05:00:05 + 05:00:30 | 5 zero-second STUBS (00.31-00.35) + recorder catch-up burst (mtimes 02:00:44 local) |
| 07:25-07:32 (09-17) | 6m9s | reconnect 07:32:16.596 | c387 already resolved |

The 05:47:21 fps-limit restart (heal-B) landed after the 05:07:35
reconnect had already restored audio; it was a video-side heal, not an
audio heal.

## The h19 "no event found" resolution

c378's 102-dead claim was the WATCHDOG-VISIBLE full stall (restart
22:36:36Z), already reclassified in c379. The segcensus h19 row
(242 total / 9 dead) decomposes as: 8 real dead segments from the
2-minute 19:12:53-19:14:27 freeze + 1 zero-second stub (32.46, the
ext3-style recorder stub class). The "no event found" was a clock-mapping
error in c378's first pass: seg names are local, and the heal WRN
(19:14:57.937) sits inside the 14.27->14.43 seg boundary when mapped
correctly.

## Instrument notes

- go2rtc /api/log via `machinectl shell nacho@ -- podman exec frigate
  curl -s "http://localhost:1984/api/log?src=<cam>"` is the reliable
  path (root's podman exec is blocked; file writes inside machinectl
  land in nacho's home, not the container).
- The log endpoint returns the CURRENT log buffer only (go2rtc
  restarts lose history; the 18:48:13 restart line bounds the window).
- frigate journal (journalctl -u frigate) carries the same WRN lines
  with sophon-local timestamps; the go2rtc endpoint carries epoch ms.
  For window work the epoch endpoint is the safer clock.
- Zero-second stubs (dur=0, small size) are a DIFFERENT class from
  the silent audio-freeze: they are recorder-side artifacts of
  reconnect bursts, not camera-side audio drops. segcensus counts
  both; the per-minute histogram + duration read separates them.
- Broken duration metadata exists (00.36.mp4: 17 frames, 117KB,
  container duration 6128s). Duration alone is not a health signal;
  frame count + size are.

## Verdict

Every ext5 freeze in the window heals at a go2rtc read-timeout
reconnect (heal-A) or an ffmpeg restart (heal-B). Zero
unexplained-heal falsifications. The c19 unified mechanism now has:
int1 (6 blocks, c19), ext1 (5h22m, c19), ext5 (5 blocks, this cycle)
-- three cameras, all consistent, zero counterexamples.

## Falsifiers standing

- Tonight's ext1 01:02Z reboot = recurrence watch (ext1 healed 10:17Z
  via reconnect; if it refreezes before the reboot and the reboot
  heals, that is heal-path confirmation on a third instance).
- Nocturne 16:01Z pass = preheal drop-in's first real test.
- If any freeze heals WITHOUT a reconnect or restart, the mechanism
  is wrong. None so far.