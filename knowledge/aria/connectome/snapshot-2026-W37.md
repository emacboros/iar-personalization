# Connectome snapshot 2026-W37

Generated: 2026-09-10 19:04 UTC | window: 5 s | TOPN: 15

## Population

| source | tool_call lines |
|---|---|
| merged (both hosts) | 90817 |
| aria | 56122 |
| continuo | 24487 |

## Co-firing (top pairs, 5s window)

### aria
```
  36053 execute_code_local->execute_code_local
   1283 read_file->execute_code_local
   1051 execute_code_local->read_file
    477 execute_code_local->read_roadmap
    381 read_roadmap->read_task
    307 write_file->execute_code_local
    293 read_file->read_file
    273 read_task->execute_code_local
    265 execute_code_local->append_file
    252 append_file->append_file
    248 append_file->execute_code_local
    163 execute_code_local->write_file
    138 read_task->read_task
    133 read_knowledge->read_knowledge
    119 write_roadmap->execute_code_local
```

### continuo
```
  10091 execute_code_local->execute_code_local
    729 read_file->execute_code_local
    454 execute_code_local->read_file
    377 execute_code_local->read_roadmap
    269 read_roadmap->read_task
    240 read_task->execute_code_local
    184 append_file->execute_code_local
    164 append_file->append_file
    162 execute_code_local->append_file
    111 write_file->execute_code_local
    109 execute_code_local->write_file
    104 list_directory->list_directory
     88 execute_code_local->git_commit
     68 read_file->read_file
     68 execute_code_local->read_knowledge
```

## N-gram motifs (2-grams, 3-grams)

### aria 2-grams
```
  22987 execute_code_local->execute_code_local
    811 read_file->execute_code_local
    738 execute_code_local->read_file
    293 execute_code_local->read_roadmap
    290 execute_code_local->append_file
    269 append_file->execute_code_local
    226 execute_code_local->write_file
    222 write_file->execute_code_local
    220 append_file->append_file
    207 read_roadmap->read_task
    206 read_task->execute_code_local
    181 read_file->read_file
    105 write_roadmap->execute_code_local
     93 read_roadmap->execute_code_local
     69 read_task->read_task
```
### aria 3-grams
```
  14406 execute_code_local->execute_code_local->execute_code_local
    485 read_file->execute_code_local->execute_code_local
    391 execute_code_local->read_file->execute_code_local
    366 execute_code_local->execute_code_local->read_file
    185 execute_code_local->execute_code_local->read_roadmap
    166 execute_code_local->execute_code_local->append_file
    134 execute_code_local->write_file->execute_code_local
    114 execute_code_local->read_roadmap->read_task
    107 append_file->execute_code_local->execute_code_local
     97 read_task->execute_code_local->execute_code_local
     94 read_roadmap->read_task->execute_code_local
     92 execute_code_local->append_file->execute_code_local
     91 execute_code_local->append_file->append_file
     81 execute_code_local->execute_code_local->write_file
     77 write_file->execute_code_local->execute_code_local
```
### continuo 2-grams
```
   7924 execute_code_local->execute_code_local
    578 read_file->execute_code_local
    537 execute_code_local->read_file
    241 execute_code_local->append_file
    221 execute_code_local->read_roadmap
    206 append_file->execute_code_local
    205 read_task->execute_code_local
    154 read_roadmap->read_task
    139 list_directory->list_directory
    130 append_file->append_file
    112 execute_code_local->write_file
    108 write_file->execute_code_local
     94 read_file->read_file
     84 list_directory->execute_code_local
     84 execute_code_local->read_task
```
### continuo 3-grams
```
   4560 execute_code_local->execute_code_local->execute_code_local
    284 read_file->execute_code_local->execute_code_local
    273 execute_code_local->read_file->execute_code_local
    217 execute_code_local->execute_code_local->read_file
    142 execute_code_local->execute_code_local->read_roadmap
    133 execute_code_local->execute_code_local->append_file
    121 append_file->execute_code_local->execute_code_local
    116 read_task->execute_code_local->execute_code_local
    104 execute_code_local->read_roadmap->read_task
     71 read_roadmap->read_task->execute_code_local
     69 read_file->execute_code_local->read_file
     64 execute_code_local->append_file->append_file
     62 execute_code_local->write_file->execute_code_local
     61 execute_code_local->execute_code_local->write_file
     60 execute_code_local->append_file->execute_code_local
```

## File-touch graph (write side; read side only post 2026-09-08)

### aria writes (top 15)
```
   1228 name=append_file 
    583 name=write_file 
    130 name=git_commit 
     41 name=create_task 
     40 name=write_subtask 
    511 path=/root/personalization/audit/iar/aria/HISTORY.log
    420 path=/root/personalization/audit/iar/aria/JOURNAL.org
    142 path=/root/personalization/audit/iar/aria/LAST-CYCLE.txt
     49 path=/root/personalization/audit/iar/aria/THREADS.org
     46 path=/root/personalization/audit/iar/aria/DIGEST.md
     42 path="
     41 path=/root/personalization/tasks/iar/aria/ROADMAP.org
     40 path=/'
     31 path=/root/personalization/knowledge/aria/bin/rage-organ.sh
     19 path="/var/home/nacho/repos/iar-personalization...
     16 path=/root/personalization/knowledge/aria/bin/relay
     16 path=/root/personalization/knowledge/aria/bin/fleet-check.sh
     14 path=/root/personalization/knowledge/aria/connectome/snapshot-2026-W37.md
     14 path=/root/personalization/knowledge/aria/bin/connectome-snapshot.sh
     13 path=/root/personalization/knowledge/aria/vision-eye.md
```

### continuo writes (top 15)
```
    438 path=/root/personalization/audit/iar/continuo/JOURNAL.org
    400 path=/root/personalization/audit/iar/continuo/HISTORY.log
    238 path=/root/personalization/audit/iar/continuo/LAST-CYCLE.txt
    166 path=/root/personalization/tasks/iar/continuo
    151 path=/root/personalization/audit/iar/continuo/STATE.md
    136 path=/root/personalization/tasks/iar/continuo/continuo
     77 path=/root/personalization/audit/iar/continuo/DIGEST.md
     58 path=knowledge/aria/token-burn-audit.md
     52 path=/root/personalization/tasks/iar
     48 path=/var/home/nacho/repos/agora/bot/aria-cycle.conf
     38 path=/root/personalization/knowledge/aria/token-burn-audit.md
     37 path=/root/personalization/tasks/iar/continuo/breaker-grace-compliance.org
     36 path=/root/personalization/knowledge/aria
     36 path=aria/token-burn-audit.md
     34 path=/root/personalization/tasks/iar/continuo/interactive-bundle-nacho
```

### load-bearing (touched by BOTH citizens)
```
path=/root/i.ar/emacs.d/configs/loop-guard.el
path=/root/i.ar/emacs.d/configs/memory.el
path=/root/i.ar/emacs.d/init.d/agent/iar-agent-cycle.el
path=/root/i.ar/emacs.d/init.d/security/iar-loop-chain-guard.el
path=/root/i.ar/emacs.d/init.d/security/iar-loop-guard-chain.el
path=/root/i.ar/emacs.d/init.d/security/iar-loop-guard.el
path=/root/i.ar/emacs.d/init.d/tool-call/iar-tool-call.el
path=/root/i.ar/emacs.d/test/test-cross-response-repetition.el
path=/root/i.ar/emacs.d/test/test-loop-chain.el
path=/root/i.ar/emacs.d/test/test-truncated-output-guard.el
path=/root/personalization/affect/CURRENT-AFFECT.md
path=/root/personalization/audit/iar/aria/DIGEST.md
path=/root/personalization/audit/iar/aria/JOURNAL.org
path=/root/personalization/audit/iar/aria/LAST-CYCLE.txt
path=/root/personalization/audit/iar/aria/THREADS.org
```

## Token economics (REQUESTS.log, per agent)

### aria
```
n=3506 p50=60821 p90=108793 p99=174327 max=188896
```
### continuo
```
n=2423 p50=28092 p90=45184 p99=65207 max=325732
```

## Silence (hang-signal channel, REQUESTS.log PARSE gaps)

Max gap between consecutive PARSE lines per agent. Gaps > 600s
(tool-timeout ceiling) are hang-class candidates; cross-check the
from/to stamps against journalctl rotation logs before claiming a hang.

### aria
```
max_gap_s=2494 from=2026 09 10 07 54 29 to=2026 09 10 08 36 03 gaps_over_600s=20
```

### continuo
```
max_gap_s=27032 from=2026 09 09 11 33 25 to=2026 09 09 19 03 57 gaps_over_600s=51
```

## Fire census (truncated-output fires, REQUESTS.log PARSE lines)

A fire = PARSE line ending exactly with `error=<X> stop=length
tokens_in=<N> tokens_out=<M>` -- tail-anchored so census commands
never count their own specs= echo (c32/c114). stop=length at the
32768 halved cap = output ceiling hit mid-turn. Cross-check bursts
against journalctl before attributing cause (law 26: two data
points make a line, never a mechanism).

### aria
```
2026-09-10: 1
TOTAL fires: 1
```

### continuo
```
2026-09-09: 8
2026-09-10: 8
TOTAL fires: 16
```

## Fence rejections (status=rejected, post 0f552b1)
```
336
```

## Baseline caveat

FIRST SNAPSHOT = baseline only. No trend claims until snapshot 2.

