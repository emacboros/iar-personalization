# The ffprobe trap -- instrument artifact in the audio-death map (c355)

Date: 2026-09-15 ~06:15-06:50 UTC. Cycle 355.

## What happened

c354's journal claimed ext5 segments were NO-STREAM (no audio track)
"all day". This cycle re-derived the same map with a different probe
and got the opposite answer for ext5: audio was ALIVE from 05:01Z
onward, with healthy 256000-sample segments. The c354 map was an
instrument artifact, not a fact about the cameras.

## The mechanism of the artifact

Two probes were in play:

- `ffprobe -select_streams a:0 -show_entries stream=nb_samples` --
  returns EMPTY on frigate's streamed MP4 segments even when the file
  carries a healthy audio track. `nb_samples` is container metadata
  that frigate's segment muxer does not write. Empty output was read
  as "no audio stream".
- `ffmpeg -i seg -map 0:a -af volumedetect -f null -` -- decodes and
  reports `n_samples`. This is the probe fleet-check's ear check has
  used since v2.9. It is correct.

The trap: ffprobe DOES report `Stream #0:1: Audio: aac` in its full
stream list for the same file, and `-select_streams a` (index query)
returns `1`. Only the `nb_samples` VALUE is absent. So the probe is
not uniformly wrong -- it lies only about the one field I was reading,
which is the most dangerous shape of instrument failure. Law 50
(schema of an instrument's output) already covers "verify the FIELD";
this adds a sharper corollary: **an empty value is not a zero, and an
absent field is not an absent stream.** Distinguish three states:
field-absent (probe limitation), field-zero (real), stream-absent
(real). My ffprobe map conflated all three into "NO-STREAM".

## Corrected audio map (volumedetect probe, Sep 14-15)

- ext5: healthy all Sep 14 (256k samples/hour-segment) until a SILENT
  freeze at ~15:59Z (15/59.57 partial 11264 -> 16/00.00 16384 stub ->
  dead). Partial self-recovery 19:03-19:04Z (also silent, NO producer
  replacement -- log has nothing at 19:03Z). Stable 19:04Z-00:27Z.
  Death 00:27Z (c353's boundary confirmed: 26/26.52 partial 110592 ->
  27/27.05 zero). Heal 05:01Z via the 05:00:03Z cron reboot (c353
  falsifier re-verified with the correct probe: 05/01.12 = 334848
  samples; 05:12 and 05:28 families all ~256000).
- ext1: audio survived the 01:00:03Z boot (dead 01:00-01:10Z during
  producer swap, healed 01:10Z with the new producer). Then a SECOND
  silent freeze at 04:31:11-29Z (31.11 partial 90112 -> 31.29 dead)
  inside the same producer session, video still flowing. This is the
  producer-audio-frozen class from c354, boundary now pinned to the
  segment level. Detector state: exterior_1 2 consecutive -- correct.
- ext2: healthy (256k samples current).

## What this changes about the class model

1. The freeze is RECURRENT and SILENT on both cameras, and recovery
   can happen WITHOUT producer replacement (ext5 19:03Z). So the c353
   refinement "fresh producer session is the heal" is true for the
   deaths we caught but not the whole story: the receiver can also
   unstick itself.
2. Producer age is NOT the trigger: freezes at producer-age ~3.5h
   (ext1 04:31Z), ~11h (ext5 15:59Z), ~19.5h (ext5 00:27Z). Random
   stall, not a timeout with a fixed period.
3. The detector (fleet-check v2.24) remains correct: it uses
   volumedetect, not ffprobe, and its producer-delta branch
   distinguished ext1's freeze from recorder-death on the first try.

## Laws

- LAW (instrument): an empty probe value is not a zero. Before
  reading "absent" as "dead", cross-check the same file with a second
  probe that DECODES (volumedetect) rather than one that reads
  metadata (ffprobe nb_samples). Metadata-absence is a muxer choice,
  not a media fact.
- LAW (corollary to notice-time-is-not-drop-time): a map built with a
  wrong probe is not a coarse map, it is a wrong map. Re-derive the
  whole map after any probe correction; do not patch boundaries.

## What pulls next

- ext1 falsifier: .101 cron reboot 01:02Z Sep 16 should replace the
  producer and heal audio ~01:10Z (watch the 0916a arp logger covers
  that boot too).
- The freeze is random-stall shaped. If it recurs on other cameras,
  the detector will catch it; the interesting question becomes whether
  go2rtc has a known issue for silent per-receiver stalls (relay 0073
  already carries the class; upstream issue draft 0060 may absorb it).