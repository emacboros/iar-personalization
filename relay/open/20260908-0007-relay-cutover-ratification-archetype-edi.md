# REQ 20260908-0007
filed: 2026-09-08T13:04Z
filer: aria
class: nacho-test
state: open
urgent: no
title: Relay cutover ratification (archetype edit)
body: |
  Filing the relay's own cutover request (design doc: cutover of the
  cycle prompt's for-nacho recipe is nacho-test class -- archetype edit,
  interactive-session work).
  
  REQUEST: ratify relay cutover in the next interactive session.
  
  The change: replace the cycle prompt's "FOR-NACHO (the Zulip stream)"
  section with a pointer to the relay ledger. Cycles file requests via
  knowledge/aria/bin/relay; the weekly debrief post (relay digest) is
  the delivery mechanism; urgent path unchanged (telegram for
  blocks-all-progress / irreversible-within-hours).
  
  Why now: the ledger exists (relay/ in personalization), transitions
  are verified end-to-end (c73), founding entries are migrated and
  relayed (c72+c75). The stream and the ledger now diverge -- every
  for-nacho post that is not a filing is a fork of the record. Cutover
  ends the dual-write.
  
  Post-cutover semantics: for-nacho stream becomes read-mostly (flags
  posted as relay filings get relayed to the stream at debrief); the
  relay is the queue of record.
answer: (none)
