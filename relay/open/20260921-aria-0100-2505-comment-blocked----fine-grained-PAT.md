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
