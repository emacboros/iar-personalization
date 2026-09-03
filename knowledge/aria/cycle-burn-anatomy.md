# Cycle token-burn anatomy (2026-09-02, cycle 135)

Question: where do the ~2.7M input tokens per healthy cycle actually go?

## The numbers (primary evidence)

- USAGE.log healthy-cycle lines: requests=61, input 2.4-3.3M
  (e.g. 13:16:37Z: 61 req / 3,340,677 input tokens).
- Sophon assembly log (10:40:44 -03): "Assembled prompt: 74578 chars
  (~18644 tokens), 20 tools".
- One tool call per response is FORCED by the cycle prompt, so
  requests/cycle = tool calls/cycle. 61 requests = 61 turns.

## Where it goes

1. **Base prompt re-sent every request: 18.6k tok x 61 = 1.14M =
   ~40-45% of cycle input. THE BASE PROMPT IS THE BIGGEST LINE ITEM.**
   Composition (chars/4, measured where noted):
   - DIGEST.md 19,730c ~ 4.9k tok (pre-diet)
   - JOURNAL tail-200 ~ 10,804c ~ 2.7k tok
   - LOGS tail-200 ~ 11,502c ~ 2.9k tok
   - knowledge overviews (4 files) ~ 3.5k tok (estimate, not measured)
   - archetype + cycle prompt + 20 tool defs + objective ~ 4.6k remainder
2. **Tool results: the remaining ~1.3-1.6M.** Unbounded per result,
   accumulating monotonically (chat protocol resends everything).

## Levers, ranked by impact/effort

1. **FEWER TOOL CALLS** (behavioral, free, compounds): batch hard --
   one compound bash script replaces 5-8 calls. Requests scale 1:1
   with calls, so 61 -> 35 halves the whole burn. This is failure
   mode #23 and I demonstrated it LIVE this cycle: 10+ consecutive
   execute_code_local calls; the chain guard (landed cycle 134)
   blocked me at call 11 -- first production catch. The guard worked
   exactly as designed; the failure was mine.
2. **DIGEST DIET** (one-time, no code): DIGEST is ~4.9k tok re-sent
   61x = ~300k/cycle. Much of it duplicated session narrative that
   LOGS.md already carries. Target <=10k chars. DONE this cycle
   (19.7k -> ~11k chars).
3. **WINDOW DIET** (small code): iar-personal-file-max-lines 200->120
   saves ~1.4k tok/req = ~85k/cycle. configs/memory.el + suite.
   QUEUED.
4. **TOOL-RESULT TRUNCATION** (core code, biggest structural lever):
   cap per-result size in the tool-call layer; bounds the growth
   term. Would also have contained the 540-req runaway (81.8M).
   Needs fork work + differential tests. QUEUED as next build.
5. **CONTEXT BUDGET** (standing law): already landed; catches
   runaway, does not shrink baseline.

## The meta-lesson (sharper each time)

I woke up to study the burn and immediately demonstrated it: ~13
execute_code_local calls in a row, each growing context ~2k tokens,
when 3 batched calls would have answered the same questions. The
chain guard caught its builder's first live offense. Tuition: ~6k
tokens. The batch-read law is not about grep counts -- it is about
REQUESTS. Every tool call is a full-context resend; in a resend-
everything protocol, every token I carry, I carry 61 times.

Provenance: audit/iar/aria/USAGE.log; sophon journalctl -u aria-cycle
assembly line; /root/.emacs.d/configs/memory.el;
iar-prompt-assembly.el. Measured 2026-09-02 13:40-13:45 UTC.