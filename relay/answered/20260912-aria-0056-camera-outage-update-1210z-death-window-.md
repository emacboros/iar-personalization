# REQ 20260912-aria-0056
filed: 2026-09-12T12:11Z
filer: aria
class: nacho-external
state: answered
urgent: no
title: Camera outage update 12:10Z: death window tightened, single-AP excluded, power-group stands
body: |
  UPDATE to 0055 (camera outage, now 60+ min, no recovery at 12:10Z).
  
  TIGHTENED DEATH WINDOW: 11:10:0x-11:10:3xZ (last frigate segment
  flush 11:10:38Z for all 5 dead; NIC RX step 11:10->11:11Z; go2rtc
  timeouts 11:12:25-32Z are its own late TCP timeout).
  
  AP MAP CLOSED: all 8 cameras verified on ONE AP (.55, BSSID
  72:7f:f0:1e:4a:a8, nacho_guest VAP) via wpa_cli on the 3 survivors.
  Single-AP death EXCLUDED. RSSI does not separate dead from alive
  (-39 dead vs -40 alive). POWER CIRCUIT / PSU GROUP remains the best
  fit: 5 cams dark with no shutdown logs, 3 on the same AP alive.
  
  NEW FACT: cameras run UTC (verified on .203). The 08:12:43Z
  dropbear probe on .202 was my own c241 fleet-check (sophon journal
  confirms container ssh at 08:12:00Z) -- 3rd confirmation, not an
  attacker.
  
  SURVIVORS HEALTHY: ext1+int3 audio 250pkts, ext2 = known-deaf stub
  (unchanged). Frigate keeps recording the 3 alive cams.
  
  ASK: physical check of the power group / PSUs / outlet circuit
  serving .103 .104 .105 .201 .202 when you are next in the house.
  Incident doc: sophon /var/lib/aria-fleet/incidents/
  2026-09-12-camera-outage-11h.md (c248 addendum).
answer: PARTIAL ANSWER (c252, 13:59Z): 3/5 recovered 13:36:43-50Z; .103/.104 still dark. Staggered boots = manual power-cycle signature; the pair did not return with the group.
