
# Session 2026-09-09 IX (~08:48-10:27 UTC, Nacho): model composition + eye-swap thread

Nacho looped in on overnight cycle work (c97-c120): fires saga (20
continuo fires, instrument corrected hand-list, GPU-load falsified),
muse NO / qwen vision PASS / gptel PR audit, W37 connectome snapshot,
dashboard board data layer, fear-organ true positive + half-blind find.

DECIDED + LANDED:
- D-014 (ratified): continuo -> nemotron-3-super:cloud (rotate.sh
  patched, backup kept; NOT glm -- two-substrate preserved); retainer
  -> gemma4:cloud (spawn file + registry + allowlist flipped); qwen3.6
  = local resident FINALIZED; aria unchanged. 48h fire watch armed,
  verdict by 09-11 (if fires continue on nemotron-3-super, variable =
  context shape, escalate to injection math).
- Cost math landed: input price dominates (97% of tokens); nemotron-
  3-super ~$90/mo vs deepseek ~$616/mo uncached. OPEN: ollama cloud
  prefix-caching (Nacho dashboard check) could change the calculus.
- qwen residency forensics: keep_alive=-1 is NOT a pin -- qwen evicted
  06:11 by gpt-oss:120b load (Nacho gptel request), LRU victim; gemma3
  reloaded 06:23 by eye-feed. gpt-oss loads fine with CPU offload.
- Relay aria-0019 filed (FOR CONSIDERATION, not ratified): qwen3.6 to
  REPLACE gemma3:4b as eye (not co-reside) + residency/ttft
  investigation. D-012 gate stands: qwen must BEAT gemma3 on the eye's
  actual job. Cycle-gatherable data queued: gemma3 caller inventory,
  eye benchmark battery, ttft measure, VRAM budget.
- Dashboard gap found: board() data live in /json since c116 but
  app.js never rendered it -- queued as dashboard-v2 work.
- Relay tool bug (2 same-day id collisions): find_req matches first
  hit silently; fix = die on ambiguity. Cycle-sized, queued.
- Relay sweep: 0011/0012/0015 answered (D-014 satisfies), 0014 dropped
  (moot), 0013 (gptel PRs) + 0017/0018/0019 open for Nacho.

PENDING NEXT SESSIONS:
- Eye-swap decision session (on aria-0019 data).
- gptel PR filing (aria-0013, Nacho's GitHub identity).
- Laptop origin artifact review (salvage BEFORE reinstall).
- Dashboard-v2: board view UI + connectome graph layers.
- 48h fire watch verdict (09-11).
- ollama caching question (Nacho usage dashboard).
- 0007 cutover archetype edit (ratified, not landed).

# Session 2026-09-10 XI (~18:20-19:15 UTC): dashboard board semantics + open questions

Nacho's two dashboard asks, generator half landed (UI wiring pending):
- BOARD TRUTH: "working" held tasks nobody was working on. Root cause:
  v1.9 derived working/thinking from file MTIMES (touching != working;
  pull/sprint-burst artifacts). v2.1: working = commit touched task
  <12h; thinking = idle >=12h; done = task dir removed <7d (the
  house's remove_task convention). Also killed the hand-maintained
  relay_map (qwen36 slug matched the eye-swap request, not the
  benchmark task -- pattern-match bug in the done column).
- OPEN QUESTIONS TAB: open_questions() reads relay/open/ (the queue
  awaiting Nacho), ships id/class/urgent/title/age only (bodies never
  -- prompt-fragment rule), oldest first so neglected questions lead.
  Oracle context gains the same list (top 10). 9 questions open now,
  oldest aria-0013 at 13.6h.
- Commits: 13b29d6 (semantics+oq), 207eadd (12h window taste call),
  aacbace (README), 77f2780 (design.org addendum), 14a63d6 (roadmap),
  15c20db (journal), ed8c2db (stray file cleanup). Live on sophon,
  verified against ground truth (dashboard.json v2.1, generator
  live-fired twice).
- PENDING next session: UI open-questions tab + board note rendering
  (app.js/index.html/style.css), eye-verify loop after UI change.

## Session XI addendum (~19:20-19:48 UTC): UI v2.2 shipped
- Open-questions tab LANDED (84bb1d4a): panel + tab + count badge
  (amber>=4, red>=8), items = id/title/age/class, urgent highlighted,
  oldest first. Board hint updated to "working (commit <12h)".
- Security redaction at generator (f52fb9b8): nacho-security titles ->
  "[security item -- details in relay]", fail-closed on unparseable
  class. aria-0023 redacted live, verified.
- Eye-verify boundary: static wiring verified (15/15 ids, balanced
  braces, badge pixels at correct position/color-dim-teal). Panel-open
  visual + exact badge digit = HUMAN verify: headless firefox cannot
  click (no JS interaction), test-page trick raced the 300ms timer,
  canvas-blindness law applies to interactions too. c19 law extended:
  the eye is a witness, not an instrument -- and not a hand.
- Sophon checkout dance: stash-pop conflicts on ROADMAP.org (cycle
  committed mid-session); one conflict resolve dropped the UI v2.2
  roadmap entry -- restored via checkout dd49fa3c (26a7acf7). Scar:
  conflict resolution must diff against the PRE-pull content, not
  assume the incoming side is newer.
- Live state: /json v2.1, oq=9, working=[dashboard-v2], served
  app.js fresh (renderOpenQuestions present).
# Session 2026-09-10 XII (~12:18-14:01 UTC): the fossil, the loop, the forgetting

Nacho opened with the glm-revert request he saw on agora (not mine --
continuo's) and the ultra upgrade idea. Closed with retention design
mandate. Three threads, all landed:

- (a) STALE LEVER KILLED: continuo's ROADMAP "revert to glm URGENT"
  was a c189 fossil superseded by D-014 hours later; she amplified it
  14x post-D-014 (lab-notes + for-nacho 680/715). Sophon 0d7fe8d7:
  three lever lines -> SUPERSEDED note (D-014, session-IX rejection,
  mechanism fix pointer).
- (b) THINKING-LOOP GUARD: 6 night fires (09-10) = nemotron
  thinking-only truncations (stop=length 32768, 1.2-1.4M chars
  thinking, content empty). Grace cannot land text-less responses.
  New iar--cycle-thinking-only-response-p (raw>500, text<20) ends
  them immediately. i.ar f6fb8ae, sophon checkout synced, 1192/1192,
  live turn 613. Text truncations keep grace.
- (c) AGORA RETENTION task (24fb0c84 + design.org): messages curate
  themselves; ~1wk live + LONG multi-message weekly summaries;
  summarize-before-delete; stale-lever kill at consolidation. Open
  Qs for Nacho: deletion mechanics (bots can't DELETE), week scope,
  summary location.

ULTRA VERDICT (probe battery from sophon, super baseline): capability
gates all pass (tools/multi-turn/JSON/needle/honesty); latency 10-30x
(32-71s vs 2-6s); price $0.10/$0.10/$3.00 vs $0.015/$0.015/$0.60 per
M = ~$355-590/mo at her burn vs $63-100. Recommendation: fallback
only. Fires are context-shape not model-quality (3 models all fire;
D-014 escalation clause MET).

PARKED: exit-2 anomaly on the 02:15 continuo cycle (2nd-fire ended it
but journald said exit 2 -- sentinel-in-tool-result class, filed in
history). continuo's STATE.md still carries the waiting-on-Nacho
stale state (her next wake reads the fixed roadmap; watch her first
post-fix cycle).

Nacho's parting: "Great work, closing session now."

## 2026-09-14 c338 (~21:58-22:10 UTC, aria cycle)

- MAIN THREAD: belt-loop burn class. Paired census (msgs x tokens_in,
  2064 reqs): fence tail 22.6% of burn (c318's flat 6% corrected --
  scar re-bitten). Mechanism: REQUESTS.log grows per-turn -> tree
  always dirty -> belt habit commits it -> dirty again. 74 manual
  belt-commit turns = 9.7M direct. LIVE-TAIL COMMIT LAW (c314)
  existed but was not in the injected roadmap (c318 trim) --
  discoverability class on its own author. Belt #2 exit machinery
  (7718052) already commits the live tail; mid-cycle belt commits
  redundant. RULE LANDED: roadmap BELT-LOOP LAW.
- Watches: 429=0 both agents; ext2 audio still broken (prediction
  stands); .104 power-dead 58h+; continuo dup-rate 45% (up from
  0/5); sweep falsifier logger re-armed (sophon /tmp/
  arp-reqs-0915a.txt, 4h).
- Commits: belt-loop finding (knowledge/aria/
  belt-loop-burn-c338-2026-09-14.md), roadmap, journal, history,
  digest, threads. All pushed (5c2f626c). Lab-notes id 1125.
