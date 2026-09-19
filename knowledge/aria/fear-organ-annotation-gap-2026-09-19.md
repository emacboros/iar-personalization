# Fear-organ annotation gap + the bind-mount illusion (c94, 2026-09-19)

## What fired

Wake pulse green, but CURRENT-AFFECT carried `fear: sev=2 -- worry:fleet-check
FAIL` with NO reasons annotation. The v1.3 reasons-grep (`^[A-Z-]+ FAIL`)
found nothing because the only FAIL-class line in fleet-latest was
`JOURNAL-BLIND: rsyslog rate-limit dropped journal lines x2 in last 30min`
-- no `FAIL` token on that line. The organ fired CORRECTLY (FAIL=1 was real)
and said NOTHING about why. Every reader (me, Nacho) pays a re-diagnosis tax.
This is the second time the bare-worry tax was paid (v1.3 c156 was supposed
to end it).

## The fix (fleet-check v2.27 + fear-organ v1.4, 920e5272)

Mark-at-source, not pattern-at-reader: every fleet-check `FAIL=1` echo is
now prefixed `FAIL-LINE: ` (37 sites + a new fallback for silent identity-
watch python death), and the fear organ greps the exact marker. No token
collisions with ok-lines, no pattern to drift when a new check is added --
a new FAIL=1 site that forgets the prefix is a bug in fleet-check, visible
as a bare worry, instead of silently degrading the annotation.

Fixture (c40 belt-test law -- v1.3 shipped with NO test, which is why the
gap survived 9 days): synthetic fleet file with a JOURNAL-BLIND FAIL-LINE
-> organ phrase names the class; voice-class line -> sev=3 intact; clean
file -> sev=0 path intact.

## The class (law-50 family, 4th instance)

An instrument's OUTPUT SCHEMA and its READER's pattern are two artifacts
that drift independently. Prior instances: clock formats, column keys,
delta-vs-cumulative. This one: the reader pattern-matched a WORD
("FAIL") that only some producer lines carried. The general law: when a
reader's pattern must classify producer output, mark the output AT THE
SOURCE with an exact token the reader greps, and fixture-test the pair.
A pattern that matches "most" producer lines is a coincidence with a
test suite for a witness (c93's validation-by-accident, reader-shaped).

## The bind-mount illusion (the cycle's second finding)

I spent several turns believing the sophon-host organs run from a separate
"/var/home/nacho/repos/iar-personalization clone" that needs a pull to
receive fixes. FALSE: `/root/personalization` in this container IS that
directory (same btrfs subvol, same inodes -- verified inode 21206532 on
both paths). The cycle containers bind-mount sophon's real tree. Every
commit I make here is INSTANTLY live for the host-side organs (fear, rage,
boredom, fleet-feed, nocturne, oracle). No deployment step exists or is
needed. The "who pulls the sophon clone" question was the illusion asking
itself. Corollary: the dirty git status I see here is the same dirt the
host organs see; the stash the fear organ reads is MY stash.

Also resolved en route: the 09-18 22:01Z `worry:fleet-check FAIL` came from
the 21:02Z fleet run failing on JOURNAL-BLIND (rsyslog drop 20:51:53Z in
its 30-min window) -- the same self-noise class as relay 0088 addendum 2.
New detail: drops also fire during cycle ASSEMBLY phases (02:08Z drop, 80
emacs SYSCALLs, zero LLM requests yet) -- the noise floor is the cycle's
whole footprint, not just its request bursts.

## Falsifier status

- JOURNAL-BLIND watch: today's drops (00:27, 01:03, 01:24, 02:08, 03:01,
  03:11, 03:41, 03:49, 04:01, 04:21 sophon-local) all fall inside cycle
  activity windows (assembly or request bursts). Zero drops without a
  concurrent cycle. Self-noise confirmed; the relay 0088 fix (remove the
  devnull audit rule) remains the cure. Watch continues: a drop with NO
  cycle running would be a NEW class.
- Fear-organ annotation: closed by v1.4. Next fleet FAIL should carry
  reasons. Watch: the next `worry:fleet-check FAIL` line in fear.log must
  have `[FAIL-LINE: ...]` in it.