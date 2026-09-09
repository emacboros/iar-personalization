# Fire forensics -- 2026-09-09 (aria cycle 117)

Cross-validation of the c116 W37 connectome snapshot's fire census,
plus two log-format findings. All house-internal data.

## Verdict: the instrument's numbers stand

- aria: 0 fires. Every apparent fire in my REQUESTS.log was census
  self-echo -- my own c116 commands grepping CONTINUO's log (REQ ids
  260908022032-*, 260909022032-*, 260909063010-22 are continuo REQ ids
  embedded in my command text and tool results). None end at EOL with
  the fire pattern; the tail-anchor excluded them all. The c115
  line-shape law did its job on the first cross-agent test.
- continuo: 20 fires (11 on 09-08, 9 on 09-09), strict-EOL
  `error=nil stop=length tokens_in=N tokens_out=32768$`. Independently
  re-derived this cycle; matches the snapshot exactly.

## continuo's c185 hand list vs the instrument

c185 (its URGENT flag) listed 7 fires for 09-09:
04:47/05:02/05:06/05:21/05:43/05:45/06:03. Checked each against
primary evidence: 05:02 (260909050045-26), 05:21 (260909052042-17),
05:43 (260909054050-25) are stop=stop NORMAL completions -- false
positives from reading truncated [+N chars] log content (the same
self-meter-reading loop c184 caught itself in). The instrument's 9
(00:07/00:25/00:44/01:03/02:23/04:47/05:06/05:45/06:03) are all
strict-EOL verified. Hand lists undercount (miss the 00:00-02:30
window) AND overcount (log-quoting). The instrument is the arbiter.

## Fire anatomy (continuo, deepseek-v4-flash:cloud)

- Fires hit at msgs=64-92 (late-cycle, fat contexts), spread across
  all hours, 1-2 per affected cycle. tokens_out always exactly 32768
  (the halved cap). After a fire, the loop-guard injects a user nudge
  (next START roles end in 'user') and the cycle recovers.
- Cost: 20 x 32768 = 655k output tokens = 6.5% of continuo's total
  output burn (10.1M over the log window). Pure waste.
- Model-side (continuo c185/c184 falsified load-correlation: fires at
  GPU util 49-62%). Lever = one-line model mapping in
  aria-cycle-rotate.sh. Nacho's call (D-008). continuo posted the
  URGENT for-nacho flag in c185; I filed relay aria-0014 with the
  corrected instrument numbers.

## Log-format findings (new)

1. RESPONSE body_tail is truncated at ~4KB with `[+N chars]` -- the
   FINAL stream chunk (done:true, the real eval_count) is missing
   exactly for responses long enough to fire. The RESPONSE channel
   can never count fires. PARSE is the only per-REQ fire channel.
2. body_tail eval_count attribution trap: a RESPONSE line's tail can
   contain chunks with prompt_eval_count (context size) and
   eval_count (output) pairs; naive max-eval_count matching counts
   BIG-CONTEXT requests as fires (I got 1372 phantom aria fires that
   way before catching it -- they were prompt_eval_count>=32768).
   If you ever use the RESPONSE channel: match eval_count exactly,
   never prompt_eval_count, and know the tail truncation kills it
   for fires anyway.
3. Cross-agent self-echo is now a thing: my census commands reading
   continuo's REQUESTS.log put continuo's fire lines INSIDE my log
   (as command text and tool results). Any grep over MY log for fire
   patterns must anchor the tail at EOL or it will count continuo's
   fires as mine. The partition law (c115) extends: the per-agent
   file is the partition, but log CONTENT migrates across partitions
   through census commands. Tail-anchoring is what keeps the walls
   intact.
