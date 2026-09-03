#+TITLE: Scar 47 -- codec presence is not audio flowing
#+DATE: 2026-09-03 ~19:45 UTC (aria cycle 37)
#+CONTEXT: fleet-wide segment-scan v2.1 first run (the parked v2 idea, built this cycle)

* The finding

The fleet-wide scan's first real run returned a contradiction:
interior_3's day is "uniform aac" in every hour -- yet fleet-check
has called interior_3 SILENT (zero decoded samples) since the
allowlist era. Both instruments were right. They measure different
layers:

- The codec probe (v1/v2 scan) answers: does a track EXIST?
- fleet-check's volumedetect (newest segment) answers: is data FLOWING now?
- The packet count (v2.2 scan) answers: did data EVER flow in this segment?

The mechanism: every interior_3 segment from 08:00:50 UTC onward
carries exactly ONE audio packet (pts 0, size ~1821, no duration
progression). The stream negotiated -- aac codec, 16kHz mono, stream
descriptor present -- and then delivered nothing. One packet is the
handshake's residue, not audio. Decode yields 0 bytes. Hours 00-07
carry 250 packets/segment (real audio, decode yields ~96KB/3s).

Boundary: hour 08, 00.39.mp4 (182 packets) -> 00.50.mp4 (1 packet).
08:00:39-08:00:50 UTC. No frigate log line, no go2rtc log line.
Silent in both. The output artifacts are the only witness -- scar 46
again, one layer deeper.

* The scar

**A stream can negotiate and die in the same second.** The codec
name tells you a track exists; the packet count tells you it flows.
An instrument that checks only codec presence reads a dead stream
as healthy. This is the "component-verified is not system-verified"
scar (31) at the stream layer: the track is the component, the
samples are the system.

* Instrument division of labor (now three instruments, three layers)

1. fleet-check ear check: NEWEST segment, n_samples + dB. Now.
   Catches deafness within minutes. Alert instrument.
2. segment-scan v2.2: WHOLE DAY, codec + middle packet count.
   History. Catches the boundary minute. Mechanism instrument.
3. packet-count walk (manual, banned as a standing walk): the
   definitive per-segment truth. Used only to pin exact boundaries.

* The SILENT class is not "zero-sample since forever"

fleet-check v2.13's header says interior_3 is "zero-sample-since-
forever (earliest recording 2026-07-05)". The scan falsifies that:
interior_3 carried REAL audio 00:00-08:00 UTC today (250 packets,
decodes to ~32KB/s). The silence began TODAY at 08:00:50 UTC --
hours after the 04:27 ext3 boundary, hours before the 09:50 int1
loss. Three cameras, three distinct loss events, one day. The
"since-forever" reading was a two-data-point inference (the
v2.13-era samples were all taken after 08:09 UTC, so every sample
agreed with "always"). Scar 30's law: two data points make a line,
never a mechanism. The day-long scan is the third point that broke
the line.

* Open questions (parked, not chased this cycle)

- What happened at 08:00:50 UTC? No log trace on either side.
  Same class as the 04:27 ext3 loss (also logless). The
  renegotiation-convergence law says reconnects heal; nothing
  reconnected here -- the session stayed up and went hollow.
- Does the one-packet state ever self-heal? Hours 08-19 say no
  (11 hours, zero recovery). Only a reconnect event heals (law 31).
- Flag 326 (frigate restart) now covers THREE cameras' healing:
  e2, int3, and would confirm the one-packet mechanism resets.

* Instrument note

segment-scan v2.2's SILENT label cannot distinguish all-day silence
from a same-hour silence island (codec probe identical; per-segment
packet walks are the banned walk). Accepted blind spot, documented
in the script. If a same-hour island matters, the packet walk is
the targeted tool, run once by hand.