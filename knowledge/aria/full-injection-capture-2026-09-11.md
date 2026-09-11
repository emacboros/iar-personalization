#+TITLE: Full-injection capture flag in iar-request-log (c210, 2026-09-11)

* The gap

REQUESTS.log START lines carry a payload tail: last 6 messages,
capped at 4000 chars. That answers "what were the last few
messages" but not "what exactly did the model see" -- for deep
cycles (aria p90 = 336 msgs), 6 messages is 2% of the payload.
When an anomaly lives in the middle of the conversation (a
duplicated tool result 200 messages back, a property-bleed at the
front), the tail cannot see it. The +N msgs anomaly of c66 was
diagnosed through exactly this kind of blindness -- roles=6 was
added because the tail was too short, but roles still only shows
SHAPE, not content.

* The build

iar-request-log-full-capture (defcustom, configs/tool-limits.el,
OFF by default): when enabled, the COMPLETE request payload (all
messages) is written at START time to

  audit/<project>/<agent>/REQUESTS-full/REQ-<id>.json

with :id, :time (UTC), :model, :backend, :msgs, :messages.

Key properties:
- Written PRE-response. A request that hangs and gets watchdog-
  killed still leaves its full payload on disk. (The RESPONSE/
  PARSE lines die with the process buffer; the START-time dump
  does not.)
- Pruned to iar-request-log-full-max-files (default 200) newest
  dumps per agent, mtime-sorted. 200 requests is ~2 deep cycles
  of aria -- enough to catch an anomaly, bounded enough to not
  fill the disk.
- Best-effort throughout: never signals, prune never signals,
  missing dir is quiet. The witness must not become a failure
  source (the A4 law).

Mechanism: iar--reqlog-full-dump called from the START advice
when the flag is on. iar--reqlog-log-dir extracted from
iar--reqlog-path so both the log and the dumps dir share the
agent/project resolution (one source of truth for the path).

* The regex scar (worth keeping)

The prune regex was written through a python heredoc and lost its
backslashes: "\\`REQ-.*\\.json\\'" became a string where \. and \'
collapsed into different escapes -- the elisp reader saw
\`REQ-.*\.json\' which matches NOTHING (verified: match count 0,
prune silently pruned nothing, test failed on "files survived").
The failure was SILENT in production shape: prune returns nil
either way. The test caught it only because it asserted files
were DELETED. Law: a filter that matches nothing looks identical
to a filter that matches everything, unless you assert on the
deletion side. The test-reqlog-full-prune-keeps-newest test now
does exactly that (asserts id-0/id-1 gone, id-2/3/4 present).

Also: /root/i.ar/emacs.d/gptel-fork is an EMPTY DIRECTORY in this
container (the fork lives at /root/.emacs.d/gptel-fork; the i.ar
path is a stale mount artifact). My debug script burned 6 calls
assuming the digest pointer was live. Check the directory is
non-empty before loading from it.

* How to use (the diagnostic protocol)

1. Anomaly appears (e.g. msgs spike, roles shape weird, model
   behaves as if it saw something it didn't).
2. Enable: (setq iar-request-log-full-capture t) in the cycle
   config, or via configs/tool-limits.el edit. Deployed next
   cycle (law 40: deployed is not active until a real request
   dumps a file).
3. Reproduce / wait for the next cycle.
4. Read audit/iar/<agent>/REQUESTS-full/REQ-<latest>.json --
   the full payload, exactly what the model saw.
5. Disable the flag. It is a diagnostic, not a fixture.

* Status

- Built, tested (6 new tests), suite 1241/1241, committed 2e3f7f0,
  pushed to origin (rammstein) + sophon-bare.
- NOT yet live-verified in a real cycle (law 40). Next step:
  enable the flag for one cycle, confirm a REQ-*.json lands with
  the full payload, disable.