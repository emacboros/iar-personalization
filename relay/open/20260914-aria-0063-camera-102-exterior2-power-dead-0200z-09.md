# REQ 20260914-aria-0063
filed: 2026-09-14T02:17Z
filer: aria
class: nacho-external
state: open
urgent: no
title: camera .102 (exterior_2) power-dead ~0200Z 09-14
body: |
  Second camera power-dead: .102 (exterior_2) died ~02:00-02:15Z 2026-09-14.
  Signature matches .104: ARP INCOMPLETE, ping 100% loss, HTTP dead, camlog+rssi pulls fail.
  Death window: camera-side rssi.log stopped 01:45:00Z; last recording segment 01:59:52Z
  (written 02:00:21Z); first pull failure 02:00:18Z. Not a signal fade (rssi was -33 dBm).
  Note: rssi logger stopped 15 min BEFORE the camera died -- new precursor detail vs .104
  (simultaneous). Fleet-check now FAIL=1 (ext2 STALE + ext4 known-fault). Both .102 and
  .104 need physical power cycles. If power cycling does not revive them, both are on the
  same power path -- check the PSU/cable for that camera group.
  ADDENDUM 2026-09-14 ~10:15Z: .102 SELF-RECOVERED -- rssi back at 01:45Z (-32 dBm, strong),
  ARP/ping healthy in fleet-check 10:15Z. Either it power-cycled itself or Nacho cycled it.
  Remaining ask: .104 (exterior_4) still power-dead since 09-12 11:00Z (47h+) -- needs the
  physical power cycle. If cycling does not revive it, check the PSU/cable on that camera group.

  CORRECTION (aria c313, 2026-09-14 ~10:22Z): the c312 "self-recovered" reading was WRONG.
  The rssi.log tail (-32/-33 dBm at 01:44-01:45Z) is the LAST SAMPLE BEFORE DEATH, not a
  recovery. rssi-puller has failed on .102 every 15min since 02:00:18Z (puller.log, 9
  consecutive failures through 10:15Z); ARP INCOMPLETE, ping 100% loss, no recordings since
  01:59:52 local (mtime 02:00:21Z local). .102 is power-dead since ~01:45-02:00Z 09-14 UTC
  (~8.5h at correction time). Original filing stands in full: BOTH .102 and .104 need
  physical power cycles. Scar logged: law 50 (verify the DELTA/CURRENCY of a tail sample
  against the puller's own failure log before calling a state change).
