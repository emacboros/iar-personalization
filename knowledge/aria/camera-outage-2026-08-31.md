# Camera Outage 2026-08-31: ext3/ext4 death + cam2-4 resurrection at a new IP

Written cycle 53 (2026-08-31 ~17:30-17:55 UTC). The fleet ear check
said GREEN; the truth was a 30-minute-old double camera death. The
instrument's first FALSE GREEN, and the reason is structural.

## The blind spot (why the ear check missed it)

The fleet newest-segment ear check reads the NEWEST segment per
camera and probes its streams. A stale-but-valid segment (written
before a camera died) reads as healthy forever. The check verified
CONTENT, never FRESHNESS. Fix: always compare newest-segment mtime
against now; anything older than ~2 min is a recording stop, which
is itself an event. Segment AGE is a first-class signal.

## Timeline (UTC, overlay timestamps are UTC too)

- 14:05:45-14:06  RTSP i/o timeouts from .103/.104 (go2rtc producer
  errors). Detect ffmpeg watchdog fires for both cameras.
- 14:06-17:24     DETECT path dead for ext3/ext4: crash-restart loop,
  149 (ext3) and 161 (ext4) restarts, zero frames. The loop is
  INVISIBLE in the newest-segment check because record kept going.
  ext4 had flapped detect earlier too: 15:07-15:39 UTC, 24 no-frames
  events, self-recovered.
- 17:24:22        NETWORK-WIDE blip: go2rtc lost ALL 5 remote
  producers simultaneously (.103, .104, .105, .201, .202). Four
  recovered within seconds. .103/.104 never returned.
- 17:24:39        Last ext3/ext4 recording segment written (24.03.mp4).
- 17:34+          My ear check: newest segments video+audio, all
  volumes baseline. FALSE GREEN -- the segments were 10+ min stale.
- 17:41+          Investigation. cam2-4 found ALIVE at NEW IP
  192.168.2.100: RTSP ch0 hevc+aac, ch1 h264+aac, MJPEG flowing.
  Clock stuck at May 25 (no NTP; RTC dead), latency bursts to
  1400ms then settling to ~10ms. NOT in frigate config -- frigate
  still points at .104, which is DEAD (ARP INCOMPLETE).
- 17:54 NOW       ext3 (cam2-3, .103): DEAD -- ARP FAILED, no ping,
  no RTSP, no HTTP on any port. ext4 (cam2-4, .104): DEAD at old IP.
  6/8 cameras recording normally.

## The two-layer architecture insight (frigate 0.17)

Frigate's DETECT and RECORD paths fail INDEPENDENTLY:

- DETECT reads via go2rtc restream (127.0.0.1:8554/<cam>) and is
  watched by the watchdog (fires on 20s of no frames).
- RECORD is a separate ffmpeg (started 13:04/13:05, before the
  outage) reading the go2rtc restream directly, writing segments to
  /tmp/cache, moved to recordings/ by the maintainer.

During 14:06-17:24: detect crash-looped (its restarts kept failing
on the 8554 404) while record kept writing healthy segments off the
same go2rtc. When the 17:24 network blip killed the go2rtc producers
themselves, record died too -- 3 hours after detect. Two failure
surfaces, two death times, one watchdog that only sees the first.

This explains cycle 51/52's audio flapping too: the record ffmpeg
survives producer hiccups that kill detect, and renegotiates when
the producer returns. "Record never renegotiates" (cycle 46) and
"record renegotiates" (cycle 52) were both sampling different
failure modes of this two-layer system.

## The cam2-4 resurrection at .100

- Overlay says cam2-4 (matches ext4). Alive, streaming both channels.
- Clock: May 25 11:36 + slow drift, uptime counter unreliable. No
  NTP, RTC battery dead or never set. The overlay timestamps on this
  device are USELESS for forensics (unlike the other cams, which
  keep real time).
- MAC: .100 answers ARP with 0a:8a:f1:0a:62:56 -- the SAME MAC as
  .101 (cam2-1). Two devices, one MAC = clone or randomization
  collision. thingino MACs on this network look randomized
  (02:xx:xx locally-administered on .102/.105).
- The device is NOT in frigate config. Frigate points at .104.
- Reading: cam2-4 likely rebooted (power event?), came back on DHCP
  at .100 (or its config reset), lost its NTP sync. .103 (cam2-3)
  did not come back at all.

## What needs the human (FOR-NACHO)

1. Physical check: are cam2-3 (.103) and cam2-4 (.104) powered?
   Same PoE switch/port? The 17:24 blip hit all cameras at once --
   switch reboot or power event is plausible; 3 of 5 recovered.
2. If cam2-4 is the device now at .100: either pin it back to .104
   (DHCP reservation) and restart frigate, or update frigate config
   to .100. Its clock needs NTP (thingino has an NTP setting).
3. cam2-3 (.103) is fully unresponsive -- power cycle needed.
4. The MAC collision (.100 vs .101) is worth checking in the switch
   -- MAC cloning between two cameras can break switching.

## Instrument fixes adopted this cycle

1. Ear check MUST include segment age: newest segment older than
   ~2 min = recording stopped = event, regardless of content.
2. "All green" from newest-segment checks is now understood as
   "the newest data was healthy WHEN IT WAS WRITTEN". Freshness is
   a separate axis. Stale data is not healthy data.
3. Watchdog asymmetry (THREADS.org, cycle 30) gets a concrete third
   instance: frigate watchdog watches detect only; record has NO
   watchdog; go2rtc producers have no watchdog. Three layers, one
   monitor.