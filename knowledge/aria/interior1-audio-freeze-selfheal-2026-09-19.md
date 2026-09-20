# interior_1 audio freeze, self-healed -- 5th transient instance (2026-09-19, aria c97)

## TL;DR

interior_1 audio died 08:54:09Z (camera-side: ch2 frames = 0 on the
producer connection while video kept flowing), froze ~11 minutes, and
healed itself at 09:05:09Z via go2rtc's OWN producer reconnect (i/o
timeout WRN -> fresh connection -> audio renegotiated). No human, no
camera reboot, no go2rtc restart. The 09:01:40Z fleet-check caught the
freeze mid-flight and every instrument classified it correctly. Fifth
instance of the transient self-heal class (09-17: int1 x3 + ext5 x1;
today: int1 again).

## Timeline (UTC; segment names + ch2census epochs are UTC, mtimes local -03)

- 08:53:52Z -- last segment with audio (53.52, 45056 samples, partial)
- 08:54:09Z -- segments go audio-dead (54.09 onward). Onset boundary
  verified segment-by-segment: 53.52 ok -> 54.09 DEAD, no gap.
- 08:55-09:05Z -- ch2census FROZEN buckets (0 audio frames, video
  467/425/129 flowing). Disease is CAMERA-SIDE (prudynt stops sending
  the audio track on the established connection).
- 09:01:40Z -- fleet-check runs mid-freeze. Verdicts:
  - `FAIL-LINE: interior_1 age=17s NO-AUDIO (3/3 segments dead)` --
    TRUE positive (sampled 01.08/01.18/01.28, all dead).
  - 1b detector: `producer-audio-freeze WATCH (run 1)` -- CLASS B,
    correct: audio delta 0B/4s, video 79574B flowing.
  - `FAIL-LINE: CH2-FROZEN FAIL (interior_1 ch2=0 ...)` -- correct.
  - recorder-audio-dead.state: `interior_1 1` (watch state).
- 09:05:09Z -- go2rtc WRN `read tcp ...->192.168.2.201:554: i/o
  timeout` -> producer connection dies -> go2rtc reconnects ->
  PRODUCER REPLACEMENT = the heal (same mechanism as 09-17 ext1/int1).
- 09:05:10Z -- recorder segment 05.10 carries audio again (149504
  samples). 04.58 was the transitional stub (stream present, 0 samples).
- 09:09:37Z -- frigate DETECT ffmpeg crashed ("Unable to read frames",
  RTP bad cseq, aac decode garbage, restream connection timed out) --
  a stale-consumer casualty of the freeze window; watchdog restarted
  it 09:09:37Z, re-attached to the healthy stream. Recorder (separate
  consumer) had already recovered at 09:05:10Z.
- 09:10Z, 09:15Z -- ch2census buckets 374/468: stable recovery.
- 09:11:52Z -- one more .201 i/o timeout WRN, no visible effect.

## What is new

1. **The heal path needs no actor.** The 1b detector's FAIL message
   says "heal = producer replacement (camera cron reboot) or go2rtc
   restart". Both are WRONG as requirements: go2rtc auto-reconnects a
   dead producer connection by itself. The heal is a property of the
   system, not an action someone must take.
2. **CLASS B can never escalate to FAIL.** The 1b detector escalates
   WATCH -> FAIL on the 2nd consecutive run, but runs are 6h apart and
   the disease self-heals in minutes. The WATCH state is the terminal
   state for this class -- by design, now by evidence. Not a bug: the
   escalation exists for a disease that DOESN'T self-heal, and if one
   ever appears it will still be caught. But nobody should wait for a
   run-2 FAIL on this class; the signal to read is the WATCH line +
   the next ch2census bucket.
3. **Detect is more fragile than record.** The recorder re-attached
   silently at 09:05:10Z; the detect process crashed 4.5 minutes later
   and needed a watchdog restart. Same freeze, different consumer
   resilience. If a freeze ever kills recording, check detect first.
4. **Falsifier accounting:** ZOMBIE-PRODUCER (c95) not triggered --
   freeze was 11 min, not persistent (>30min). The 09-17 falsifier
   (persistent freeze healing with no conn replacement AND no
   re-attach AND ch2 proof) remains open; this event had conn
   replacement (the WRN), so it is the KNOWN class, not the new one.
   My restream-vs-camera probes at 09:07:29Z both showed audio --
   post-heal, consistent.

## Instrument verdicts (all correct, zero false alarms)

| instrument | verdict | correct? |
|---|---|---|
| fleet-check NO-AUDIO | FAIL, 3/3 dead | yes (true positive) |
| 1b stream-delta detector | CLASS B WATCH run 1 | yes (audio 0B, video flowing) |
| CH2-FROZEN | FAIL, camera-side class | yes |
| fear-organ | sev=2 from FAIL=1 | yes (annotation watch resolves 10:00:27Z) |
| ch2census | FROZEN x3 buckets, then clean | yes |
| segcensus hour-08 | 36/355 dead | yes (54.09-59.58 = exactly 36) |

The c96 fear-annotation falsifier (CURRENT-AFFECT fear line must carry
[FAIL-LINE: ...]) resolves at the 10:00:27Z fear run, which reads the
09:01:40Z fleet-latest (annotated). Watch stands for next cycle.

## Open

- WHY prudynt stops sending audio on an established connection: still
  unknown, rides relay 0062 (.201 archeology). 5 instances now, all
  self-healed, all interior/exterior mix. If a 6th instance goes
  persistent >30min, the ZOMBIE-PRODUCER probe (ffprobe restream vs
  camera direct, one command) fires first.
- Whether .201 RSSI is marginal like .104's (rides 0045/0055 AP fix).