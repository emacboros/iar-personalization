# Continuo STATE.md -- updated cycle 26 (2026-09-03 21:27 UTC)

## In flight
- Lab-notes post for c26 DEFERRED (soft cap 120 hit at post time;
  memory-tools exemption active). FIRST ACTION next cycle: post
  the c26 close via /tmp/agora_post.sh recipe (rebuild helper:
  curl -u AUTH --data-urlencode to=lab-notes topic=cycle). Text
  is in JOURNAL c26 entry tail / burn-decomposition file.
- Commit pending: knowledge/iar/burn-decomposition-2026-09-03.md
  + this cycle's record writes. Commit at kill-emacs if cap
  allows (git_commit is exempt).

## This cycle (c26)
- Burn decomposition from primary evidence. Instruments agree
  (132 == 132). Floor 12.4k, ~325 tok/round-trip, growth ~74%
  of burn. Cadence price ~250M tok/day. Tool-cap 120 pressed by
  healthy cycles (6/20 continuo >100) -- calibration datum for
  Nacho. REQ-id duplicates = cycle-boundary artifacts (debunked,
  census law). Token double-count CLEAN (live probe).

## Next
1. Post deferred lab-notes close (above).
2. Interactive bundle with Nacho: rotate.sh /tmp-copy, exit-126
   law, git-as-nacho, floor trim leftovers, mirror push, bare-repo
   trio (306). NEW: tool-cap calibration + cadence price.
3. Zulip backup gap: Nacho's call.

## Standing
- sophon ssh root@10.66.0.5 works (nacho@/git@ blocked). KH reseed
  per cycle. Suite: IAR_ROOT=/root/i.ar emacs --batch -l
  emacs.d/test/run-tests.el (1013 tests).
- Agora auth: EMAIL form, API /api/v1/messages, anchor=newest +
  jq filter, FORM-ENCODED. Streams: with-nacho=6 for-nacho=5
  lab-notes=4.
- iar--reqlog-counter restarts per session; REQUESTS.log spans
  cycles -- segment censuses by msgs=2 floor marker.