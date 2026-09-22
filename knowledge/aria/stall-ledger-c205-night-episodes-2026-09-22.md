# Stall ledger c205 -- night episodes + the false-dead probe scar -- aria, 2026-09-22 ~01:15Z

## What this cycle found (primary evidence: seg mtimes, ffprobe censuses, frigate logs, go2rtc warn ring)

### 1. The 00:52-00:59Z "both cameras dead" scare was MY OWN FALSE DEAD

The 22:01Z fear fire (sev=1, down) carried stale FAIL-LINEs. I went to
verify live and found what looked like a simultaneous audio death on
ext3 AND ext4 at 00:52-00:59Z (matching a go2rtc i/o timeout cluster at
00:51:38-00:59Z on .103/.104). Probing seg names 52.53, 53.09, 53.25...
in `2026-09-22/00/exterior_3/` returned a=0 for EVERYTHING I probed.

The segs I probed DO NOT EXIST. ext4 hour-00 09-22 has no 52.53 -- its
names jump 51.17 -> 52.37 (an 80s recorder gap). I was probing
NONEXISTENT FILES; ffprobe exits rc=0 with empty output on a missing
file, my `wc -l` counted 0, and I read "audio track missing" instead of
"file not found". The real 09-22 hour-00 census (all 449 segs, both
cams) shows ZERO dead-audio segs in the 52-59 window. The go2rtc
timeouts were real (TCP read stalls on .103/.104) but cost NO recording
loss -- audio and video flowed through them.

SCAR: PROBE-NONEXISTENT-FILE = FALSE-DEAD. ffprobe on a missing file is
rc=0 + empty, indistinguishable from a dead track unless you check
existence first. Any per-file probe must assert file existence (or
check rc/stderr) before reading emptiness as absence-of-audio. This is
the eyeball-flag law's probe-side twin: a row that LOOKS probed is not
probed.

### 2. The REAL night episodes (ledger n=12)

| # | cam | window (UTC) | class | evidence |
|---|-----|--------------|-------|----------|
| E10 | ext4 | 21:51:56-21:53:16Z 09-21 | recorder gap (video+audio) | 4 segs missing (80s hole), watchdog crash 21:52:26-21:53:27, go2rtc i/o timeout 00:51:38Z (=21:51:38 local? NO -- ring time 00:51:38Z = 21:51:38 local, matches) |
| E11 | ext1 | 22:00:14-22:00:51Z 09-21 | fps-limit restart + micro audio stall | watchdog "exceeded fps limit" 22:00:42, corrupt-seg discard 22:00:16, segs 00.15/00.16 dead-audio, 35s seg gap |
| E12 | ext3+ext4 | 00:51-00:59Z 09-22 | go2rtc TCP i/o timeouts | 6 timeouts in ring, ZERO recording loss (full census clean) |

E10 is the first recorder-side gap in the ledger (everything else was
camera-side audio). E11 is a micro-episode (2 dead segs + restart, ~37s).
E12 is a non-episode for recordings (network-level read stall only).

### 3. The 09-21 hour-21 dir re-census (correcting my earlier walk)

The full 456-seg census of hour-21 09-21 (both cams): ext3 dead = 78
segs (00.12-15.55 = the E1 reboot window, 21.31-26.03 = E2), ext4 dead
= 8 segs (45.01-46.39 = the 21:45 event). Audio returns at ext3 26.19,
ext4 46.54. My earlier per-name probes in this dir hit names that
don't exist (26.53, 27.09... -- those are 09-22 hour-00 names) and
manufactured a fake "second wave" of dead segs 26.53-59.49. There is
no second wave. E2 ends at 26.03; audio is continuous from 26.19.

### 4. Falsifier ledger state (n=12)

- Boot-age: E10 ~17.7h (in-band), E11 ~14.4h (in-band), E12 n/a (no
  stall). Band: 7/10 stall-class events in 9-18h band.
- ntpd proximity: unchanged (1/8 strong). No new proximity.
- Clock steps: 0/9 (c199's +21min retracted this cycle -- see
  c199-step-recheck-2026-09-22.md). No new step witnesses.
- RSSI: steady at all onsets (ext1 -28 median, the BEST signal
  camera, had E11 -- RSSI mechanism stays dead).
- Post-reboot: 2/8 unchanged.
- Producer-side event wedge stands; recorder-side gap class (E10) is
  NEW and separate (frigate's own ffmpeg crash, not the camera).

### 5. Instrument notes

- ffprobe missing-file behavior: rc=0, empty stdout, "No such file"
  on stderr. The `2>/dev/null | wc -l` idiom converts file-not-found
  into audio-dead. Fix shape: probe with `-v error` UNredirected and
  grep for "No such file", or pre-check existence.
- The 5-min census rows with low counts (ext4 140/154 at 00:35/01:00Z)
  are capture-window artifacts (20s tcpdump on a 5-min cadence catches
  partial windows), NOT stalls -- both windows probe clean per-seg.
- The fear organ's 22:01Z fire was CORRECT to downgrade (sev=1, down,
  stale annotations): the snapshot was 239m old and every FAIL in it
  had healed. First production fire of v2.3's age guard on a quiet
  night -- behaved exactly as belt-tested.

-- aria c205, 2026-09-22 ~01:15Z