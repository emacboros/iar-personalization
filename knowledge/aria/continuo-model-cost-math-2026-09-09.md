# continuo replacement cost math (2026-09-09, from live 24h burn)

24h burn (dashboard, 09:15Z):
- continuo: 2850 req, 84.8M input, 2.88M output (deepseek-v4-flash)
- aria:     6999 req, 375.0M input, 2.61M output (glm-5.3-flash)

Monthly (x30): continuo ~2.54B in / 86M out. aria ~11.25B in / 78M out.

Per-model monthly cost for CONTINUO's workload (input / cached-in / output $/M):
- deepseek-v4-flash (current): 2.54B*0.22/1M + 86*0.66 = $559 + $57 = $616/mo
  (cached-in would be $35 if the cache hit; unknown)
- nemotron-3-super:cloud:      2.54B*0.015/1M + 86*0.60 = $38 + $52 = $90/mo
- nemotron-3-nano:cloud:       2.54B*0.06/1M + 86*0.24 = $152 + $21 = $173/mo
- gpt-oss:120b:                2.54B*0.15/1M + 86*0.60 = $381 + $52 = $433/mo
- glm-5.3-flash (aria's):      2.54B*0.15/1M + 86*0.50 = $381 + $43 = $424/mo
- minimax-m2.7:                2.54B*0.30/1M + 86*1.20 = $762 + $103 = $865/mo
- deepseek-v4-pro:             2.54B*0.66/1M + 86*1.98 = $1676 + $170 = $1846/mo
- kimi-k2.6:                   2.54B*0.95/1M + 86*4.00 = $2413 + $344 = $2757/mo
- nemotron-3-ultra (retainer): 2.54B*0.10/1M + 86*3.00 = $254 + $258 = $512/mo
- gpt-oss:20b:                 2.54B*0.07/1M + 86*0.30 = $178 + $26 = $204/mo
- gemma4:cloud:                2.54B*0.14/1M + 86*0.40 = $356 + $34 = $390/mo
- mistral-large-3:             2.54B*0.50/1M + 86*1.50 = $1270 + $129 = $1399/mo
- qwen3.5:397b:                2.54B*0.60/1M + 86*3.60 = $1524 + $310 = $1834/mo

NOTE: input price dominates (97% of tokens are input). The cached-input
column matters enormously if ollama's cloud honors prefix caching across
requests -- deepseek cached-in is $0.014/M (16x cheaper). If prefix caching
works for the cycle's re-sent base prompt, deepseek-v4-flash real cost
could be ~$100-150/mo, not $616. UNKNOWN: whether ollama cloud caching is
automatic. This is the single biggest cost unknown.
