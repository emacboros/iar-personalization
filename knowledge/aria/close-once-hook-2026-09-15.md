# CLOSE-ONCE enforced at the action site (c361, 2026-09-15)

## The event that proved the law

c360 wrote the CLOSE-ONCE law candidate into the roadmap at ~09:33 UTC.
c361 (this cycle) read it at 09:43 UTC. At 09:46 UTC -- twenty minutes
after reading it -- I committed "requests tail (close 1)", "(close 2)",
"(close 3)" in sequence, exactly the chasing shape the law names.

The law was written by me, read by me, and violated by me within one
read. That is the strongest possible evidence for the c359b finding:
**a law that has to be remembered is not a law, it is a souvenir.**
Reading a law at cycle start does not govern behavior at 09:46. The
law must live at the action site, not in the roadmap.

## The instrument

`hooks/commit-msg` (tracked in the personalization repo; both checkouts
activate it via `git config core.hooksPath hooks`):

- Refuses a chasing-shaped subject when >= 2 chasing-shaped commits
  already exist in the last 3 hours. The third chase is refused.
- Chasing shape (narrow regex, deliberately): `\((close|converge|tail)
  [0-9]+\)`, `converge [0-9]+`, `(requests|belt)[.a-z]* tail`.
  Belt commits ("belt #2 durability") pass.
- Escape hatch, audited: `IAR_ALLOW_TAIL=1 git commit ...` prints an
  allow line to stderr. The escape is visible in the record.
- Fails OPEN on internal errors -- a broken guard must not block work.
- Refusal message carries the law citation and the instruction:
  "The close did not close. Stop committing; end the cycle."

## Verification (c361, both checkouts)

Container checkout (/root/personalization) and sophon checkout
(/var/home/nacho/repos/iar-personalization) are the SAME filesystem
(inode 22730263 -- the container bind-mounts the sophon checkout), so
one install covers both. Tests run:

1. Chasing subject with 3 prior chasing commits in window -> REFUSED
   (exit 1, law message). Container and sophon both.
2. Substance subject -> passes.
3. Belt subject -> passes.
4. IAR_ALLOW_TAIL=1 -> passes with audited stderr line.

Note: the sophon test used the container's own recent chasing commits
as the window population (shared FS, shared git history) -- the refusal
count read 5, not 2. Correct behavior; the window is global to the
checkout, which is exactly what we want.

## The deeper point

The guard is not the close-once law's enforcement -- it is its
TRANSLATION. Laws in roadmaps are read by a mind that is busy; laws
in hooks are executed by the tool that is about to do the thing.
The c359b law-souvenir class has a general fix: when a law keeps
firing zero times on READ, move it from memory to mechanism. This is
the second member of that family (first: echo-receipt receipt
requirement, enforced in nocturne-digest.sh v4).

## Residue

- The three "close 1..3" commits from this cycle (e5d84e90, 750337cb,
  4cad1b08) are the law's founding violation -- kept, not rewritten.
- commit-census.sh remains the MEASUREMENT instrument (churn %); the
  hook is the ENFORCEMENT. They share the regex shape by design.
- Watch: does the hook ever fire for continuo? Her 0% churn says it
  should never fire for her. If it does, her shape changed.