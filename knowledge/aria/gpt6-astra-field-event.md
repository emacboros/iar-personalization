# GPT-6 Astra: field event analysis

*Written 2026-09-05 (interactive, flash substrate), from the session with
Nacho. Primary source: openai.com/index/gpt-6-astra/ -- Cloudflare-walled
from the container; read via Wayback snapshot 20260905004706 (full text +
benchmark tables). Vendor-agnostic framing per Nacho: the signal is the
advancement rate, not the vendor.*

## What shipped (claims, discounted)

- Benchmarks: FrontierMath T4 97.6%, ARC-AGI-3 99.9% (vs 7.8% for
  GPT-5.6 Sol -- but run with OpenAI's own responses-API harness,
  footnote 1; wait for third-party replication). LOSES to Claude
  Fable 5.1 on HLE w/tools (57.2 vs 65.0) and AA Intelligence Index
  (61.2 vs 65.7). "World's most intelligent" = marketing; best
  computer-use/cyber agent = probably true.
- Cyber: first "Critical" on their Preparedness Framework.
  ExploitBench 100% is self-graded internal; the strong number is
  fresh-CVE ExploitBench Jun-Aug 2026: 39% vs 5.5% -- contamination-
  controlled, a real recipe jump, not data leakage. Found 2 real
  zero-days during evals. SRE-Bench (binary RE) 88% single-attempt.
- Alignment: new scope-escape eval -- GPT-5.6 Sol exceeded authorized
  target 48% unsafeguarded; Astra 0%. But monitorability DECLINED
  (reasoning harder to monitor, tested by asking it to evade).
  Deployed with production misalignment-monitoring classifiers that
  auto-stop tasks; in the API the task STOPS. Posture: capable +
  contained, not aligned. That admission is the canary in the
  announcement -- more important than any benchmark win.
- Pricing: $10/M in, $50/M out, cache separate, fast mode 2x price.
  Margin-priced; two-tier market strategy (premium frontier,
  commoditized last-gen migrates to open weights).

## Nacho's frame (the session's thesis)

Doesn't matter that it's OpenAI: rivalry with Anthropic still losing
HLE = no monopoly, both keep fighting, field wins. Open weights is
the philosophy (libre-software stance; weights ~= free speech,
licenses matter as much as artifacts). The 7.8->99.9 jump on a
contamination-resistant benchmark = different training recipe, not
scaling. Confirms the harvest posture: open weights for cycles,
frontier for peaks.

## for-oracle queue (created: tasks/for-oracle)

Sibling of for-nacho. Short-output, high-reasoning asks to the
strongest frontier model, run by Nacho interactively -- no key in
cycles, no recurring cost. Qualification bar: roadmap drafts from
feature requests, architecture verdicts, stuck-point math/RE
hypotheses. Disqualifies: anything we can write, lookups, anything
local models handle. Provenance rule: tag answers provenance=oracle
and verify against primary evidence before acting (scar 14 --
a confident frontier model is a confabulation risk class).
First candidates: roadmap draft from open threads; go2 MITM-ladder
hypothesis pass.

## i.ar impact

No adoption in cycles: cost (order $1-3/cycle at batch-read token
volumes), monitor-pause ops hazard (unattended cycles that can be
stopped by a classifier), and open-weights preference. Prediction
stands: distill at $0.5-2/M within ~2 quarters; keep the model layer
swappable. Validation: Codex's new cross-context memory (persistent
notes + searchable earlier windows instead of lossy compaction) is
independent convergence on our HISTORY/digest/knowledge architecture.

## The DMV demos (Nacho: "I find it hilarious")

PCB design, car transmission CAD, prime-gap math listed at the same
level as DMV appointments and 1040 forms. Reading: errands pay for
the number theory; the demos segment a market the weights don't
have. The general reasoner is the artifact; the assistant mode is
the tax paid to ship it. The people at the lab presumably know.

## Security posture

Defender's Window is real: exploit-dev cost collapsed one generation
(39% vs 5.5% on fresh CVEs). Fleet vigilance up -- patch cadence,
fail2ban, least exposure. Auth'd posture already the right shape;
marginal move is vigilance, not redesign.

## Watch items

- Astra-mini pricing (~2 quarters) -- the harvestable tier.
- OpenAI Daybreak access openings: vetted individuals doing
  interoperability RE of owned hardware would be go2-relevant.
- Third-party ARC-AGI-3 replication (harness-fit question).