# Connectome snapshot 2026-W37

Generated: 2026-09-08 23:25 UTC | window: 5 s | TOPN: 15

## Population

| source | tool_call lines |
|---|---|
| merged (both hosts) | 60240 |
| aria | 34017 |
| continuo | 18084 |

## Co-firing (top pairs, 5s window)

### aria
```
  25965 execute_code_local->execute_code_local
   1002 read_file->execute_code_local
    747 execute_code_local->read_file
    406 execute_code_local->append_file
    397 execute_code_local->read_roadmap
    368 append_file->execute_code_local
    353 append_file->append_file
    278 read_roadmap->read_task
    265 read_task->execute_code_local
    258 write_file->execute_code_local
    240 execute_code_local->write_file
    186 read_file->read_file
    133 read_knowledge->read_knowledge
    131 read_roadmap->execute_code_local
    126 write_roadmap->execute_code_local
```

### continuo
```
  12851 execute_code_local->execute_code_local
    712 read_file->execute_code_local
    481 execute_code_local->read_file
    282 execute_code_local->read_roadmap
    263 execute_code_local->append_file
    252 append_file->execute_code_local
    247 read_task->execute_code_local
    206 read_roadmap->read_task
    176 write_file->execute_code_local
    171 execute_code_local->write_file
    170 append_file->append_file
    103 git_commit->execute_code_local
     78 read_knowledge->execute_code_local
     78 execute_code_local->git_commit
     75 execute_code_local->read_knowledge
```

## N-gram motifs (2-grams, 3-grams)

### aria 2-grams
```
  13499 execute_code_local->execute_code_local
    531 read_file->execute_code_local
    462 execute_code_local->read_file
    216 execute_code_local->append_file
    210 execute_code_local->read_roadmap
    197 append_file->execute_code_local
    186 append_file->append_file
    151 read_roadmap->read_task
    129 execute_code_local->write_file
    127 read_task->execute_code_local
    126 write_file->execute_code_local
    115 read_file->read_file
     77 write_roadmap->execute_code_local
     74 read_roadmap->execute_code_local
     68 read_knowledge->read_knowledge
```
### aria 3-grams
```
   8370 execute_code_local->execute_code_local->execute_code_local
    321 read_file->execute_code_local->execute_code_local
    269 execute_code_local->read_file->execute_code_local
    212 execute_code_local->execute_code_local->read_file
    132 execute_code_local->execute_code_local->read_roadmap
    124 execute_code_local->execute_code_local->append_file
     92 append_file->execute_code_local->execute_code_local
     85 execute_code_local->write_file->execute_code_local
     82 execute_code_local->read_roadmap->read_task
     77 execute_code_local->append_file->append_file
     70 read_roadmap->read_task->execute_code_local
     62 read_task->execute_code_local->execute_code_local
     59 execute_code_local->execute_code_local->write_file
     53 execute_code_local->append_file->execute_code_local
     49 write_file->execute_code_local->execute_code_local
```
### continuo 2-grams
```
   6686 execute_code_local->execute_code_local
    370 read_file->execute_code_local
    359 execute_code_local->read_file
    152 execute_code_local->append_file
    144 execute_code_local->read_roadmap
    131 read_task->execute_code_local
    120 append_file->execute_code_local
    104 read_roadmap->read_task
     90 execute_code_local->write_file
     90 append_file->append_file
     88 write_file->execute_code_local
     53 git_commit->execute_code_local
     43 execute_code_local->git_commit
     42 read_knowledge->execute_code_local
     38 execute_code_local->read_knowledge
```
### continuo 3-grams
```
   3983 execute_code_local->execute_code_local->execute_code_local
    200 execute_code_local->read_file->execute_code_local
    186 read_file->execute_code_local->execute_code_local
    157 execute_code_local->execute_code_local->read_file
     95 execute_code_local->execute_code_local->read_roadmap
     84 execute_code_local->execute_code_local->append_file
     76 read_task->execute_code_local->execute_code_local
     70 execute_code_local->read_roadmap->read_task
     66 append_file->execute_code_local->execute_code_local
     51 execute_code_local->write_file->execute_code_local
     49 read_roadmap->read_task->execute_code_local
     46 read_file->execute_code_local->read_file
     45 append_file->append_file->execute_code_local
     43 execute_code_local->execute_code_local->write_file
     41 execute_code_local->append_file->append_file
```

## File-touch graph (write side; read side only post 2026-09-08)

### aria writes (top 15)
```
    966 name=append_file 
    363 name=write_file 
     94 name=git_commit 
     39 name=create_task 
     38 name=write_subtask 
    379 path=/root/personalization/audit/iar/aria/HISTORY.log
    308 path=/root/personalization/audit/iar/aria/JOURNAL.org
     19 path="/var/home/nacho/repos/iar-personalization...
     17 path=/root/personalization/tasks/iar/aria/ROADMAP.org
     16 path=/root/personalization/audit/iar/aria/DIGEST.md
     11 path=/root/personalization/knowledge/aria/vision-eye.md
     11 path=/root/personalization/audit/iar/aria/FOR-NACHO.md
     10 path=/root/personalization/knowledge/aria/camera-outage-2026-08-31.md
      9 path=/root/personalization/tasks/iar/ROADMAP.org
      9 path=/root/personalization/knowledge/aria/aevum-watch.md
      9 path=/root/personalization/audit/iar/aria/THREADS.org
      8 path="/var/home/nacho/repos/iar-personalizati...
      8 path=/root/personalization/knowledge/aria/bin/tool-census
      8 path=/root/personalization/DIGEST.md
      7 path=\"/var/home/nacho/repos/iar-perso...
```

### continuo writes (top 15)
```
    250 path=/root/personalization/audit/iar/continuo/HISTORY.log
    242 path=/root/personalization/audit/iar/continuo/JOURNAL.org
     70 path=/root/personalization/audit/iar/continuo/LAST-CYCLE.txt
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
      4 path=/root/personalization/tasks/iar/continuo/ROADMAP.org
```

### load-bearing (touched by BOTH citizens)
```
path=/root/i.ar/emacs.d/configs/loop-guard.el
path=/root/i.ar/emacs.d/configs/memory.el
path=/root/i.ar/emacs.d/init.d/agent/iar-agent-cycle.el
path=/root/i.ar/emacs.d/init.d/security/iar-loop-chain-guard.el
path=/root/i.ar/emacs.d/init.d/security/iar-loop-guard-chain.el
path=/root/i.ar/emacs.d/init.d/security/iar-loop-guard.el
path=/root/i.ar/emacs.d/test/test-loop-chain.el
path=/root/i.ar/emacs.d/test/test-truncated-output-guard.el
path=/root/personalization/audit/iar/aria/THREADS.org
path=/root/personalization/audit/iar/continuo/HANDOFF-C67-FLAG-LOSS.md
path=/root/personalization/audit/iar/continuo/HISTORY.log
path=/root/personalization/audit/iar/continuo/LAST-CYCLE.txt
path=/root/personalization/docs/iar/tools.md
path=/root/personalization/docs/infra/git-server.md
path=/root/personalization/knowledge/aria/agora-valence-v1-notes.md
```

## Token economics (REQUESTS.log, per agent)

### aria
```
n=2161 p50=42795 p90=66978 p99=89924 max=99039
```
### continuo
```
n=2890 p50=29377 p90=50050 p99=74319 max=85630
```

## Fence rejections (status=rejected, post 0f552b1)
```
2
```

## Baseline caveat

FIRST SNAPSHOT = baseline only. No trend claims until snapshot 2.

