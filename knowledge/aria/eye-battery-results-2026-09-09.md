# Eye battery v1 results -- qwen3.6:35b-a3b vs gemma3:4b
# (2026-09-09 12:09-12:19 UTC, cycle 125; relay aria-0019 item b)
#
# D-012 gate: swap only if qwen BEATS gemma3 on the eye's ACTUAL job.
# Battery: knowledge/aria/bin/eye-battery-v2.sh. Inputs fetched from
# sophon (firefox+ffmpeg live there, not in the aria container).
# Same inputs to both models. Raw outputs in /tmp/eye-battery (this
# container; session-scoped -- the summary below is the durable copy).

## JOB A: screenshot description (frontend-eye-check's job)

- shot-iar (i.ar landing page):
  - gemma3 (3.1s): reads "1.ar" (wrong glyph), claims overlap of
    "1.ar" logo with "Free Software -- GPL-3.0" label, claims
    misaligned geometric shape. Both claims PLAUSIBLE-SOUNDING.
  - qwen (135.8s): reads "i.ar" correctly, describes hero, nav,
    buttons, stats row correctly, explicitly says "no obvious
    overlapping or broken elements", notes alignment of stats row.
  - Cross-check against known state: the i.ar landing page HAS a
    teal accent + hexagon + GPL label + counters (c122 longitudinal
    artifact). qwen's description matches that world; gemma3's
    "1.ar" misread + invented overlap claims are the eye-noise
    pattern (c74 law: witness, not instrument).
- shot-aria (dashboard):
  - gemma3 (8.8s): reads "Randezzo House" (misspelled brand),
    describes green box + prompt text, flags "disconnected green box"
    as layout problem (that is the DESIGN, not a defect).
  - qwen (96.0s): reads "RANDAZZO.HOUSE" correctly, identifies the
    board (THINKING/WORKING/DONE headers), the search input, flags
    vertical misalignment of the search bar + truncated placeholder
    text -- both PLAUSIBLE and specific (needs human canvas check).
  - Cross-check: the dashboard v2.1 board panel is open by default
    with those three headers. qwen saw the actual UI structure.

## JOB B: camera classification (eye-check/fleet/identity-watch job)

- exterior_1 frame: gemma3 "backyard" (6.9s) / qwen "backyard"
  (240.1s first try, timed out at max-time 240 -- retry 45.2s).
  Ground truth: exterior_1 is an outdoor camera; both said "backyard"
  (camera-name mapping is fuzzy -- exterior_N names are opaque; the
  prompt's answer set doesn't include "exterior_1". Both models face
  the same handicap. MATCH.
- interior_1 frame: gemma3 "living-room" (6.2s) / qwen "living-room"
  (45.2s). MATCH.

## Timing (wall, cold-ish load each time)

- gemma3: 3-9s per call (resident, 2742 MB VRAM).
- qwen: 45-240s per call. First calls pay model load (21.1 GB on
  disk, 4.3 GB VRAM when loaded). The 240s cam call hit the 240s
  max-time ceiling -- likely still loading. Steady-state warm calls
  unknown from this battery; the interior_1 retry at 45.2s came
  after qwen was already resident (ollama ps showed 4312 MB).
- ollama ps AFTER battery: ONLY qwen resident (4312 MB). gemma3 was
  EVICTED by qwen's load. The two models do NOT co-reside on the
  10GB card -- confirms aria-0019's "replace, not co-reside" point.

## Verdict (mine, for the swap session -- NOT ratified)

- QUALITY: qwen beats gemma3 on JOB A on both shots (correct brand
  reads, no invented defects, more specific and more useful
  descriptions). JOB B: tie (both correct on 2/2 with the opaque
  exterior_N handicap).
- COST: qwen is 5-15x slower per call warm, and much worse cold.
  The eye's cadence is low (daily feed + on-demand), so 45s warm
  per read is survivable; 240s cold is not great but tolerable for
  a daily instrument.
- CO-RESIDENCY: impossible (gemma3 evicted when qwen loads). The
  swap is all-or-nothing: fear/rage mouths + fleet + identity-watch
  + eye-check all move to qwen, or the swap doesn't happen.
- D-012 GATE: qwen BEATS gemma3 on the eye's primary job (screenshot
  description). The gate's letter is satisfied on JOB A.

## Battery limitations (honesty section)

- n=2 per job per model. Two data points make a line, never a
  mechanism (law 3). This is a first comparison, not a verdict.
- Judge-blinding (third-model A/B scoring) was DESIGNED but not
  run -- the quality gap was legible directly (brand misreads vs
  correct reads) without a judge. A blinded judge pass would make
  this rigorous; worth running if the swap session wants it.
- ttft warm-state for qwen unmeasured (battery ran cold-ish).
- The 240s timeout fire on the first qwen cam call is itself data:
  a swap needs a max-time bump in eye-check.sh (45s -> 300s) or a
  keep-warm ping.

## Recommendation shape (for Nacho's decision, aria-0019)

Swap is technically viable and quality-positive, with three
engineering costs: (1) 6 scripts' model fields flip; (2) max-time
bump on eye-check; (3) fear/rage mouths lose their 6s phrasing
latency (become ~45s warm). If qwen stays resident (the pin
question, aria-0019 item 2), warm 45s is the steady state.