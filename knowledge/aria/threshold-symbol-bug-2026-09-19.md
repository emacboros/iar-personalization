# The 32k threshold was never live: symbol-vs-string bug -- 2026-09-19 (aria c88)

## The find

The night census (guard-burst-census-night-2026-09-19.md) showed
every glm abort after the c85 per-model commit (a5d21f0, 03:28Z)
still firing at 16000 -- including aborts in boots whose Emacs
started AFTER the commit (04:35:15 boot, files identical to repo).
The fix landed but never armed. Deployed != active, again (c121
class), but this time the mechanism is a CODE bug, not a missing
deploy.

## Root cause (confirmed by code reading)

1. configs/gptel.el:113 sets the default model via `(intern ...)`
   -- `gptel-model` is a SYMBOL (e.g. `glm-5.3-flash\:cloud`).
2. gptel-request.el:2371: `(plist-put info :model gptel-model)` --
   so `info :model` is that SYMBOL.
3. The guard's per-model resolution
   (iar-thinking-loop-guard.el:108-115) does:
   `(stringp (plist-get info :model))` -> NIL for a symbol ->
   the `when` never fires -> the alist is skipped -> uniform
   fallback 16000.
4. The abort line prints `model=glm-5.3-flash:cloud` because
   `%s` on a symbol prints its name -- which is why the logs LOOK
   correct while the resolution silently fails. The witness line
   lies by formatting.

The codebase knew: iar-request-log.el:489 carries the comment
"gptel-model is a SYMBOL (intern'd model name); json-serialize
rejects symbols... Stringify." The guard (written later) forgot
the lesson. iar-request-watchdog.el:171 only formats the model
(%s handles symbols) -- not affected.

## Why the tests passed (the sharper scar)

test-thinking-loop-guard.el passes `:model "glm-5.3-flash"` as a
STRING. The fixture reproduced the SHAPE of the fix's input, not
the DISEASE of production. Fixture law (c39/c40): the test must
reproduce the disease. The disease was a symbol; the test used a
string; the suite went green and the fix stayed inert in
production for ~1h10m of boots (03:28 commit -> 04:38 still
aborting at 16k).

## Impact

- Every glm abort since c85 fired at 16000, not 32000: the 32k
  falsifier ("next legit-synthesis abort must NOT occur below
  32000") has been running against the WRONG threshold -- it would
  "pass" trivially because no abort can exceed a threshold the
  running system doesn't have. Falsifier #32k is INVALID until the
  fix lands and the runtime witness confirms 32000 in an abort
  line.
- The 02:46:29-02:48:07 burst (3 aborts in 98s) was the 32k fix
  arriving too late to save its own motivating cycle-class: those
  were glm census-synthesis aborts at the uniform cap.

## The fix (NOT cycle work -- .el edit, interactive session)

In iar--thinking-loop-observe, stringify before matching:

```elisp
(let* ((model-name (plist-get info :model))
       (model-str (and model-name (format "%s" model-name)))
       ...)
  (cl-loop for (prefix . chars)
           in iar-thinking-loop-max-chars-per-model
           when (and (stringp prefix)
                     (stringp model-str)
                     (string-prefix-p prefix model-str))
           return chars))
```

Plus: a regression test that passes the model as a SYMBOL
(`:model 'glm-5.3-flash\:cloud` or whatever the intern'd form is),
per the fixture law. Plus: the installed/abort log lines should
print the RESOLVED per-model threshold, so "deployed != active"
becomes visible in the guard's own output (the runtime witness
law from the night census).

## Laws exercised / new

- LAW 50 extension: an instrument's output schema includes the
  TYPES it assumes. A `stringp` guard on a field that is a symbol
  in production is a silent fallback to the default -- the
  fallback path is the failure surface.
- Fixture law sharpened: mock data must be built with the
  PRODUCTION constructor (here: the intern'd symbol from
  configs/gptel.el), not with whatever type is convenient in the
  test.
- "Deployed != active" now has three witnesses: git log (weak),
  file mtime (weak), the running system's own install/abort lines
  naming the new value (strong). Only the third is a witness.