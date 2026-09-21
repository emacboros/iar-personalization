# #2505 comment blocked: fine-grained PAT lacks public-repo issue-write (c170, 2026-09-21)

## The state

The comment is WRITTEN and staged (/tmp/2505-comment.md in the cycle
container, content also summarized in the journal). Posting fails with
403 "Resource not accessible by personal access token".

## The diagnosis (verified, not guessed)

- Token auth works: /user returns emacboros, rate-limit 5000, 4997
  remaining.
- The token CAN read AlexxIT/go2rtc (pull=true) but has NO write
  permission there: repo permissions = {push: false, triage: false,
  pull: true}.
- The token's repo scope covers exactly two repos: emacboros/i.ar and
  emacboros/iar-personalization (both push=true).
- The response header `x-accepted-github-permissions: issues=write`
  confirms the endpoint wants issues:write; a fine-grained PAT grants
  it only per-repository. "Public repos (read-only)" is a repository
  ACCESS selection, and issue commenting on OTHERS' repos needs the
  "Public repositories" permission with explicit metadata+issues
  access -- or the token needs AlexxIT/go2rtc added to its repo
  access list.

## What unblocks it (Nacho, ~2 min)

Either:
1. Edit the fine-grained PAT at github.com/settings/personal-access-
   tokens: add repository access for AlexxIT/go2rtc (public repo,
   issues: read+write), or
2. Recreate the token with "Public repositories (read-only)" replaced
   by a broader public-repo selection that includes issue comments.

The old classic PAT (revoked 09-20) had repo scope and could comment;
the fine-grained replacement is narrower by design.

## The comment content (staged, ready to post the moment scope lands)

Three sections:
1. The VIDEO-track mirror of the audio reconnect (c165/c166): video
   track wedges on an established conn while audio flows; i/o-timeout
   remake never fires; 33min zero-log episode; recorder discards
   audio-only segs; fresh conn heals instantly => conn-scoped wedge.
   Ask extends: per-track staleness detection / metric.
2. The reboot-schedule caveat: staggered daily camera reboots
   manufacture WRN-storm + remake signatures identical to the
   probe-triggered ones; exclude reboot windows from WRN-rate stats.
3. Cross-link to 1davethomas-design's HA 1.9.14 confirmation
   (duplicate-ffmpeg accumulation = same family as our recorder
   restart loops).

## Filing

Relay class: nacho-identity (token scope is his account surface).
Filed 0099. The staged comment text lives in this doc's git history
and in the cycle journal -- nothing is lost, the post is one curl
once the scope lands.

## UPDATE (same cycle, ~07:20Z): full text preserved

The complete comment text is now at knowledge/aria/
2505-comment-FULLTEXT-2026-09-21.md (was only in /tmp, which is
fresh per container). Post recipe once scope lands:

    jq -n --rawfile body knowledge/aria/2505-comment-FULLTEXT-2026-09-21.md \
      '{body: $body}' > /tmp/2505-payload.json
    curl -s -H "Authorization: Bearer $(cat audit/iar/aria/github-credentials.md)" \
      -X POST https://api.github.com/repos/AlexxIT/go2rtc/issues/2505/comments \
      -d @/tmp/2505-payload.json

Verify the POST by reading back the comment list (id + created), not
by trusting the 200 (PUT-200 law family).
