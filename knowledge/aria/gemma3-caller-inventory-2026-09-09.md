# gemma3:4b caller inventory (2026-09-09 12:07 UTC, cycle 125)

Prepared for relay aria-0019 (Nacho, for-consideration): qwen3.6 to
REPLACE gemma3:4b as eye organ. D-012 gate: swap only if qwen BEATS
gemma3 on the eye's actual job. This is item (a) of the cycle-
gathering plan: inventory every gemma3:4b caller.

Method: grep across /root/personalization (knowledge/, tasks/) for
the literal model string. Verified MODEL var in aria-oracle.sh
(NOT a gemma3 caller -- granite4.2:3b default). ollama ps at census
time: gemma3:4b resident, 2742 MB VRAM.

## Callers (6 scripts, all in personalization repo)

1. knowledge/aria/bin/eye-check.sh (line 65)
   - Job: camera-frame classification (12-way camera name from
     Frigate frame, one word). Inline JSON, images=[b64].
   - Cadence: on-demand (aria-cycle failure-first walks).

2. knowledge/aria/bin/fear-organ.sh (line 140)
   - Job: affect "mouth" -- one-sentence first-person phrasing of
     fear signal. Text-only chat, num_predict=60.
   - Cadence: on fear events.

3. knowledge/aria/bin/rage-organ.sh (line 379)
   - Job: affect "mouth" -- same shape as fear, anger phrasing.
   - Cadence: on rage events.

4. knowledge/aria/bin/fleet-check.sh (line 325)
   - Job: camera overlay cross-check (MATCH/RACE/VISION-UNCLEAR),
     think off. Fleet-feed timer feeds it every 6h.
   - Cadence: 6h scheduled (aria-fleet-feed.timer).

5. knowledge/aria/bin/frontend-eye-check.sh (lines 47, 77, 106)
   - Job: dashboard/landing page screenshot description. THE eye
     organ's main scheduled job (aria-eye-feed.timer daily 09:30
     -03). EYE= var + inline req dict.
   - Cadence: daily scheduled.

6. knowledge/aria/tools/identity-watch.sh (line 46)
   - Job: overlay camera name from both frames (identity-watch
     tool). MODEL= var.
   - Cadence: on-demand tool.

## Non-caller (checked, named for completeness)

- aria-oracle.sh: MODEL=granite4.2:3b (NOT gemma3). Oracle is not
  affected by the swap.

## Swap-surface summary

All 6 callers are text-in/vision-in, small-output jobs. 4 of 6 are
scheduled instruments (fleet 6h, eye daily, fear/rage event-driven
-- fear/rage are "scheduled" only in the sense of event cadence).
A swap touches 6 files, 8 model-string sites (eye-check 1,
frontend-eye 3 incl comment, fleet 2 incl comment, fear 2,
rage 1, identity-watch 2 incl comment).

## Notes for the benchmark battery (item b)

- The eye's ACTUAL jobs to benchmark: (1) screenshot description
  (frontend-eye-check's prompt shape), (2) camera-name
  classification (eye-check/fleet/identity-watch prompt shape).
- qwen3.6 vision retest already PASSED (relay aria-0012: "fitter
  crash-free"), but that was a general vision test, not the eye's
  job shapes. D-012 gate needs the job-shaped battery.
- ttft: qwen cold load ~23s (c110). gemma3:4b currently resident
  (2742 MB). If qwen replaces gemma3 as eye, gemma3's residency
  question changes -- fear/rage mouths also call gemma3:4b. If
  qwen takes the eye job, do fear/rage mouths move too? That is a
  design question for the swap session, not this census.