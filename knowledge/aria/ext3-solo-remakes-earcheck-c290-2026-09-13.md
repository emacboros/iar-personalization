# EXT3 SOLO SESSION-REMAKES + EAR-CHECK TRANSIENT (c290, 2026-09-13)

## The find: 6 benign solo producer re-dials on ext3 today

The camlog puller's snapshot-overlap inflation (each 15-min pull
re-appends overlapping logread ring content) initially showed 7
"backchannel sessions" on .103 today. Deduped by (session, socket,
channel): SEVEN real sessions, 3 channels each:

| camera time (UTC) | frigate-side witness (local) |
|---|---|
| 03:00:34 | 03Z reboot staircase reconnect (expected) |
| 04:47:16 | 01:46:32-01:47:32 producer read-timeouts x3 + CONN-state |
| 04:47:36 | 01:47:32 timeout -> re-dial |
| 04:48:09 | ~01:48 re-dial |
| 05:57:16 | 02:57:10 timeout |
| 05:57:59 | 02:57:58 timeout |
| 06:44:07 | 03:44:07 timeouts x2 |

The 6 non-reboot remakes are go2rtc producer re-dials after camera-side
read-timeouts. They did NOT kill detect (zero fps-limits, zero splices)
and did NOT kill audio: segments spanning every remake window probe
250 pkts / ns=256000. BENIGN self-heals.

## What this refines

- The solo-death class (samples #1/#2, c269) refines to: producer
  re-dials are COMMON (6x on one camera in one morning) and usually
  harmless. Solo-DEATH = re-dial + detect death (fps-limit within
  +24-34s) + splice. The discriminator between "remake" and "death"
  is whether detect ffmpeg dies within the watchdog window.
- Snapshot-overlap inflation is a camlog-puller artifact: distinct-
  session counts from the pulled logs MUST dedup on (session, socket,
  channel) before counting. (The puller appends overlapping ring
  snapshots; 51 lines at one timestamp = 17 real lines x3 overlaps.)

## The ear-check transients (c289's "ext3 3/3-dead")

Two 3/3-dead readings on ext3, both transient:

1. 03:01:43Z (timer run): 27s after .103's 03:00:34Z reboot-reconnect.
   CONFIRMED mechanism: the 3 newest completed segments at that moment
   were mid-reboot artifacts. Reboot-window artifact class.
2. 07:01Z (c289's manual run): the 3 segments that check would have
   read (04/00.00, 00.14, 00.33 local = 07:00-07:01Z) are all 250-pkt
   HEALTHY now. Non-reproducible; likely 3x transient volumedetect
   failure (io hiccup in the remake aftermath). Unexplained.

Ear check re-run this cycle: ext3 ns=256000 x3, healthy. Verdict:
watch only, but seed the discriminator (below) rather than chase.

## THREADS seed: ear-check discriminator

Candidate guards for fleet-check ear check v2.22:
- Reboot-window guard: skip cameras whose camera rebooted <2min before
  the check (staircase hours are KNOWN: ext1 01Z ... int3 08Z).
- Single-segment re-probe: on a 3/3-dead verdict, re-probe the 3
  segments once before failing (transient ffmpeg/io failure x3 is
  the observed false-alarm shape).
- mtime guard: skip segments younger than 60s (v2.16 skips only the
  single newest; a remake can leave 2-3 young partials).

## Instrument notes

- camlog puller dedup law: count sessions on (session, socket, RTP
  channel), never on raw line counts.
- frigate journalctl --since parses LOCAL time on sophon; camera logs
  are UTC. The c289 clock law applied again (one empty grep window
  burned re-deriving it).

[EXTERNAL DATA]: none -- all primary evidence from sophon logs and
recordings.