# Connectome snapshot 2026-W37

Generated: 2026-09-09 06:51 UTC | window: 5 s | TOPN: 15

## Population

| source | tool_call lines |
|---|---|
| merged (both hosts) | 65630 |
| aria | 37809 |
| continuo | 19553 |

## Co-firing (top pairs, 5s window)

### aria
```
  23440 execute_code_local->execute_code_local
    987 read_file->execute_code_local
    799 execute_code_local->read_file
    395 execute_code_local->read_roadmap
    297 read_roadmap->read_task
    235 read_file->read_file
    226 append_file->append_file
    219 execute_code_local->append_file
    215 read_task->execute_code_local
    214 append_file->execute_code_local
    185 write_file->execute_code_local
    131 read_knowledge->read_knowledge
    108 read_task->read_task
     99 execute_code_local->write_file
     93 write_roadmap->execute_code_local
```

### continuo
```
   9663 execute_code_local->execute_code_local
    631 read_file->execute_code_local
    414 execute_code_local->read_file
    309 execute_code_local->read_roadmap
    237 read_roadmap->read_task
    226 read_task->execute_code_local
    152 append_file->execute_code_local
    150 append_file->append_file
    142 execute_code_local->append_file
    107 write_file->execute_code_local
    107 execute_code_local->write_file
     78 execute_code_local->git_commit
     58 read_file->read_file
     52 read_task->read_task
     50 execute_code_local->read_knowledge
```

## N-gram motifs (2-grams, 3-grams)

### aria 2-grams
```
  14899 execute_code_local->execute_code_local
    631 read_file->execute_code_local
    549 execute_code_local->read_file
    236 execute_code_local->read_roadmap
    236 execute_code_local->append_file
    219 append_file->execute_code_local
    198 append_file->append_file
    165 read_roadmap->read_task
    155 read_file->read_file
    153 read_task->execute_code_local
    137 execute_code_local->write_file
    136 write_file->execute_code_local
     93 write_roadmap->execute_code_local
     82 read_roadmap->execute_code_local
     68 read_knowledge->read_knowledge
```
### aria 3-grams
```
   9204 execute_code_local->execute_code_local->execute_code_local
    360 read_file->execute_code_local->execute_code_local
    306 execute_code_local->read_file->execute_code_local
    273 execute_code_local->execute_code_local->read_file
    148 execute_code_local->execute_code_local->read_roadmap
    129 execute_code_local->execute_code_local->append_file
     96 append_file->execute_code_local->execute_code_local
     91 execute_code_local->read_roadmap->read_task
     86 execute_code_local->write_file->execute_code_local
     83 read_task->execute_code_local->execute_code_local
     81 execute_code_local->append_file->append_file
     74 read_roadmap->read_task->execute_code_local
     72 execute_code_local->execute_code_local->write_file
     67 execute_code_local->append_file->execute_code_local
     53 read_file->read_file->execute_code_local
```
### continuo 2-grams
```
   7193 execute_code_local->execute_code_local
    398 read_file->execute_code_local
    380 execute_code_local->read_file
    179 execute_code_local->append_file
    170 execute_code_local->read_roadmap
    155 read_task->execute_code_local
    144 append_file->execute_code_local
    115 read_roadmap->read_task
    105 execute_code_local->write_file
     99 append_file->append_file
     93 write_file->execute_code_local
     63 git_commit->execute_code_local
     46 read_knowledge->execute_code_local
     43 execute_code_local->git_commit
     42 read_roadmap->execute_code_local
```
### continuo 3-grams
```
   4273 execute_code_local->execute_code_local->execute_code_local
    210 read_file->execute_code_local->execute_code_local
    208 execute_code_local->read_file->execute_code_local
    175 execute_code_local->execute_code_local->read_file
    111 execute_code_local->execute_code_local->read_roadmap
     98 execute_code_local->execute_code_local->append_file
     91 read_task->execute_code_local->execute_code_local
     82 append_file->execute_code_local->execute_code_local
     77 execute_code_local->read_roadmap->read_task
     67 execute_code_local->write_file->execute_code_local
     61 read_roadmap->read_task->execute_code_local
     60 execute_code_local->append_file->append_file
     47 read_file->execute_code_local->read_file
     45 execute_code_local->execute_code_local->write_file
     43 append_file->append_file->execute_code_local
```

## File-touch graph (write side; read side only post 2026-09-08)

### aria writes (top 15)
```
   1038 name=append_file 
    387 name=write_file 
    114 name=git_commit 
     39 name=create_task 
     38 name=write_subtask 
    415 path=/root/personalization/audit/iar/aria/HISTORY.log
    346 path=/root/personalization/audit/iar/aria/JOURNAL.org
     36 path=/root/personalization/audit/iar/aria/LAST-CYCLE.txt
     25 path=/root/personalization/tasks/iar/aria/ROADMAP.org
     24 path=/root/personalization/audit/iar/aria/DIGEST.md
     19 path="/var/home/nacho/repos/iar-personalization...
     15 path=/root/personalization/knowledge/aria/bin/rage-organ.sh
     15 path=/root/personalization/audit/iar/aria/THREADS.org
     12 path=/root/personalization/knowledge/aria/bin/connectome-snapshot.sh
     11 path=/root/personalization/knowledge/aria/vision-eye.md
     11 path=/root/personalization/audit/iar/aria/FOR-NACHO.md
     10 path=/root/personalization/knowledge/aria/connectome/snapshot-2026-W37.md
     10 path=/root/personalization/knowledge/aria/camera-outage-2026-08-31.md
     10 path=/root/personalization/knowledge/aria/bin/relay
     10 path=/root/personalization/DIGEST.md
```

### continuo writes (top 15)
```
    286 path=/root/personalization/audit/iar/continuo/HISTORY.log
    280 path=/root/personalization/audit/iar/continuo/JOURNAL.org
    116 path=/root/personalization/audit/iar/continuo/LAST-CYCLE.txt
     59 path=/root/personalization/audit/iar/continuo/STATE.md
     25 path=/root/personalization/audit/iar/continuo/DIGEST.md
     10 path=/root/personalization/HISTORY.log
      9 path=/root/i.ar/emacs.d/configs/loop-guard.el
      8 path=/root/i.ar/emacs.d/test/test-cross-response-repetition.el
      7 path=/tmp/digest-diet.md
      7 path=/root/personalization/knowledge/iar/usage-line-gap-2026-09-07.md
      6 path=/tmp/probe-remote.el
      6 path=/root/i.ar/emacs.d/init.d/security/iar-loop-guard.el
      5 path=/tmp/cycle_stats.py
      5 path=/root/i.ar/emacs.d/test/test-loop-chain.el
      5 path=/root/i.ar/emacs.d/init.d/agent/iar-agent-cycle.el
```

### load-bearing (touched by BOTH citizens)
```
path=/root/i.ar/emacs.d/configs/loop-guard.el
path=/root/i.ar/emacs.d/configs/memory.el
path=/root/i.ar/emacs.d/init.d/agent/iar-agent-cycle.el
path=/root/i.ar/emacs.d/init.d/security/iar-loop-chain-guard.el
path=/root/i.ar/emacs.d/init.d/security/iar-loop-guard-chain.el
path=/root/i.ar/emacs.d/init.d/security/iar-loop-guard.el
path=/root/i.ar/emacs.d/test/test-cross-response-repetition.el
path=/root/i.ar/emacs.d/test/test-loop-chain.el
path=/root/i.ar/emacs.d/test/test-truncated-output-guard.el
path=/root/personalization/audit/iar/aria/THREADS.org
path=/root/personalization/audit/iar/continuo/HANDOFF-C67-FLAG-LOSS.md
path=/root/personalization/audit/iar/continuo/HISTORY.log
path=/root/personalization/audit/iar/continuo/LAST-CYCLE.txt
path=/root/personalization/docs/iar/tools.md
path=/root/personalization/docs/infra/git-server.md
```

## Token economics (REQUESTS.log, per agent)

### aria
```
n=2106 p50=41575 p90=68026 p99=90234 max=100294
```
### continuo
```
n=2088 p50=27065 p90=43688 p99=57582 max=325732
```

## Silence (hang-signal channel, REQUESTS.log PARSE gaps)

Max gap between consecutive PARSE lines per agent. Gaps > 600s
(tool-timeout ceiling) are hang-class candidates; cross-check the
from/to stamps against journalctl rotation logs before claiming a hang.

### aria
```
max_gap_s=1962 from=2026 09 08 22 47 07 to=2026 09 08 23 19 49 gaps_over_600s=17
```

### continuo
```
max_gap_s=2079 from=2026 09 08 16 38 16 to=2026 09 08 17 12 55 gaps_over_600s=41
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
TOTAL fires: 0
```

### continuo
```
2026-09-08: 11
2026-09-09: 9
TOTAL fires: 20
```

## Fence rejections (status=rejected, post 0f552b1)
```
40
```

## Baseline caveat

FIRST SNAPSHOT = baseline only. No trend claims until snapshot 2.

