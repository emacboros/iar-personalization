# ext4 power-dead standing alarm + ext3 3.4h silent stall (c294, 2026-09-14 ~01:30-01:56 UTC)

## Finding 1: ext4 (.104) standing alarm -- the crash-loop anatomy

.104 (exterior_4) has been power-dead since 2026-09-12 ~10:00Z (last
segment 09-12 11:10Z; the 09-11 five-camera L2 event, relay 0038
answered, others recovered 13:36Z 09-12, .104 did not; power cycle =
Nacho's hands). What I had NOT seen until this cycle: the death is not
quiet on the frigate side.

- frigate's watchdog crash-loops on exterior_4 every 10s: 360
  crashes/hour, ~5,694 on 09-12, ~8,227 on 09-13 (~14k in 2 days).
- Journal volume: 111,704 frigate lines on 09-13 vs 40,714 on 09-11
  (2.7x). The flood is why my journalctl --verify hung 600s this cycle
  (ausearch-class hazard; do not run --verify on sophon while the
  flood lasts).
- fleet-check ear check: exterior_4 NO-SEGMENT -> standing FAIL=1
  since 09-12 -> fear organ standing sev=2 (worry:fleet-check FAIL)
  since 09-13 03:01Z. Alarm fatigue on an already-owned signal.

## Fix: fleet-check v2.22 (KNOWN_FAULT_EXT4_SEG)

Same allowlist contract as ext1 SEG-TAIL (v2.18) and KNOWN_DEAF
(v2.9): known-fault + NO-SEGMENT = watch state (reported, not
failed); segments reappearing = RECOVERY event, FAIL loudly so the
flag is withdrawn after verification. i.ar personalization commit
a8b1851a, pushed to sophon bare. Live-verified: feeder run shows
"exterior_4 NO-SEGMENT (known-fault power-dead, watch state; power
cycle pending)", verdict FAIL=0 exit=0; fear organ re-run: sev=0
delta=down. The standing worry is cleared. Power cycle remains
Nacho's; the flag comes out when .104 records again.

## Finding 2: ext3 3.4h silent stall (17:30-21:43Z 09-13), healed by a fleet wave

The 18:04Z fleet feed carried exterior_3 STALE(11748s) -- a real gap,
not an artifact. Timeline (camera clocks = UTC, verified):

- 17:16:36 frigate session (socket 30) + 17:16:44 second session
  (socket 36, 3 tracks = viewer/mic-probe shape).
- 17:30:06 frigate: "No frames received from exterior_3 in 20
  seconds" -> detect died. Segments stop.
- 17:47:19 frigate re-dial (socket 30) -- session accepted, NO frames
  flowed, segments stayed dead.
- 18:40-18:43 record path wrote packet-less segments; maintainer
  discarded them ("Invalid or missing video stream"); encoder -22.
  After 18:43:46 the frigate journal goes SILENT on ext3 (no errors,
  no retries) -- a silent stall, the c263 "every failure worth fixing
  produces silence" shape.
- 19:41:47 another frigate re-dial (socket 30) -- still no frames.
- 21:43:43 FLEET-WAVE remake: all 7 alive cameras logged Backchannel
  sessions the same second (cameras.log witness, 9 lines). ext3's
  stalled stream was remade and segments resumed at 21:43.50. NO
  frigate journal line marks the recovery (flood + no log for it).
  NO viewer traffic (no GET lines 21:40-21:44) and no mic-probe:
  a remake wave WITHOUT page load -- new wave sample, trigger
  unknown (go2rtc-internal re-dial class, the c280 solo-death
  hypothesis shape, but fleet-wide).

## Class updates

- SOLO-DEATH: longest sample yet (3.4h), and two producer re-dials
  (17:47, 19:41) did NOT heal it -- re-dial alone is not sufficient;
  the wave remake was. Refines the c290 refinement: re-dials are
  common AND sometimes ineffective; the heal needs a full session
  remake (audio-death law v3.1 unchanged: ANY session remake).
- WAVE census: first observed wave WITHOUT page-load trigger
  (21:43:43Z 09-13). The c280 falsifier (relay 0060) said a remake
  without page load = mic-probe with dialer open; here there was no
  mic-probe either. Watch for the next recurrence and its trigger.
- The ext4 flood masks frigate journal signals (rate-limited or
  drowned): the ext3 recovery left no trace. The flood is itself an
  observability hazard. If .104 stays dead much longer, consider
  disabling the ext4 camera in frigate config (Nacho's call --
  config change, not mine).

## Instruments used

cameras.log syslog sink (fleet-wide same-second witness -- it caught
the wave cleanly where the frigate journal was flood-blind),
camlog puller snapshots, frigate journal (with the flood caveat),
recording-segment mtimes.