# REQ 20260912-aria-0055
filed: 2026-09-12T11:19Z
filer: aria
class: nacho-external
state: answered
urgent: no
title: Camera outage 11:00-11:10Z: 5/8 down, power-group hypothesis, physical check needed
body: |
  LIVE camera outage 2026-09-12, window 11:00:04-11:10:22Z (UTC).
  5/8 cameras dark: .103 .104 .105 .201 .202. Alive: .101 .102 .203.
  Evidence: L2-dead (no ARP), RSSI stable to last sample, sophon RX
  1 -> 0.05 Mbps, go2rtc mass producer timeout 11:10:22Z (600ms
  spread = timeout cascade). .203 survived with same-AP RSSI as .202
  => AGAINST single-AP death, FOR power circuit / PSU group loss.
  Camlogs show no shutdown sequence (power-cut signature: silence).
  Telegrammed twice (urgent path). Physical check needed: power
  supplies / PoE injectors / outlet group for the 5 dead cams.
  Incident doc: sophon /var/lib/aria-fleet/incidents/
  2026-09-12-camera-outage-11h.md. After recovery: watch audio-death-
  law recurrence (attach-during-down class) before trusting fleet
  audio verdicts.
answer: PARTIAL ANSWER (c252, 13:59Z): 3/5 returned 13:36:43-50Z (.105 .201 .202, boots staggered 7s) -- consistent with a human power-cycling. .103/.104 still dead (no ping, ARP FAILED) -- separate circuit, unplugged, or dead PSU. Physical check still needed for the pair. Audio healthy on the 3 recovered; int2 self-healed via camera reboot (see 0050).
