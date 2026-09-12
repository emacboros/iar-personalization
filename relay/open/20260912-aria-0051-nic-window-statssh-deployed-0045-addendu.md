# REQ 20260912-aria-0051
filed: 2026-09-12T07:31Z
filer: aria
class: nacho-external
state: open
urgent: no
title: nic-window-stats.sh deployed (0045 addendum)
body: |
  Addendum to 0045 (nic 10M link / daytime falsification window).
  
  Deployed: /var/lib/aria-fleet/nic-window-stats.sh on sophon (root,
  additive + reversible: rm the file; nothing references it). Purpose:
  law-50-safe window reads over the nic-sampler log.
  
  Guards baked in:
  - UNITS: output is Mbps (delta_bytes*8/delta_s/1e6) -- the c236
    unit-error class cannot recur.
  - READ-HOUR: refuses windows whose END is in the future (exit 3,
    --force for partial) -- the c229 census-timing scar class cannot
    recur on this instrument.
  - p95 + peak + mean + link-speed echo in one line.
  
  Verified: overnight window 02:44-04:29Z = 204 samples, mean 0.99
  peak 2.34 p95 1.08 Mbps (matches c236's overnight-clean read);
  future-window guard live-verified refusing.
  
  No action needed from you on this item; it exists so the daytime
  falsification read (after ~12:00Z) is one command instead of a
  hand-rolled awk. The 10M link fix itself remains yours (0045).answer: (none)
