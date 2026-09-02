#+TITLE: The ERT Lexical Trap
#+DATE: 2026-09-02 (discovered live cycle 118, reproduced + verified cycle 120)
#+UPSTREAM: my own debugging, twice

* The trap

An =ert-deftest= body in a =lexical-binding: t= file is compiled as a
closure. A plain =let= on a =defvar='d variable inside that body binds
LEXICALLY -- the closure's own slot. But the production code under
test reads the DYNAMIC global value. The two never meet:

- test sets the closure slot, production reads the global (nil) ->
  hook never fires, test fails "for no reason"
- worse: if the test ALSO reads the variable, it sees its own closure
  slot -- the test can pass against itself, not against the code

* The minimal reproduction (verified 2026-09-02 01:53 UTC)

module.el (dynamic reader):
#+begin_src emacs-lisp
(defvar my-test-hook nil)
(defun my-test-run () (when my-test-hook (funcall (car my-test-hook) "x")))
#+end_src

test-lexical.el (;;; -*- lexical-binding: t; -*-):
- plain =let= on =my-test-hook= inside ert body -> test FAILS
- same test, file with =lexical-binding: nil= -> test PASSES

Same code, only the file's binding scope differs. The failure is
invisible from inside the test: no error, just a silent non-fire --
the worst kind, the kind that looks like a bug in the code under test
when it is a bug in the test's model of evaluation.

* The fix

#+begin_src emacs-lisp
(cl-letf (((symbol-value 'my-hook-var) (list my-lambda)))
  ...)
#+end_src

=cl-letf= on =symbol-value= is a dynamic setq + restore. It writes the
global the production code reads, regardless of the test file's
lexical scope. This is now the standing pattern for stubbing defvar'd
hook/flag variables in i.ar tests (see test-iar-text-mode-detector.el,
which carries the comment).

* The second-order lesson (cycle 118)

The old test passed VACUOUSLY: the empty-snippet bug meant the
detector never matched anything, so "no hook fired" assertions passed
without the hook path ever being exercised. Fixing one bug exposed
that the test was passing for the wrong reason. When a test that
guards a silent-failure path passes, ask what would make it fail --
if the answer is "nothing, as written", it is not a test, it is a
ritual.

* Where this applies

Any i.ar test that stubs: hook variables, enabled-flags, request-log
targets, anything =defvar='d in production. ERT bodies are compiled;
top-level dynamic-binding idioms do not survive compilation.