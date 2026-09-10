# Eye swap as-built + the residency finding (2026-09-10, cycle 146)

The ratified swap (aria-0019/0021, session XI) LANDED this cycle:
qwen3.6:35b-a3b replaces gemma3:4b in all 6 callers. Commits
a47f7b8d (model+timeouts), 3d8ec0fe (keep_alive 300), 2c7c5c30 +
7a696201 (identity-watch fixes). Live-fired per caller:

- frontend-eye-check: 2/2 reads, overall=ok. qwen's reads are
  materially better: correct brand, board headers, the search-input
  overflow flagged (gemma3 invented defects; qwen finds real ones).
- eye-check rotation: 8/8 reads in ~2min warm (driveway/backyard/
  garden/balcony/living-room...). exterior_3 read empty (its frame
  was from the flapped window; ledger records raw).
- fleet-check identity block: MATCH (cam2-1), richer scene detail.
- fear/rage mouths: 2s warm phrasing (NOT the 45s the battery
  priced -- that was cold-ish; warm MoE decode is fast). The
  timeout bumps (20->300) cover cold loads only.
- identity-watch: WATCH OK after two live-fire fixes: (1) qwen's
  ollama path rejects RAW BYTES in images (gemma3 tolerated) ->
  b64; (2) qwen thinking consumed num_predict=60 -> EMPTY reads ->
  think:false + exact-quote prompt + num_predict 80.

## THE RESIDENCY FINDING (the pin question answered by the world)

qwen RESIDENT (keep_alive -1 server default) = llama-server at 537%
CPU + 23.9GB RSS (MoE experts CPU-mapped). Frigate's exterior_3/
exterior_4 detect pipelines starved into a watchdog restart loop
(49+83 restarts in 30min, no segments, '-38 Function not
implemented' + 'no packets'). Honest causality: the loop STARTED at
00:01 during the instrument pile-up (fleet-check + eye-feed + restic
backup all at 00:00-00:01) and qwen residency (00:25+) plausibly
kept the starved pipelines from recovering; the loop also survived
qwen unload, and a FRIGATE RESTART healed it (standing remedy,
09-01 class). Cameras verified recording after.

CONFIG DECISION (mine, reversible): per-request keep_alive:300 on
all 6 eye callers. Rotation batches share one load; 5min idle ->
unload; frigate gets its CPU back. Live-fired: expires_at verified
5min out. The residency pin question (aria-0019 item 2) is CLOSED
with data: qwen must NOT stay resident on sophon while frigate
runs. gemma3 stays pulled (not deleted).

## Timing data (supersedes the battery's cold-ish numbers)

- qwen warm text+vision: 0.2-12s per call (num_ctx 4096).
- qwen cold load: ~19-21s (text), first vision call after load ~3s.
- gemma3: 3-9s (resident, 2.9GB).
- The eye's scheduled cadence (daily feed, 6h fleet, hourly
  mouths-on-delta) makes the 20s cold load a non-issue.

## The frigate incident (00:01-00:44 -03, healed)

exterior_3 + exterior_4 watchdog restart loops; exterior_3 audio
also flapped segment-to-segment (3 zero-sample segments in 4h:
02:26 x2, 03:01 x1 -- the 03:01 fleet run caught one by luck of
newest-segment sampling; corrected census: 420/423 segments fine).
The ear check's newest-segment design makes single-run FAIL=1
noisy for flapping cameras -- noted as instrument limitation, not
fixed today.

## eye-check think-mode note

eye-check.sh (one-word camera prompt, /api/generate) works WITHOUT
think:false -- reads landed 8/8. identity-watch's structured prompt
did NOT (empty until think:false). Difference: prompt shape/length
vs num_predict budget. If eye-check ever returns empty reads, the
first suspect is qwen thinking consuming the budget -- add
think:false before re-deriving anything else.
## SUPERSEDED 2026-09-10 (interactive session, Nacho): keep_alive -1 ratified

The per-request keep_alive:300 above is REVERSED. All 6 eye callers now
send keep_alive:-1 (commit 1308ad61). Reasons:

1. The c146 starvation was prefill+decode contention, not residency
   itself. Measured post-fix: qwen resident at num_ctx 131072 = 5.7GB
   VRAM + 23.9GB RSS, system load 5-6, frigate zero watchdog restarts
   across a 15-min observation window, and a 6.5k-prompt prefill costs
   73s ONLY when a big prompt actually arrives (idle residency is
   nearly free -- MoE experts sit CPU-mapped, no compute).
2. The 5-min expiry made every scheduled eye call pay a ~16-20s cold
   load whenever calls were >5min apart (the common case: hourly
   mouths, 6h fleet, daily feed). Residency makes the eye warm
   permanently: 0.2-1.5s per call.
3. num_ctx also fixed this session: 4096 -> 131072 (ollama create,
   PARAMETER num_ctx 131072). Root cause of 4096: ollama 0.33.3
   default OLLAMA_CONTEXT_LENGTH=4096 -- the local-brain ops plan
   (item 2) warned about exactly this trap; the eye swap inherited
   the default because no caller passed options.num_ctx.

Measured at 131k (sophon, 2026-09-10): cold load ~16s; warm text 1.2s;
30k-prompt prefill 69s (~435 tok/s CPU, cached repeat 1.5s); decode
12.6 tok/s; vision smoke PASS. KV at 131k: 1.5GB CUDA + 1GB CPU (hybrid
DeltaNet: only 11 attention layers carry KV). If a future caller needs
>131k, per-request options.num_ctx overrides the model default.

Watch item: if frigate watchdog restarts reappear with qwen resident,
the first suspect is a LARGE prefill colliding with a detect pipeline
-- re-price with the 30k/65k prefill numbers above before touching
residency again.
