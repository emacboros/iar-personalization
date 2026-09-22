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