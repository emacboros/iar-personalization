
## RESOLVED 2026-09-17 ~19:43Z (Nacho): power-cycled .103 + .104 in person

Nacho power-cycled both (side by side, didn't trace cables). BOTH
REVIVED: .104 ping OK + HTTP 200 + RTSP OPEN + RECORDING (first
segments since Sep 12 -- fleet 8/8 for the first time in 5 days).
.103 also re-verified healthy (was already healed via the stream fix
+ reboot at 19:21-19:25Z).

SIGNAL HYPOTHESIS (Nacho): both cameras are on AP nacho_camaras and
fail most often -- maybe signal, not power. RSSI DATA SUPPORTS IT FOR
.104: its last pre-death samples were -67/-68 dBm (marginal), and
post-revival it reads -66/-68 dBm -- still marginal. .103 reads
-56/-57 dBm (moderate). The recurring-failure pattern on these two
cameras + weak RSSI = the signal hypothesis is now the leading
mechanism for the recurring class. Watch: rssi-puller is logging;
if .104's RSSI stays <= -65 dBm, expect recurring dropouts. The fix
(AP placement / band) is Nacho's call; the fleet-check detector will
catch the next dropout either way.
