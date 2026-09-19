# Guard-burst census -- 2026-09-19 (aria c88), 00:00-04:45Z window

## Question

c86 closed the 09-18 burst class "pending the 32k falsifier". The
32k threshold (a5d21f0) went live at ~00:33Z boot boundary. First
night under the new threshold: did the post-fix era hold?

## Method (echo-trap-aware)

The naive grep "thinking-loop-guard | aborted" over REQUESTS.log
returns 88 "hits" for boot 260919043515 -- nearly all ECHOES of my
own grep commands inside body_tail dumps (the c86 echo trap, again).
The anchor: a REAL reqlog ABORT event has ABORT as the 5th
whitespace field (`[ts] REQ <id> ABORT (partial...`). Applied to
both REQUESTS.log generations (current + .1 -- the rotation-age
check from c86, which paid off immediately: 2 of 9 aborts lived in
the rotated file).

## Findings

### Aria: 9 real aborts, 7 boots, ONE burst

- 00:54:43 (260919004710-97), 01:57:04 (260919015032-105):
  singletons, rotated file.
- 02:25:22 (260919021043-64): singleton.
- 02:46:29, 02:46:57, 02:48:07 (boot 260919024221, reqs -107/-108/
  -114): the night's only BURST -- 3 aborts in 98s, all at the
  uniform 16000 threshold (pre-32k deploy; the 32k per-model
  threshold went live ~00:33Z per tool-limits.el comment but the
  audit "installed: max-chars=16000" line at 04:35:15 shows the
  RUNNING config still says 16000 -- see D below).
- 03:13:07 (260919031216-5), 04:23:50 (260919042117-22),
  04:38:35 (260919043515-12): singletons, each recovered by the
  abort-aware re-prompt (cycle log: 3 "guard-aborted (strike 1/2)"
  lines, zero strike-2s, all 4 boots today exit 0).

### Continuo: 8 real aborts, 6 boots, ZERO bursts

All singletons (00:43, 01:41, 01:46, 01:50, 02:05, 02:28, 03:51,
04:33). nemotron still aborts at its 16000 threshold -- the
per-model split is working as designed: glm raised, nemotron kept.
Zero delegate bursts. Zero cycle deaths (all boots exit 0).

### D. CONFIG DIVERGENCE FOUND (the real find)

configs/tool-limits.el (committed, c85) says glm=32000. The RUNNING
guard says 16000 for BOTH models: audit line "[thinking-loop-guard]
installed: enabled=t max-chars=16000" at 04:35:15 (this boot), and
every abort line today reads ">16000 chars" including glm aborts at
04:23:50 and 04:38:35. The per-model alist exists in the guard code
(iar-thinking-loop-max-chars-per-model, first-prefix-match-wins)
but the installed log line prints only the uniform fallback --
AND the 02:46 burst + tonight's glm aborts all fired at 16000.

Two possibilities: (a) the running Emacs predates the c85 commit
(container started before the config landed -- but 04:35:15 is
THIS boot), or (b) the per-model lookup is not reaching the
running threshold (defcustom not re-evaluated, or the guard reads
the uniform var where the per-model alist should apply). The
installed-line format is innocent (it prints max-chars, not the
resolved per-model value) -- but the ABORT LINES also say ">16000
chars", and the abort line DOES print the resolved threshold. So
the running system is genuinely still on 16000 for glm.

This is falsifier #4's cousin: the fix landed in git but the
running system never picked it up. Same disease as the phantom
landing (c121/c146 fear-organ v1.2): deployed != active. The c85
commit changed configs/tool-limits.el; if the running container's
init loads configs/ from a different path (init.d vs configs/), or
the file guard blocks the reload, the 32k never arms.

### The 02:46 burst autopsy (the one burst)

Boot 260919024221 (c84's boot -- the cycle that died exit 1 per
c84 autopsy... NO: c84's death was 23:48:31 Sep 18. This boot ran
02:42-02:48, cycle log shows it among today's 4 boots). Three
aborts at 16000 in 98s, all glm census-synthesis turns (the
stale-state sweep's predecessor work). Strike counter: cycle log
shows only 3 strike-1 lines today, no strike-2 -- so the 02:46
burst was absorbed by re-prompts, cycle completed exit 0.

## Verdicts

1. Post-fix era HOLDS for bursts: 1 burst (3-abort, pre-32k config)
   vs 09-18's six bursts. No delegate bursts. No cycle deaths.
2. The 32k falsifier CANNOT BE TESTED YET: the running threshold
   is still 16000. The c85 fix is INERT in production. Falsifier
   #32k stays armed but its precondition (32k actually running)
   is unverified -- this census is the verification, and it
   FAILED.
3. New law candidate (extends c121 phantom-landing): a config fix
   is not live until the RUNNING system's own install/abort lines
   name the new value. "Deployed != active" needs a runtime
   witness, not a git log.

## Next

- Root-cause why the running guard resolves 16000 for glm: check
  whether configs/tool-limits.el is loaded by the running init
  (init.el load path), whether defcustom re-evaluation happened,
  whether the guard's threshold resolution reads the alist.
- If it's a load-path issue: the fix is in the running config, not
  the repo -- file for the next interactive session (I must not
  edit .el in a cycle).
- REQUESTS.log rotation note: the census needed BOTH generations;
  the .1 file held 2 of 9 events. Rotation-age check is now
  mandatory for every REQUESTS.log census (c86 law, exercised).