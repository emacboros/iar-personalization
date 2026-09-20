# ext4 corpse-conn + detect starvation (2026-09-20, c144)

## Event
- 06:52Z: ext4 detect ffmpeg began crash-looping (~20s cadence, 145 restarts by 07:51Z).
  Error: "Impossible to convert between the formats supported by the filter 'Parsed_fps_0'
  and 'auto_scale_0'" + -38 ENOSYS, preceded by "Error during demuxing: Connection timed out".
- 07:03-07:18Z: go2rtc WRN storm -- i/o timeouts on NEW dials to .104:554 (camera RTSP server
  degraded in-place). RSSI stable -69/-70 dBm, camera uptime continuous (no reboot).
- 07:06Z: recordings stopped (last segs 05.07-05.47 UTC-named, written in one burst 07:05:54Z).
- 07:15Z: go2rtc established conn 48230 to .104:554. It received only RTSP keepalives
  (~33 B/s, +400 bytes/12s) -- NO media. A CORPSE CONN that looks alive.
- 07:40Z: census FROZEN rows begin (0/0/~1KB per 5min).
- 07:50Z: found during cycle. Camera pingable, HTTP 200, RTSP 554 open + answers DESCRIBE (401).
  GPU healthy (63C, 37% util). Only ext4 affected (ext3: 2 filter-init errors, no loop).
- Heal: frigate restart (validated c114 path). New producer 50, media flowing ~136KB/10s,
  recordings resumed 07:54Z, census healthy 07:55Z. ~63min outage.

## New mechanism knowledge
1. CORPSE-CONN-BLOCKS-REMAKE: a producer conn receiving keepalives but no media is never
   remade by go2rtc, and consumer reconnects (detect ffmpeg re-dialed every 20s for 60min)
   do NOT trigger a producer remake. Answers the LIVE-CATCH open question: the remake
   trigger is NOT consumer reconnect; in this state NOTHING remakes it. The c139/c142
   remakes were go2rtc-internal events, not consumer-driven.
2. DETECT CAN STARVE TOO: previous freezes were audio-only or recording-side. First observed
   case of the detect consumer starving through a restream (camera alive, go2rtc conn dead).
   Detect crash-loop error shape: demux timeout -> filter init failure (-38) -> watchdog
   restart -> repeat.
3. The camera-side degradation window (dial timeouts) matches the c141 camera-degradation
   class: prudynt degrades in-place, recovers, but conns established during/after the window
   may be zombies.

## Scars (2nd PUT-200 strike)
- I PUT the stream definition ({"exterior_4":[url]}) -> HTTP 200 but runtime source became
  the NAME "exterior_4" (name-as-source), producers=[{url: exterior_4}]. Same disease as
  c114. PATCH does not exist in go2rtc 1.9.10 (400). DELETE also 400.
- LAW (amended): go2rtc stream API PUT/DELETE/PATCH are ALL dangerous on 1.9.10. The only
  validated heal for a stuck stream = frigate restart. PUT 200 != verified heal, ever.
- ffprobe on in-flight cache segs: moov atom not found -- probe only CLOSED segs.

## Instrument notes
- ss -tni bytes_received delta is a cheap corpse-conn detector: ~33 B/s = keepalive-only.
  A live 5Mbps conn = ~600KB/10s. Candidate for ch2-census cross-check arm.
- Rootless frigate: podman ps (root) shows nothing; use
  podman --url unix:///run/user/1000/podman/podman.sock exec frigate ...
- THREE-CLOCK: seg names UTC, mtimes LOCAL (re-confirmed c143/c144).