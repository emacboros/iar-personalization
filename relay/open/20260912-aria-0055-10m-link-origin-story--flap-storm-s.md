# REQ 20260912-aria-0055
filed: 2026-09-12T07:46Z
filer: aria
class: nacho-test
state: open
urgent: no
title: 10M link origin story -- flap storm Sep 1, partner advertises gigabit, fault window Aug31->Sep1
body: |
  CLASS: nacho-test
  TITLE: 10M link origin story -- flap storm Sep 1, partner advertises gigabit, fault window Aug31->Sep1
  BODY:
  Upgrade to 0045 (sophon NIC linked at 10Mb/s). Read the link's
  history from the kernel journal; the origin is now known to the
  minute.

  TIMELINE (boot 0, sophon):
  - Boot: Sep 1 01:27:34 -03. Link up 01:27:58 at 100Mbps/Full
    (downshifted) -- degraded from the first breath.
  - 03:24:31: Link Down. Then a 15s-down/15s-up flap cycle x8
    (03:24:31-03:25:57) while the r8169 downshift ladder walked
    1000 -> 100 -> 10.
  - 03:25:57: settled at 10Mbps/Full (downshifted). 11.5 days and
    counting; every read since (sampler, ethtool) says 10.

  NEW FACTS:
  1. The link partner ADVERTISES 10/100/1000 (ethtool "Link partner
     advertised link modes"). The 10M-only-port hypothesis is
     EXCLUDED. Cause class = physical layer: cable with only two
     good pairs (10/100 need 2 pairs; gigabit needs 4), marginal
     terminations, or damaged pairs.
  2. Boot -2 (Aug 31 16:04 - Sep 1 01:24 -03) has ZERO link events
     in its kernel journal -- the link held without a single flap.
     The fault appeared between Aug 31 and Sep 1 01:27. Sharper
     question than "check the cable": what was touched, moved, or
     re-plugged around Sep 1 01:27 local?
  3. The 03:24:31 first link-down coincides with the first recorded
     house-wide RTSP storm: 16 go2rtc i/o timeouts (.104/.101/.201)
     in the 20 minutes after. The 10M link is the residue of a
     physical fault that announced itself on day one of this boot.

  FIX (unchanged, evidence stronger): re-terminate or replace the
  cable, or move sophon to a different switch port. After the fix,
  the falsifier is one line: ethtool enp10s0 | grep Speed should
  read 1000Mb/s, and the sampler log's link_speeds column should
  flip to 1000.

STATUS NOTE 2026-09-12T17:35Z (aria c260): origin story stands as
filed (flap storm Sep 1 03:24-03:25Z, ladder walk 1000->100->10,
partner advertises gigabit => physical-layer cause). Hardware fix
(cable re-terminate/port move) remains Nacho's. Falsification
window (14:00-18:00Z daytime saturation test) rescheduled for the
next clean day -- the 09-12 outage contaminated the first attempt.

## ADDENDUM (2026-09-12 17:58Z, aria c261): falsification window CLOSED
- 14:00-17:54Z clean-day read: no saturation at 7/8 cameras (RX
  peak 1.11 Mbps, total peak 2.15 Mbps vs 10 Mb/s link). Cable fix
  = hygiene, not urgent. Original flap-storm analysis stands.
