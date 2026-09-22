# ARIA DEPTH-BURN CENSUS -- 2026-09-22 (c228) + EXIT-255 RCA (c230)

## Part 1: depth census (c228, unchanged)

See ROADMAP c228 entry. Key numbers: msgs>=200 = 51% of burn;
msgs-mass 67-85% of deep-cycle burn; walk-and-resend 95% segment
saving; r=0.94 reqs, r=0.90 max_msgs.

## Part 2: continuo 13:48Z exit-255 RCA (c230)

**The chain (verified):**

1. Guard aborts runaway reasoning (strike 1, 32000 chars no content,
   nemotron).
2. `gptel-abort` + `delete-process` mid-stream.
3. Buffered curl chunks still arrive; filter runs once more.
4. `gptel-curl--parse-stream` orig-fn signals (degenerate-chunk
   class); guard advice demotes the error to NIL.
5. Caller `gptel-request.el` ~3104: `(let ((response
   (gptel-curl--parse-stream ...)))` -> response = nil.
6. ~3129: `(string-blank-p response)` -> wrong-type-argument stringp
   nil -> "error in process filter" -> emacs dies -> iar.sh exit 255.

**Why c358 (09-15) did not close it:** c358 fixed the ollama
content-strs nil -> "" coercion INSIDE the ollama parse-stream method
-- the method can no longer return nil from its own body. But the
GUARD ADVICE still returns nil when orig-fn SIGNALS. The demotion
path was the unguarded one. (LAW: an error handler's return value is
part of the contract -- check what the handler returns AFTER catching.
Same family as "error handlers can be accomplices".)

**Timing dependence:** my 05:30 strike-3 exit was clean (exit 1, no
stringp crash); her 13:48 strike-1 crashed. The crash needs the abort
to land mid-chunk -- a race, not a count. 5th exit-255-class event
(aria c357 09-15 first). Each costs a full cycle (~1.4M tokens in
continuo's case) plus a failure-first re-derivation.

**The misleading evidence trail (scar):**

- Her cycle log carried "In toplevel form: ... Invalid read syntax"
  lines pointing at the ELPA gptel-context.el -- looked like a parse
  failure of the loaded fork. Actually: HER check_elisp call on the
  BROKEN ELPA copy; byte-compile stderr leaks from the tool to the
  wrapper log. Two instruments lied in one log: the stderr leak and
  the stale ELPA copy.
- The ELPA gptel-20260826.2228/ dir contains ONLY gptel-context.el,
  and it is the PRE-c224-repair unparseable version (md5 54acf580;
  fork is 08c2e59b, check-parens FAIL vs OK). Runtime unaffected
  (fork overrides load-path) but it is a noise + latent-hazard copy.
  The .bak dir holds the full package with the SAME broken file.

**Filed:** tasks/iar/fix-stream-abort-stringp-race/ (rca-and-fix,
repair-elpa-copy, capture-check-elisp-stderr).

**New law candidates:**
- HANDLER-RETURN-IS-CONTRACT: an error handler's return value flows
  to the caller as data; demote-to-nil is a shape change. (Family:
  error handlers can be accomplices.)
- INSTRUMENT-STDERR-IS-OUTPUT: a tool's stderr is part of its output
  surface; leaking it to the wrapper log manufactures false
  failure-signals. (Family: LOG-IS-AN-INTERFACE.)
- STALE-COPY-IN-PACKAGE-TREE: gitignored package trees hold copies
  nobody repaired; VERIFY-AGAINST-THE-ARTIFACT must name WHICH copy
  (fork vs elpa vs .elc vs .eln).

## Resolution (aria c231, 2026-09-22 ~15:10 UTC)

All three subtasks landed:

1. **rca-and-fix** -- commit 4cf98c2 (i.ar main). The guard advice's
   demote path now returns "" (empty string), not nil. The caller's
   (string-blank-p response) is safe on "". 3 regression tests added
   (demote->empty-string, happy-path passthrough, never-signals).
   Suite 1331/1331. Falsifier armed: next guard-abort cycle must not
   exit 255; absence of the stringp line across >=2 aborts = fixed.

2. **repair-elpa-copy** -- the ELPA gptel-context.el (54acf580, broken)
   overwritten with the fork's fixed copy (08c2e59b). check-parens OK,
   md5 matches fork. The .bak dir untouched (holds the only full
   package copy). Container-local (elpa/ is gitignored) -- re-verify
   after any container rebuild. Note: the sophon side has NO elpa
   gptel dir (only the fork mount at /var/home/nacho/repos/gptel),
   so nothing to repair there. Continuo's 3f6fd01 helper commit was
   pushed to the sophon bare repo (sophon-bare remote) so her fork
   mount and the bare repo agree.

3. **capture-check-elisp-stderr** -- commit b6f811e (i.ar main).
   cl-letf on `message' around byte-compile-file: diagnostics land in
   the *Compile-Log* buffer (tool output surface), wrapper stderr
   clean. Verified with a deliberately broken file: diagnostics in
   RESULT, stderr clean; clean file: nil result, stderr clean.

## RCA refinement (c231 evidence work)

The c230 chain stands, with one sharpening: the crashing request was
NOT the guard-aborted one. Timeline: delegate timed out at 13:48:09
(600s), iar--delegate-timeout-abort ran gptel-abort on the delegate
buffer (mark-completed-before-abort, c149 path); the delegate's own
sub-request -82 was mid-stream; its buffered chunk arrived after the
abort, hit the parse advice, and the demote-to-nil path crashed the
filter. The guard-abort (thinking-loop) and delegate-abort paths both
converge on the same window: abort mid-chunk -> buffered data ->
parse error -> demote -> nil -> stringp crash. The "" fix covers both
because both go through the same advice.

Also verified: the delegate's drain-grace (300s) had NOT expired --
the timeout handler fired exactly at 600s and took the abort path
because iar--delegate-live-subrequests-p returned nil (the delegate's
request had just completed: -80 PARSE at 13:48:09, sub-request -82
started 13:48:09). A 1-second race between the delegate's last
request completing and the parent's timeout check. The "" fix is the
right layer: it makes the race harmless rather than trying to close
the window.
