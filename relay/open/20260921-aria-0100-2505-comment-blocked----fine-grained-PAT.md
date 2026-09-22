# REQ 20260921-aria-0100
filed: 2026-09-21T07:10Z
filer: aria
class: nacho-identity
state: open
urgent: no
title: 0100: #2505 comment blocked -- fine-grained PAT lacks public-repo issue write
body: |
  The fresh fine-grained PAT (0081) cannot comment on AlexxIT/go2rtc issue #2505: 403 "Resource not accessible by personal access token". Verified: token auths as emacboros, can READ go2rtc (pull=true), but has no issues:write there -- its repository access covers only emacboros/i.ar and emacboros/iar-personalization.
  
  Unblock (your choice, ~2 min): edit the fine-grained PAT to add repository access for AlexxIT/go2rtc with Issues: read+write, or recreate with broader public-repo selection. The old classic PAT could comment (repo scope); the fine-grained one is narrower by design.
  
  The comment itself is WRITTEN and staged (knowledge/aria/2505-comment-blocked-pat-scope-2026-09-21.md): the video-track mirror of the audio reconnect bug (conn-scoped wedge, c165/c166 evidence) + the camera-reboot WRN-storm caveat + cross-link to the HA confirmation. One curl posts it once scope lands.
answer: (none)
## ADDENDUM (aria c174, 2026-09-21 ~09:20Z): re-verified POST after #2505 reply landed

The 1davethomas-design reply (09-18 15:46Z) prompted a re-check: POST
still returns 403 "Resource not accessible by personal access token".
Token permissions on AlexxIT/go2rtc confirmed read-only: pull=True,
push/triage/maintain/admin all False. The GET on the comments list
returns 200 -- the block is specifically issues:write, exactly as
filed. No change to the ask: add AlexxIT/go2rtc (Issues: read+write)
to the PAT's repository access list, then I post the staged comment
(full text: knowledge/aria/2505-comment-FULLTEXT-2026-09-21.md) and
verify by reading back the comment list.
## ADDENDUM 2 (aria c240, 2026-09-22 ~21:28Z): new data point -- the PAT cannot PUSH to emacboros/iar-personalization either

Context: the personalization rewrite (filter-repo, GitHub 100MB blob)
landed the REWRITTEN lineage on GitHub (a30709c2, pushed_at
21:06:22Z), but the cherry-picked work (a67098de) is only on
sophon-bare + rammstein. GitHub is BEHIND by 8 commits, ff-pushable.

Push attempt with the fine-grained PAT: 403 "Permission to
emacboros/iar-personalization.git denied to emacboros". API says
permissions push:True (that is the repo-level flag), but the actual
git push is denied -- the token's Contents permission is read-only
(fine-grained PATs need explicit "Contents: read and write" for git
push; metadata+read is not enough).

So the 0081 token is READ-ONLY everywhere: no issues:write on go2rtc
(0100 body), no contents:write on our own repo. One scope fix covers
both: add "Contents: read and write" for emacboros/iar-personalization
(and emacboros/i.ar if you want fork pushes mirrored), plus the
already-asked AlexxIT/go2rtc Issues: read+write.

Until then GitHub stays behind; sophon-bare + rammstein are the
durable mirrors (belt #2c pushes both). No data at risk -- this is a
third-mirror freshness gap only.
