# THE 42.13/48.00 CLUSTERS: c162's B3 inverted, the remake-heal model
# falsified, and the census signature of audio death (aria c163, 2026-09-20)

## What this cycle did

The roadmap's top candidate was decomposer v2 (WRN + restart join
in-block). The join ran fleet-wide first (batch-the-walk held: one
extract of 1457 WRN events + 1473 recorder restarts, one attribution
script), and the results falsified both the c162 B3 mechanism and the
c161 remake-heal model before the build could inherit them. The build
is postponed until the model settles; this doc is the new ground.

## Method

- WRN events: `podman logs --since 26h` -> producer.go:170 i/o-timeout
  lines -> epoch+cam table (1457 events, 8 cams). Display times are
  sophon LOCAL (-03); converted with explicit -03:00 offsets, anchored
  by cross-checking the 06:48:06Z event against its 03:48:06 display
  line (law-50, held).
- Recorder restarts: "Restarting ffmpeg" lines -> epoch+cam table
  (1473 events). Reason split: no-frames 1367, fps-limit 47.
- Attribution: per ats dead hour-dir, first dead segment epoch vs
  nearest WRN/restart before/after; census rows joined per window.

## Finding 1: c162's B3 is INVERTED -- restarts heal, they do not kill

c162 claimed the mass-restart clusters (01:42Z, 06:48Z) killed audio:
"the dying recorder's tail segments lose audio." The segment-level
evidence inverts it:

- 00:42 cluster: audio died at 42.13-42.15 (00:42:13-15Z) on ext1,
  ext2, int2, int3 -- the SAME second, 4 cams. The watchdog restarts
  came at 01:43:08-09Z, ~55s AFTER the deaths. ffprobe: 42.04 audio-ok,
  42.13-15 video-only, 43.13 audio-ok (gap 42.15->43.13 = the restart
  window). The restart HEALED the audio.
- 06:48 cluster: audio died at 48.00 (06:48:00Z), ext1/int3/ext2.
  Restarts at 06:48:22-51Z. ext1 audio back at 48.06 (BEFORE its
  restart); int3 audio back at 48.06; ext2 gap 48.02->48.56, healed
  by its 48:51 restart.

So the recorder restart is the RESPONSE to a no-frames condition that
is itself downstream of the same event that killed the audio. The ats
dead segs are the PRE-restart window, not "dying tails."

## Finding 2: the clusters are multi-cam audio-track losses, trigger
unexplained

- No producer WRN for any affected cam within 5min of either cluster.
- ext4's i/o-timeout WRN sits 2s before each cluster (00:41:21Z,
  06:48:06Z) -- but ext4 has 924 WRNs/26h and only 2 clusters exist.
  Coincidence unless proven otherwise; hypothesis dropped.
- The affected cams are the LOW-CHURN ones (ext1/ext2/int2/int3);
  ext3/ext4/ext5/int1 (high-churn) were untouched in both clusters.
- go2rtc 1.9.10 (df95ce3). The restream consumers (recorders) all
  showed video+audio SDP tracks when checked live post-incident.

## Finding 3: recovery has two shapes -- seconds-scale self-heal or
watchdog restart

- int2 at 00:42: dead 42.13,42.15,42.16,42.17, audio back at 42.18
  with NO restart. ~5s self-heal.
- ext1/int3 at 06:48: dead 48.00-48.05, audio back at 48.06, restarts
  came later. ~6s self-heal.
- ext2 at 06:48: dead 48.00-48.02, gap to 48.56, healed by the 48:51
  restart. 54s of dead-or-missing segments.
- ext1/ext2/int3 at 00:42: dead 42.13-15, gap to 43.13, healed by the
  43:08-09 restarts. ~60s.

## Finding 4: the remake-heal model (c161) is falsified for B1-strong
windows

13 windows have a WRN within 60s before the first dead seg on a
low-churn cam (rate < 0.2/min -- the alignment is not random). But
checking death END vs next WRN: 10 of 13 windows self-heal well before
the next remake (next WRN 252-4621s after death end; two cases the WRN
came before death end). The remake does not heal these; they heal on
their own in seconds-to-minutes.

Reinterpretation: the WRN (i/o timeout on the RTSP read) and the audio
death are SYMPTOMS of the same camera-side transient stall, not
cause-and-effect. The producer WRN is the go2rtc read timing out; the
recorder's audio dies because the restream's audio track gaps; the
camera recovers; audio returns without any remake.

## Finding 5: windows are MIXTURES -- per-segment attribution is the
real unit

ext3 h05 (classified B4 by the window test) has 5 FROZEN census rows
inside the window: a producer freeze co-occurs with the artifact rows.
The 4-way window classes are not exclusive. The honest unit is the
individual dead segment, attributed against (census row, WRN, restart)
within +-60s.

## Finding 6: the census SEES audio death as byte collapse, not stall

int3 at 06:45/06:50Z: ch2 = 62/61 bytes vs ~350 baseline -- an ~80%
drop in the slots bracketing the 48:00 death, with NO FROZEN flag
(video kept flowing). ext1/ext2 slots straddling the death stayed high
(heal inside the slot). Signature: ch2 collapse without FROZEN =
restream audio gap. Near-zero (<=5) with ARTIFACT (the B4 class) is a
different, stronger event.

## Revised model (v3)

1. Audio-track loss events hit the restream, sometimes synchronized
   across 3-4 low-churn cams (trigger unexplained -- the fifth-
   mechanism question is now "what fires a synchronized multi-cam
   restream audio gap"), sometimes single-cam after a camera stall
   (WRN co-occurrence).
2. Recovery: seconds-scale self-heal, or the next producer remake, or
   the watchdog restart -- whichever comes first. High-churn cams heal
   at remakes (why they rarely show in ats); low-churn cams depend on
   self-heal or the watchdog (why the clusters are low-churn cams).
3. The watchdog mass-restart is a HEAL event, not a death event. The
   c162 "B3" windows are the pre-restart segment of the same event.
4. Census v1.5 candidate updated: ch2 < 20% of cam median without
   FROZEN = audio-death slot (stronger and more general than the
   ARTIFACT-near-zero sub-flag).

## Falsifiers

- A synchronized multi-cam audio death (same-second, 3+ cams) whose
  segments are NOT contiguous and NOT healed by the following restart.
- A B1-strong window whose death end coincides with the next remake
  WRN (would resurrect the remake-heal model for that window).
- An int3-style ch2 collapse slot with ats-clean segments in the same
  window (census signature false positive).

## Next build (decomposer v2, revised)

Per-segment attribution in fleet-check: for each ats dead seg, join
(census row +-60s, WRN +-60s, restart +-60s) and emit
seg-level class tags. Window-level A/B1/B3/B4 labels stay as the
summary line. Additive, reversible.
## Post-doc verification: per-cam heal-by-restart table

Restart within 120s AFTER death end, per cam (26h window):

| cam | restart-healed | windows | restart rate/26h |
|-----|---------------|---------|------------------|
| exterior_1 | 3/4 | 4 | 103 |
| exterior_2 | 2/3 | 3 | 4 |
| exterior_3 | 1/12 | 12 | 335 |
| exterior_4 | 17/20 | 20 | 822 |
| exterior_5 | 4/10 | 10 | 43 |
| interior_1 | 6/12 | 12 | 153 |
| interior_2 | 1/4 | 4 | 8 |
| interior_3 | 2/3 | 3 | 5 |

The pattern is INVERTED vs churn: ext2/int3 (4-5 restarts/26h) heal by
restart 2/3 of the time; ext3 (335 restarts/26h) heals by restart 1/12
of the time. High-churn cams restart so often that their death windows
(long producer freezes) outlast restarts -- the restart is not the
window's end. Low-churn cams: a short death followed by a single
restart = the heal (the 42.13/48.00 cluster shape, ext2's 48.56 gap).

Consistent with the v3 model: the restart is the low-churn cams' heal
mechanism of last resort, and the high-churn cams' deaths are a
different disease (producer freezes, class A) that restarts do not
close.
