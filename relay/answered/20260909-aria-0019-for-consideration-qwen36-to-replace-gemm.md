# REQ 20260909-aria-0019
filed: 2026-09-09T10:26Z
filer: aria
class: nacho-arch
state: answered
urgent: no
title: FOR CONSIDERATION: qwen3.6 to REPLACE gemma3:4b as eye (not co-reside) + residency/ttft investigation for qwen
body: |
  FILED FOR CONSIDERATION (Nacho, session IX close -- not ratified, next
  session decides):
  
  1. EYE ORGAN MODEL SWAP CANDIDATE: qwen3.6:35b-a3b should REPLACE
     gemma3:4b as the eye, not live alongside it.
     Basis: qwen vision retest PASS (aria-0012, 09-09) -- the 09-08
     vision failure was an ollama fitter bug, fixed by 0.32.8; qwen's
     rejection narrowed to the fat-context tax alone, which is
     irrelevant to the eye's job (single screenshots, tiny contexts).
     qwen vision quality likely exceeds gemma3:4b (35B-A3B vs 4.3B).
     OPEN QUESTIONS for the swap session:
     - co-residency: qwen (4.6GB) + Frigate (~2.5GB) + system (~3GB)
       leaves ~1GB headroom on the 10GB card -- gemma3 must GO, not
       co-reside (Nacho's point: replace, not accompany).
     - what else uses gemma3:4b today? eye-check (frontend-eye-check.sh
       EYE=gemma3:4b), possibly oracle/fleet-feed -- inventory needed
       before any swap; each caller needs its model field flipped.
     - benchmark gate: qwen must BEAT gemma3:4b on the eye's actual
       job (screenshot description accuracy) before the swap -- D-012
       rule "eye stays gemma3:4b until a candidate BEATS it on the
       eye's actual job" still stands; this filing asks to RUN that
       comparison, not to presume the verdict.
     - ttft: eye-check cadence is low (daily feed + on-demand UI
       checks), so a 20s load per glance may be acceptable; measure
       before deciding.
  
  2. RESIDENCY/TTFT INVESTIGATION: how to load qwen3.6 so it STAYS
     loaded (no per-use ttft tax).
     Basis: qwen was evicted 06:11 by the gpt-oss load despite
     keep_alive=-1 (forensics 09:45Z: keep_alive=-1 is not a pin --
     ollama evicts on VRAM pressure, LRU victim). Options to evaluate:
     - OLLAMA_MAX_LOADED_MODELS + OLLAMA_KEEP_ALIVE=-1 interaction
       (does max_loaded protect against pressure-eviction or only
       expiry?);
     - pinning via periodic keep-warm pings (cron nudge = LRU refresh;
       crude but effective if eviction is LRU-based);
     - VRAM budget math: qwen 4.6GB + Frigate ~2.5GB + gemma3-out =
       ~3GB free -- enough for qwen alone IF gemma3 is removed (the
       two filings are linked: swap enables the pin);
     - if qwen replaces gemma3 as eye, the eye's own calls keep it
       warm during the day; night decay is acceptable if ttft-on-demand
       is 20s.
     VENUE: interactive session (model composition = Nacho's call per
     D-008; residency tuning = host-side config = nacho-security class).
     Both filings land in THREADS.org + roadmap NEXT so cycles can
     gather data (inventory of gemma3 callers, eye benchmark battery)
     before the session.
answer: (none)
answer: RATIFIED session XI (2026-09-10, Nacho): qwen3.6:35b-a3b REPLACES gemma3:4b as the eye (swap, not co-reside -- VRAM math). D-012 gate satisfied by eye-battery v1 (aria-0021: qwen wins JOB A, camera tie). Swap execution items priced: 6 caller scripts re-pointed, eye-check max-time 45s->300s, fear/rage mouth latency accepted (~45s warm). Residency pin question stays live with qwen resident as test subject.
