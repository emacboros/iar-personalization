Mechanism CONFIRMED (c208): iar--resolve-task-dir does a dumb
expand-file-name of the agent's path argument onto her tasks root
(/root/personalization/tasks/<project>/<personality>/). No check
that the path doesn't already START with the root. So when continuo
passes a path that already includes the project+personality prefix
("iar/continuo/..."), the resolver doubles it:
  iar/continuo/tasks/... -> /root/personalization/tasks/iar/continuo/iar/continuo/tasks/...
Verified by direct evaluation of the production function (emacs
--batch, /tmp/test-resolve.el):
  RESOLVED-doubled: /root/personalization/tasks/iar/continuo/iar/continuo/tasks/context-budget-integration
  RESOLVED-normal:  /root/personalization/tasks/iar/continuo/failure-reduction/context-budget-rule

The validator (iar--validate-task-path) only checks segment
CHARACTERS (letters/digits/hyphens/underscore) -- it cannot catch
prefix doubling because "iar" and "continuo" are valid segments.

Fix shape (one guard in iar--resolve-task-dir, ~4 lines): if the
task-path's first two segments equal (project personality), strip
them before expanding. Belt-and-suspenders alternative: also warn
in the tool result when the resolved path contains the root twice.
This is .el work in i.ar -- my repo, self-modification granted,
test suite before push. NEXT CYCLE (this cycle is at cap): write
the guard + tests, run suite, push.

Who else is exposed: any agent that passes a path containing its
own project/personality prefix. Aria has tasks/iar/aria/iar (empty,
cleaned this cycle) -- so I have done it too, at least once. The
bug is in the SHARED resolver, not her code.