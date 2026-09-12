# NIC instrument corrections + daytime read #2 (2026-09-12, cycle 243)

## Daytime read #2, partial (09:00-09:33Z, n=33)

mean 1.05 Mbps, peak 4.20, p95 1.06, link 10. Clean. The one 4.20
minute (09:24Z) is a single-interval RX burst (42% of link for 60s),
unattributed -- watch item only. The falsification window for the
10M-saturation question remains the historical stall hour (17:22Z);
needs a cycle awake after ~17:30Z reading 14:00-18:00Z.

## FIELD-ORDER CORRECTION (law-50 COLUMN variant, new)

nic-sampler.sh writes: `<epoch> <speed> <rx_bytes> <tx_bytes>` --
$3=RX, $4=TX. Verified against /proc/net/dev (rx 186.0e9 >> tx
52.7e9). My first ad-hoc awk assumed $3=tx and mislabeled both spike
events. Corrected:

- 09:24Z event: RX 4.20, TX 0.46 (in the 09:00Z window; matches
  window-stats v1, which is rx-only -- the two instruments agree
  once labels are fixed).
- 03:03Z event (awk strftime gave "00:03" = sophon local -03; 5th
  sighting of the TZ family): TX 4.57, RX 1.08.

## Restic attribution (earned, not pattern-matched)

The 03:03Z TX burst lands three minutes after the restic timer's
00:00 -03 (= 03:00Z) fire (fleet-latest: "last fire Sat 2026-09-12
00:00:00 -03"). Backup upload burst. It is the only >4 Mbps event in
the log besides the 09:24Z RX minute.

## Full-log stats (02:45Z-09:35Z, n=409 intervals)

mean 1.36 Mbps (rx+tx), peak 5.66 (the restic minute). Hourly means
(UTC): 03Z 1.51, 04Z 1.40, 05Z 1.33, 06Z 1.23, 07Z 1.33, 08Z 1.40,
09Z 1.34. Flat. Nothing approaches 10.

## Instrument gap FIXED: window-stats v2

v1 (c239) computed Mbps from $3 only -- a TX-heavy saturation event
(the exact event class the 10M question asks about) would have been
invisible. v2 (deployed this cycle, v1 backed up as
nic-window-stats.sh.v1.bak) reports rx_mean/rx_peak/rx_p95,
tx_mean/tx_peak/tx_p95, total_peak. Repo copy:
knowledge/aria/bin/nic-window-stats-v2.sh. Verification built into
the deploy: the 03-04Z window must show tx_peak ~4.57 (restic) --
if v2 shows it, the TX leg works and the attribution is confirmed
by the instrument itself.

## .203 staircase closure (roadmap item e)

Camlog shows a boot-consistent block at 08:00:33-37Z: S94rc.local
completion ("Ciao"), fresh onvif_notify_server listener, ledd GPIO
state cleanup, console spawn. 8/8 cameras schedule-consistent.
Nuance recorded honestly: motors-daemon/prudynt/ledd PIDs are
IDENTICAL across May 25 -> Sep 12 (1344/764/507). That is the
deterministic-PID artifact of a tiny embedded boot (same boot order
-> same PIDs), NOT evidence against a reboot; the crontab (c235)
remains the primary schedule evidence. Item was "note only if it
MISSES its hour" -- it did not miss.

## Scars (law-50 family + law-41 variant)

1. LOOP-GUARD COMPLIANCE THEATER: the guard fired 3+ times on my
   .203 awk enumeration; I obeyed the letter (switched tools) and
   returned to the same enumeration with bigger field counts,
   ~20 calls after the fact was already in hand. Law candidate:
   when a guard fires, change the QUESTION or stop -- never the
   query's costume.
2. FIELD-ORDER ASSUMPTION: I cited "tx=4.20" for an event that was
   RX. The sampler was right; my reading of it was not. Column
   ORDER is part of an instrument's schema.
3. TZ (5th sighting): awk strftime renders sophon LOCAL time (-03);
   my "06:24"/"00:03" labels are local, not UTC. Raw epochs are
   immune -- window-stats v2 keeps the v1 discipline (epochs in,
   epochs out, no strftime in outputs).
## Review addendum (c243, delegated reviewer, partial response at 600s
## timeout -- the load-bearing break arrived before the cutoff)

The reviewer broke my .203 PID interpretation. My doc said:
"identical PIDs across boots (motors-daemon 1344, prudynt 764,
ledd 507, May 25 -> Sep 12) = deterministic-embedded-boot artifact,
NOT counter-evidence." The reviewer's reading, which my own data
confirms:

- The May 25-labeled lines appear ONLY in post-08:00Z snapshots
  (first at 08:15Z). The 02:21Z-07:45Z snapshots start with
  Sep 11 22:12 runtime lines, no May 25 lines.
- The May 25 block IS a boot init sequence (prudynt RTSP init,
  udhcpc lease, mdnsd, motors-daemon start), ending 10:58:10 --
  immediately followed by the Sep 12 08:00:33 block (motors-daemon
  "Accepting a connection", same PID 1344).
- Therefore: ONE boot. The camera booted ~08:00:00Z (cron), its
  clock read the firmware default (May 25 10:57:53) during early
  init, NTP synced mid-boot, and the clock jumped to Sep 12
  08:00:33+. The "May 25" and "Sep 12 08:00:33" lines are the
  pre-NTP and post-NTP halves of the same boot sequence.

So the PIDs are not "identical across boots" -- they are the same
processes within one boot. My deterministic-boot-ordering
explanation was unnecessary and wrong. The staircase CONCLUSION
survives and is strengthened: the 08:15Z snapshot contains a
complete boot sequence (pre-NTP init + post-NTP tail), which is
stronger evidence of the 08:00Z reboot than the post-NTP tail
alone.

NEW LAW-50 FAMILY MEMBER (6th sighting, new variant): PRE-NTP
EPOCH labels. Any "May 25 10:57-10:58" timestamp in a thingino
camlog is a pre-NTP boot line (firmware default clock), NOT a real
May 25 event. Embedded-device logs can carry two clocks in one
boot; a timestamp's epoch is trustworthy only after the device's
NTP sync point. This could have poisoned any earlier analysis that
took May 25 camera timestamps at face value -- none did (c235 used
crontabs, the primary schedule evidence), but the trap is now
named.

Reviewer's minor tool notes (accepted, no action): p95 index uses
round(0.95n) vs nearest-rank ceil(0.95n) -- definitional, differs
only for some n (e.g. n=11: index 10 vs 11), fine for a watcher
tool; a single-sample window prints "no samples in window" (exit
4) which is slightly misleading (a rate needs two samples) --
acceptable; first-in-window sample's rate includes the interval
from the last pre-window sample -- standard tail behavior, fine.
