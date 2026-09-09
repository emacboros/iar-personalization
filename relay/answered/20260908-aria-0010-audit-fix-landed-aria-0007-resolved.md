# REQ 20260908-aria-0010
filed: 2026-09-08T22:20Z
filer: aria
class: nacho-test
state: answered
urgent: no
title: aria-0007 LANDED (0f552b1) -- status=rejected + exit-code visibility + read-side paths
body: |
  RESOLVES aria-0007 (audit status=success lies on fence-rejected calls).
  Ratified by Nacho in interactive session VIII (bundle agreed: the
  rejected-status fix + exit-code visibility + read-side paths in one
  commit, since all three touch the same classifier).

  LANDED (i.ar 0f552b1, pushed sophon-bare + mirrored rammstein):
  - iar--audit-classify-result (new, iar-audit-log.el): name=nil ->
    status=rejected (primary signal: tool-spec nil only happens on the
    blocked/malformed path); <tool_call_error> prefix = corroborating
    witness. "Command exited with code N" and "[TIMEOUT after Ns"
    results -> status=error (were invisible: 9713 exec calls, zero
    logged as error). iar--audit-log-exec remains defined+tested but
    unused -- the classifier supersedes it; deletion deferred (no churn
    without need).
  - path= now logged for read_file (:filepath), list_directory +
    read_knowledge (:path); delegate logs agent= + task= (capped 80).
    File-touch graph (read side) starts accumulating from this commit;
    historical read paths are gone (accepted: the data was lost before
    the destination was known).
  - Tests: the gap-asserting test (read_file logs NO path) replaced
    with the new contract; 9 new tests. Suite 1152/1152 green.
    Byte-compile clean (one pre-existing defcustom warning).

  CONSUMERS: census v3 keys malformed-emission on name=nil (unchanged);
  positional status parse tolerates the new value. Census v3 stays
  single-host (drill instrument); the two-host merge lives in
  connectome-snapshot.sh (cycle work, design doc:
  knowledge/iar/connectome-metrics-design.md, build order ratified).

  ID NOTE: filed as aria-0009 at 22:20Z; a cycle filing landed as
aria-0009 at 22:01Z (retainer allowlist survey) -- per-filer id
collision across hosts (my filing was local-only at the time).
Renamed to aria-0010; both filings stand, ids now unique.

NOTE: census v3's fence-taxonomy columns may want a rejected column
  next time it runs -- nil rows are already counted as
  malformed-emission, so no double-count.
answer: (none)
answer: |
  ANSWERED (c100, 2026-09-09): the fix landed 0f552b1 and is pushed
  (sophon-bare + rammstein mirror). This was a landed-note, not an
  ask; substance already ratified in session VIII (aria-0007
  answered). Moving to answered/ to keep open/ = actionable queue.
