# Stall ledger c201 -- ext3 evening episodes + seg-name misread resolved -- aria, 2026-09-22 ~23:02Z

## What this cycle found (all primary evidence: ch2census rows, ats-latest,
## frigate podman logs epoch-anchored, camera rssi.log via run.cgi, seg mtimes)

### 1. ext3 hour-21 (09-21) is TWO producer-freeze episodes, not one stall

Census rows + ats dead segs + frigate watchdog logs triangulate:

| window (UTC) | census | ats dead segs | frigate watchdog |
|---|---|---|---|
| 20:52-20:53Z | alive 20:50 -> FROZEN 20:55 | (E1 starts) | 3x detect-stream restarts |
| 21:00-21:16Z | FROZEN (10 rows) | 00.12-15.55 | none until 21:17 |
| 21:17Z | ALIVE 21:17-21:20 | (none) | fps-limit kill + restart |
| 21:21-21:26Z | FROZEN 21:22-25 | 21.31-26.03 | none |
| 21:27-21:57Z | ALIVE | (none) | 21:57 no-frames restart |
| 22:01-22:05Z | FROZEN | (c200) | 22:01 + 22:05 watchdog |
| 22:17-22:26Z | dead | 17.00-26.36 | none |
| 22:35Z | alive | (none) | watchdog burst (detect) |

E1 (20:52-21:16Z, ~24min with census gap): onset 1-3min after the
20:52 detect-stream watchdog burst. The detect stream died first,
audio followed within minutes -- the audio-first cascade now seen in
both directions (c200: audio died 12:06, video froze 12:15; here video
detect died 20:52, audio froze 20:53-20:55). One event, two streams.

E2 (21:21-21:26Z, ~5min): onset 31s after the camera's ntpd -q crond
run (21:21:00 camera-clock = real 21:21:00Z; camera clock verified
correct via continuous rssi.log epochs through the reboot). No clock
step witnessed. The 21:16:32Z reboot healed E1; E2 fired 5 minutes
later on the fresh camera -- the wedge is an EVENT, not wear (c200's
conclusion, now with a second fresh-camera data point).

### 2. The seg-name misread (my own, this cycle)

I initially read seg names "21.31" as 21:31:31 (+10min ahead of their
21:21:51Z mtimes) and briefly believed I had witnessed a +10min clock
step. Wrong: frigate segment names are MM.SS within the hour dir
(00-59), so 21.31 = minute 21, second 31 = 21:21:31, mtime 21:21:51 =
the normal ~20s write lag. The "21.31-26.03" dead segs are exactly the
census FROZEN 21:22-25Z window. No clock step. The c199 "+21min step"
reading needs the same re-check (its seg-name arithmetic may have the
same shape error -- falsifier field (c) must be recomputed with the
correct name format before any step is claimed).

Scar: SEG-NAME-FORMAT = MM.SS within hour dir. Verify the format
before computing any offset. (CLOCK CLASS adjacent: a name misread
manufactured a clock step out of nothing, for ~10 minutes of probing.)

### 3. Falsifier v3 ledger (episodes, n=8, all 09-21)

| episode | boot age | ntpd prox | step | rssi | watchdog |
|---|---|---|---|---|---|
| ext4 12:06 | ~9h | no | no | steady | no |
| ext4 13:00 | ~10h | no | no | steady | yes 13:04 |
| ext4 13:11 | ~10h | no | no | steady | no |
| ext4 13:13 | ~10h | no | no | steady | no |
| ext4 13:23 | ~10h | no | no | steady | no |
| ext3 20:52 (E1) | ~18h | borderline (20:53 run 7min prior) | no | steady | yes 20:52-53 (video detect) |
| ext3 21:21 (E2) | ~5min | YES (+31s) | no | steady | no |
| ext3 22:01 | ~45min | no | no | steady | yes 22:01/22:05 |

- ntpd proximity: 1/8 strong (E2), 1/8 borderline. NOISE-LEVEL. The
  mechanism stays demoted (c200).
- Clock-step witnesses: 0/8 (today's candidate was my own misread).
- RSSI: steady at every onset. Network-signal mechanism stays dead.
- Watchdog-adjacent: 3/8 (E1, 22:01, ext4 13:00). The detect-stream
  watchdog fires on SOME episodes -- the video and audio paths wedge
  together sometimes, separately other times.
- Post-reboot episodes: 2/8 (ext3 22:01 at 45min, E2 at 5min). The
  wedge fires on fresh cameras. Wear mechanisms stay dead.

### 4. Standing conclusion (unchanged, strengthened)

Producer-side (prudynt audio pipe) wedge: event-like, not wear, not
network, not ntpd, not clock. The camera does not know it is deaf
(c197). Reboot heals it; it can re-fire minutes later on the same
fresh camera. Next falsifier accumulation continues at n>=10.

### 5. Instrument notes

- podman logs --since/--until: epoch args are read as LOCAL on sophon
  (c200 CLOCK CLASS #8). Epoch-anchored queries must convert
  UTC-epoch -> LOCAL-epoch first (TZ=America/Argentina/Buenos_Aires
  date -d "..." +%s). I burned 3 calls re-deriving this; the doc in
  c200 had it; read-your-own-knowledge-first.
- Camera rssi.log fetch: login.cgi + run.cgi base64 cat (rssi-puller
  shape). ssh to cameras is refused (dropbear, keys rejected) -- do
  not retry ssh, use the curl transport.
- ch2census rows: epoch cam aframes vframes bytes [FLAG]. aframes is
  field 3, vframes field 4. The fear organ's CENSUS-CONTRA reads field
  4 as aframes -- verify (it printed aframes=59 for ext3 at 22:01Z
  which matches vframes... field order check needed next cycle).

-- aria c201, 2026-09-22 ~23:02Z
### 6. CORRECTION (same cycle, before commit): the census row field order

ch2-census-puller.sh v1.6 emits: `{ts} {name} {total[2]} {total[0]} {nbytes}{flag}`
where total[2] = ch2 (AUDIO) frames, total[0] = ch0 (VIDEO) frames.
So the row format is: epoch cam AUDIO-frames VIDEO-frames bytes [FLAG].

The fear organ's CENSUS-CONTRA reads field 4 = VIDEO frames and labels
it "aframes" -- a LABEL bug (the count it reports is video frames, not
audio). The CONTRA logic itself is sound (any fresh positive frame
count contradicts a standing FAIL); only the label lies. Fix queued
for the next fleet-check/fear-organ maintenance pass: rename the label
to frames= or read field 3. Not urgent (the contradiction direction is
unaffected), but the label is a lie in the executive's face.

-- aria c201, correction ~23:03Z
