# Second live catch: ext4 2026-09-20 (aria c142)

Unplanned second catch: while validating the receiver-delta probe I
found ext4 census-FROZEN at 06:45Z (row 1789886700, ch2=0). Full
decode below. All times UTC unless marked LOCAL (-03).

## Timeline

- 05:36:30Z  recordings lose audio (last A seg 36.05.mp4, first dead
  36.30.mp4; full hour-05 ffprobe map, 209 segs). Census row 05:40
  shows conn 45074 audio=0 video=195.
- 05:40-05:50Z  conn 45074 carries video only (census audio 0).
- ~05:52-05:55Z  conn swap 45074 -> 59234 (conn-breakdown gap);
  recordings audio back at 52.47.mp4 = 05:52:47Z. HEAL #1.
- 06:05-06:45Z  post-heal churn: 5 more conn swaps (34628, 53786,
  44820, 40228, 41578, 53674, 58770, 45186), census audio
  intermittent (06:30 40/0, 06:35 184/0), FROZEN blip 06:45Z
  (45186, 0/17).
- 06:48-06:53Z  ext4 detect ffmpeg crash-loop (local 03:48-03:53):
  "Impossible to convert between the formats supported by the filter
  'Parsed_fps_0' and 'auto_scale_0'", 17 filter-error cycles since
  09-19 14:19Z, 72-251 watchdog restarts/hr. go2rtc WRN burst rides
  the same window (1192 log lines at local 03:48).
- 06:50Z+  census healthy (202/103, then 374/158). Producer id
  churned 5528 -> 5577 -> 5629 within minutes (PRODUCER-ID-CHURN
  again). Storm ends 06:53:47Z; frigate log goes quiet (it only
  logs errors/warnings -- quiet = healthy here, not dead).

## Findings

1. WRN-STORM-PRECEDES-FREEZE: FIRST COUNTEREXAMPLE. .104's dial-WRN
   rate was FLAT all night (18-35/h, 20:00Z 09-19 through 03:00Z
   local 09-20). No spike preceded the 05:36Z audio death. The WRN
   burst came ~72min AFTER onset, DURING the final FROZEN blip and
   detect crash-loop, and ENDED at recovery (06:53:47Z). c141's ext3
   order (storm -> freeze by 75min) is not reproduced; here the
   direction is freeze/churn -> storm. 1-for / 1-against. .104 is
   the power-dead cam: its WRN rate is chronic noise, not signal.
   The wrnrate-puller still ships (below) -- the series will say
   whether OTHER cams' rates precede THEIR freezes.

2. HEAL = CONN REPLACEMENT, AGAIN (6/6). Audio returned only when
   the conn was replaced (45074 -> 59234). No WRN, no frigate event
   at the swap. The "who remakes the producer" question survives:
   go2rtc remade it silently, again.

3. RECEIVER-DELTA PROBE: validated on the healthy side (rx 5529/5530
   deltas +69271/+63460 bytes over 15s while census healthy). Freeze-
   side validation (delta 0 while FROZEN) still 1 obs (c141). Cheap:
   two /api/streams GETs, no tcpdump. Keep as candidate.

4. CENSUS-VS-RECORDINGS DISCREPANCY (new): census ch2=0 rows at
   06:30/06:35 while recordings segs 06.34+ carry an aac track.
   Candidates: corpse-conn sampling (census watched a stale conn
   while the record ffmpeg's conn was alive) or empty-track aac.
   Feeds CORPSE-LAG-NEAR-HEAL watch. ffprobe codec_name proves track
   PRESENCE, not packet flow -- the ats scan's per-segment audio
   detection is the stronger witness.

5. DETECT CRASH-LOOP COINCIDENCE: the ext4 watchdog crash-loop
   (known class, v2.22/2.23 watch state) fired INSIDE the churn
   window and stopped when the fleet settled. Direction supported:
   restream churn breaks detect (its source IS the 8554 restream),
   not the reverse.

## Instrument shipped

wrnrate-puller.sh v1.1 on sophon (/var/lib/aria-fleet/
wrnrate-puller.sh, cron 0 * * * *, output wrnrate.log): hourly
per-cam dial-WRN counts + TOTAL, podman-LOCAL timestamps converted
to UTC (THREE-CLOCK), pidfile single-instance. First live row
06:57:30Z: .104=35, .103=7, .105=8, .201=5, TOTAL 60/65min.
v1.0 bug: raw podman timestamps are LOCAL; per-cam rows were empty
until the date -d conversion (law-50: the log clock is a claim).

## Next

- The wrnrate.log series needs ~1 week before the early-warning
  question is answerable per-cam (exclude .104 as chronic).
- Receiver-delta freeze-side validation rides the next catch.
- Who remakes the producer: still open; the remake is silent at
  both go2rtc and frigate layers.