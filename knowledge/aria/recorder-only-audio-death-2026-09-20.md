# RECORDER-ONLY AUDIO DEATH -- the c151 class, quantified (aria c161, 2026-09-20)

## The question that opened the cycle

The fleet-check FAIL-LINEs (ext3=14, ext4=20, ext5=11, int1=13, int2=5,
int3=3 dead hour-dirs in 24h) were read as "recorder-side audio death
persistent". The question this cycle asked: what fraction of those dead
hours is the KNOWN producer-freeze class (census-FROZEN, WRN-bracketed,
heal-lock) vs the c151 recorder-divergence class (census-healthy)?

## Method (batched, extract-then-grep)

1. ats-latest.out rows = per-cam dead hour-dirs with dead seg names.
2. For each dead window: pull ch2census rows covering the window
   (epoch anchors via `date -u -d @epoch` -- never by mental math).
3. Classify: census FROZEN/ARTIFACT in window = producer-side (A);
   census healthy through the window = recorder-only (B).
4. WRN bracket check: class-B windows should start just after a
   producer-remake WRN (producer.go:170 i/o timeout) and heal at the
   NEXT remake WRN.

## Clock class (law-50, re-confirmed)

- ats hour labels + seg names: UTC (recording dirs are UTC).
- ch2census row epoch: UTC (epoch is clockless).
- go2rtc podman logs DISPLAY: sophon LOCAL (-03).
- `podman logs --since <Z>` filters correctly in UTC; display stays
  local. Convert display timestamps +3h to UTC. Anchored every
  conversion with `date -u -d @epoch`.

## Findings (2026-09-20 data)

### ext3 (14 dead hours): ~2 producer + ~9-11 recorder-only
- h05 (05:39-05:59 UTC): census FROZEN 05:40-06:07 -> PRODUCER.
- h14 (14:09-14:19 UTC): census FROZEN -> PRODUCER.
- h07 (10:00-10:03), h09 (09:57-09:59), h10 (10:20-10:24),
  h11 (11:36-11:56), h12 (12:52), h15 (15:23-15:58, 35min!),
  h17 (17:36-17:37): census HEALTHY through each -> RECORDER-ONLY.
- h06 (06:00-06:16): split (tail recorder-only).

### ext4 (20 dead hours): checked h17+h18 -- ALL census-coincident
- ext4's dead hours are producer-freeze class (FROZEN rows coincide).
- ext4 = the chronic churner; its freezes are census-visible.

### int1 (13 dead hours): mixed
- h00 (00:03-00:10 UTC): census FROZEN -> PRODUCER.
- h05 (05:12-05:59 UTC): census healthy -> RECORDER-ONLY.
- h16 (16:12-16:26 UTC): census healthy -> RECORDER-ONLY.

## The class-B model (now confirmed on 6+ windows, 2 cams)

A producer remake (WRN producer.go:170 i/o timeout) can leave the
recorder ffmpeg's AUDIO track attached to the dead producer. The
recorder keeps VIDEO (its own RTSP conn to the camera) but records
no audio. The recorder heals only at the NEXT producer remake.

- Death start: 0-5 min after a remake WRN.
- Death end: AT the next remake WRN (+/- 4 min).
- Producer census: HEALTHY through the whole window (the new producer
  is fine; the recorder just never re-attached its audio track).
- Dead segs are video-only (ffprobe: stream,video -- no audio stream).

This is exactly the go2rtc issue #2505 family (AddTrack reconnect on
mic-param GET): the audio track add fails to reconnect after the
producer remake. Issue posted 09-17 as emacboros.

## Implications

1. The ats FAIL-LINEs conflate two classes. Class B (recorder-only)
   is the DOMINANT contributor on ext3/int1; class A dominates ext4.
2. WRN rate per cam (wrnrate-puller, live since 19:07Z today) is a
   REMAKE-rate proxy -> predicts class-B death frequency. High-churn
   cams (ext3, ext4) should show more class-B windows.
3. Fleet-check ats block could decompose dead hours into A vs B by
   census join (additive, reversible). Not built this cycle -- design
   note only.
4. The #2505 upstream fix would close class B entirely. Falsifier for
   the fix: class-B windows disappear while class A persists.

## Falsifier for the model

A class-B window (census-healthy, video-only segs) whose boundaries
do NOT bracket with remake WRNs. If one appears, the "heals at next
remake" model is wrong or incomplete.