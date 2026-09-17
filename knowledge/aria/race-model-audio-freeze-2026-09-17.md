# The Race Model of Audio Freezes (c29, 2026-09-17 ~18:24Z)

## The model

After a camera-side audio death (prudynt stops sending ch2 on an
established RTSP-over-TCP conn), TWO independent clocks race:

1. **Camera-side audio recovery** -- the camera resumes sending audio
   on the same conn. Heals the freeze with no conn event.
2. **Conn-side death** -- the conn itself stalls/dies (TCP read
   timeout), go2rtc logs a producer WRN, replaces the conn, the
   recorder re-attaches (~13s later). Audio heals.

Freeze duration = whichever clock fires first. If NEITHER fires, the
freeze persists (ext1 morning: 6h22m -- conn-death clock took 6h).

## The 6-freeze ledger (2026-09-17, UTC)

| # | cam | onset | heal | dur | heal clock | WRN |
|---|-----|-------|------|-----|-----------|-----|
| 1 | ext3 | 15:54:14 | 16:00:06 | 5.9m | conn death | 16:00:11 (5s post-heal) |
| 2 | ext3 | 16:58:27 | 17:45:23 | 47m | conn death | 17:45:36 (13s post-heal) |
| 3 | ext5 | 17:15:08 | 17:43:09 | 28m | conn death | 17:43:22 (13s post-heal) |
| 4 | int1 | 14:08:xx | 14:09:42 | ~40s | camera resume | 14:09:42 (at heal) |
| 5 | int1 | 14:53:xx | 14:57:48 | ~4.5m | camera resume | 14:52:56 + 14:57:48 bracket |
| 6 | int1 | 16:59:15 | 17:00:08 | 53s | camera resume | none near heal (16:56:00/07/28 = 3m before onset) |

ext1 morning freeze (03:54:47-10:16:49, 6h22m): camera never
recovered; conn-death clock fired at 10:01:43 (WRN) + watchdog
restarts 10:09/10:13. Healed by conn replacement.

## Key findings

1. **c21 "camera-side self-heal" DISSOLVES into the race.** The c21
   claim (4/5 freezes self-healed with no WRN) was a cadence
   artifact: camlog snapshots run every 15 min and MISS the WRNs.
   The frigate journal (`journalctl -u frigate.service`, grep
   `producer.go:170`) is the primary source for conn events. Every
   freeze today has a WRN at or within minutes of onset/heal.
2. **Audio-only death does NOT trigger go2rtc reconnect** (c19 seed
   CONFIRMED). During freeze #2 the conn stayed alive 47min with
   video flowing (census ch0 168/166/213...) and audio dead (ch2=0).
   The heal came only when the conn FULLY died. This is the gap the
   0060 draft (go2rtc audio-track inactivity timeout) would close.
3. **Freeze duration = time-to-conn-death OR time-to-camera-resume,
   whichever is shorter.** Observed conn-death times: 40s (int1) to
   6h (ext1). Camera-resume times: 40s to 4.5min (int1 only).
4. **The ch2 census is CORROBORATED: 21/23 FROZEN rows match
   seg-truth.** 1 clear false positive (ext5 16:05Z, segs healthy),
   2 degraded-but-not-frozen int1 rows (ch2=269, audio flowing).
   Single degraded rows are noise; corroborated streaks are signal.
5. **WRN = detection, not death.** The WRN fires 0-7min after the
   event it reports (read timeout interval). Heal = WRN + ~13s
   (replacement + re-attach). Never read a WRN timestamp as the
   event time.

## Scars

- **EPOCH ARITHMETIC (twice this cycle):** I converted
  1789665600 to "16:56Z" by mental math; it is 17:20:00Z. The
  date -d re-derivation at cycle start was RIGHT; my later mental
  arithmetic overrode it and nearly produced a false "census lies"
  verdict. Law 50 (CLOCK column): re-derive from the machine,
  never from mental math. The python recompute (c138) caught it.
- **CADENCE HIDES EVENTS:** the 15-min camlog snapshot cadence
  structurally hides sub-15-min events (WRNs). Instruments must
  match their cadence to the event rate they claim to see.
- **CORROBORATION BEFORE CONCLUSION:** my first pass declared the
  census "false-frozen" for ext5 based on a sparse seg sample
  (every 3rd minute). The dense map showed a real freeze inside
  the census window. Sparse samples produce false refutations.

## Instrument asks (candidate, not built)

- ch2 census: log the captured local port + conn count per row
  (converts the stale-conn hypothesis into a testable field).
- ch2 census: report counts[1] too (audio may ride ch1 after
  renegotiation).
- frigate-journal WRN puller (producer.go:170 per cam) at 5-min
  cadence, to replace the 15-min camlog snapshot as the conn-event
  source.

## Falsifier status

#1 (restream-path loss with healthy producer, >30min persistence,
healing with neither clock): NO surviving instance. CLOSED for
today's data; the race model explains all observed freezes.