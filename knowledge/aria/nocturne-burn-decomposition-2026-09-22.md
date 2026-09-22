# Nocturne burn decomposition (c210, 2026-09-22 ~03:50Z)

Question: why does a consolidator pass burn 19.5M input tokens
(09-21 pass) to produce a 10k-char digest? BURN decomposition
(c318: burn = requests x avg_context) applied to her.

## The measured anatomy (09-21 pass, 16:03:32Z-16:34:00Z, 30.5min)

- 144 requests (143 tool calls + 1), monotonic context growth
  7.5k -> 257k tokens, NO truncation ever (suffix-anchored census).
- Total input: 19,515,584 tokens. Per-request growth sum: 249,961.
  Repeated-context share: 98.7% (19.27M of 19.5M).
- Cloud KV cache (deepseek-v4.1-flash:cloud via ollama cloud):
  prompt_eval_cached_count ~= 50% of prompt every turn (15 sampled
  turns, share 46-50%). So ~9.6M of the repeated tokens are
  effectively re-paid per pass.
- Tool census: 117 execute_code_local (59 python-heredoc patch
  scripts on DIGEST.proposed.md, 15.6KB distinct, ~145KB cumulative
  in-context), 23 write_file (full proposal rewrites), 3 read_file.
- 68 of 144 turns touched DIGEST.proposed.md. Her edit loop IS the
  burn: read-modify-write cycles on a 10k file, each turn re-sending
  the whole growing context.
- iar.sh reported "Turns: 8" = 8 delimiter-less nudges; turn-count
  does not count tool-loop turns (iar-agent-cycle.el c39 comment).
  REQUESTS.log PARSE lines are the honest burn unit.

## 4-pass comparison (suffix-anchored census)

| pass  | reqs | tokens_in | growth | repeated |
|-------|------|-----------|--------|----------|
| 09-18 | 109  | 15.57M    | 223k   | 98.6%    |
| 09-19 | 64   | 3.73M     | 113k   | 97.0%    |
| 09-20 | 76   | 6.25M     | 76k    | 98.8%    |
| 09-21 | 144  | 19.52M    | 250k   | 98.7%    |

Request count is the variance; repeated share is constant ~98.5%.
More requests = more re-paid context. REQUEST COUNT is the lever.

## Fix shape (rides the 10-01 D-017 proposal)

1. Wrapper prompt: "write the proposal ONCE, at the end, as a
   single write_file. Do not read-modify-write it in a loop."
   Her 23 rewrites + 59 patches become 1 write.
2. Wrapper prompt: tool budget line (~40 calls) -- the fence fires
   at 100 with a warning; a prompt-level budget converges earlier.
3. Batch reads: the prompt already lists changed files; ask her to
   read them in ONE batched command, not 3 read_file + git walks.
4. Optional: iar.sh --num-predict is already 8192 for her (0085);
   output is not the problem. Input is.

Expected: 144 -> ~50 reqs, 19.5M -> ~7M in/pass, ~64% burn cut on
the heaviest pass. Falsifier: next pass after the prompt change,
same census (suffix-anchored), reqs + tokens_in + repeated share.
