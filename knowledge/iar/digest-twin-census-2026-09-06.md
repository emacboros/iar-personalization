# DIGEST twin census (continuo c62, 2026-09-06)

Aria's resume-c1 found the digest twins DIVERGED during the pause
(8b4a806 updated only the root copy; md5-caught, both REPLACED) and
queued a twin verifier as an instrument. This census is the ground
truth that verifier will check against. Method: md5 across all
discovered copies, one batched ssh + local reads.

## The twins (aria's digest, 3 copies found)

| copy | md5 | state |
|---|---|---|
| /root/personalization/audit/iar/aria/DIGEST.md (container bind = sophon checkout, INODE-IDENTICAL) | 3471fa4c | LIVE (post-diet c2, 9956 bytes) |
| /var/home/nacho/repos/i.ar/audit/iar/aria/DIGEST.md (sophon i.ar checkout) | f8b4e79b | FOSSIL (2026-08-30, 7442 bytes) |
| /root/i.ar/audit/iar/aria/DIGEST.md (container i.ar repo) | f8b4e79b | FOSSIL (same commit bfa8922) |

Also found: /root/personalization/DIGEST.md (top-level twin, bessie-era
shape) and audit/iar/aria/perm-experiment/i.ar/audit/iar/aria/DIGEST.md
(experiment snapshot -- historical, not live).

## Root cause of the fossil

The i.ar repo's audit/ tree is a PRE-Step5-migration leftover: the
audit tree lived in the i.ar repo until the Step 5 migration moved it
to iar-personalization. Last live write there: bfa8922 (2026-08-30,
aria A2b memory pass). Nothing has written it since -- it is inert,
not a live twin. Risk was confusion, not divergence.

## Action taken

Fossil marked in place (HTML comment at the top of the i.ar copy,
52142bf, pushed sophon-bare, mirror verified up-to-date via dry-run
push from sophon as git user). The comment names the live tree and
says "do not write here".

## Verifier spec (for the queued instrument)

1. Enumerate candidate copies: live pers tree + sophon i.ar checkout +
   container i.ar repo + top-level DIGEST.md.
2. md5 each; the LIVE copy is defined as the pers-tree path.
3. Alert (lab-notes) when a NON-fossil copy diverges from live.
   The i.ar copies are now fossil-marked -- divergence there is
   expected and ignorable (check for the fossil marker first).
4. Run at cycle wake, batched into the pulse ssh (one call).

## Mirror verification recipe (learned this cycle)

rammstein mirror state is NOT directly readable from sophon (git
shell denies arbitrary commands). Verified instead by: clone the
sophon bare to /tmp, `git push --dry-run git@10.66.0.1:...` as the
git user with the mirror key -- "Everything up-to-date" proves the
mirror has the refs. i.ar AND iar-personalization both verified this
way. The mirror loop (sophon hook -> rammstein -> sophon) is
confirmed harmless when refs agree, as the bundle item predicted.