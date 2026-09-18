# REQ 20260918-aria-0081
filed: 2026-09-18T00:53Z
filer: aria
class: nacho-security
state: open
urgent: no
title: LIVE GitHub PAT leaked into git history -- revoke + rotate NOW
body: |
  LIVE GitHub PAT leaked into git history + working copies. Rotation by
  you is the ONLY real fix. Details:
  
  WHAT: the classic PAT for emacboros (all scopes: repo, admin:*,
  delete_repo, workflow, copilot) was pasted by you in the 09-17
  interactive session at 19:42Z. The request-audit log (REQUESTS.log,
  which records full request/response bodies) captured it. The
  credentials file itself was correctly gitignored and never committed,
  but the LOG capture propagated:
  
  - sophon bare + rammstein bare: git history. Entered at 187c4fa6
    (2026-09-17 19:46Z, "requests log: session sync"). Still in HEAD's
    audit/iar/aria/REQUESTS.log. 20 commits touch the file since entry.
  - working copies (sophon + this container): scrubbed to REDACTED
    placeholders tonight (the live audit stream re-poisons them as I
    work; final scrub at cycle close).
  - GitHub mirrors (emacboros/i.ar, emacboros/iar-personalization):
    last pushed 2026-07-15/07-23, BEFORE the token existed = CLEAN.
    Leak commit verified NOT on GitHub.
  - randazzo-ignacio/iar-prod (private, collaborator access): token can
    read/write it; no leak there.
  - token is LIVE (verified 200 on /user). Account surface: 2 public
    repos, 1 private collab, 1 SSH key (aria), no orgs.
  
  WHAT I DID: scrubbed both working copies (partial; treadmill noted),
  verified bare history + mirror cleanliness, confirmed no OTHER live
  secrets in history (checked ghp_/github_pat_/AKIA patterns; the AKIA
  hits are the exposure-review doc discussing the pattern, not keys).
  
  ASK (nacho-security):
  1. REVOKE the current emacboros PAT and issue a fresh one (fine-grained,
     public_repo only if possible). Deliver the new one the same way but
     consider: the paste-into-session channel is what leaked it. A
     file-drop on sophon (e.g. /var/home/nacho/repos/iar-personalization/
     audit/iar/aria/github-credentials.md, chmod 600, gitignored) avoids
     the request-log capture entirely. The old file is NOT on sophon --
     it lived only in the yoga session.
  2. RATIFY history purge (filter-repo on both bares + working copies)
     -- destructive on shared history, so your call. Even after purge,
     assume the token is burned once revoked; purge is hygiene, not fix.
  3. STRUCTURAL (ours to build, your ratify): redact secret-shaped
     strings at the request-log layer before write. I can draft the
     patch next cycle.
  
  URGENT rationale: token is live, all-scope, and sits in git history on
  two hosts. Exfiltration window exists until revoked. Telegram sent.
answer: (none)
