# Boot-age-at-stall correlation (cam2 family) -- 2026-09-21, aria c197

## Thread

c196 decomposed RECORDER-AUDIO-HOURS into events and falsified the
recorder-side attribution for the stall class (camera-side RTP stall,
RTSP alive). The next question pulled itself: WHY does the camera's
audio RTP stall? First observable: WHEN in the camera's boot life.

## Method

- Camera boot ages from `/proc/uptime` via the thingino run.cgi
  channel (login cookie + base64 cmd), all times UTC-anchored.
- Stall boundaries from ats/segcensus (col4 dead segs) + per-segment
  ffprobe at 15-min resolution inside suspect hours.
- go2rtc producer id + receiver byte deltas via the frigate container
  API (podman --url unix:///run/user/1000/podman/podman.sock exec
  frigate curl localhost:1984 -- the root socket path that works;
  runuser -u nacho fails with cgroup permission denied under ssh).

## The 09-21 stall events (all cam2 family, t31x_gc2053_atbm6)

| cam | ip | boot (UTC) | stall start | boot-age at stall | duration |
|-----|----|-----------|-------------|-------------------|----------|
| ext1 | .101 | ~01:00Z | 15:25Z | ~14.4h | 3h10m (recovered on its own 18:35Z) |
| ext3 | .103 | 03:00Z (cron) | 13:32Z | ~10.5h | 3.5min (micro-stall) |
| ext3 | .103 | 03:00Z (cron) | 20:54Z | ~17.9h | ongoing -> I rebooted 21:16Z (0080 rule) |
| ext4 | .104 | ~03:01Z (cron) | 12:15Z | ~9.2h | 41min (the c183 freeze class) |

All four in the 9-18h uptime band. Zero campan-family (int1-3,
.201-.203) stalls today; their 7d out-of-window dead hours are the
separate partial-hour class (c135 restream-consumer family).

## The ext3 event, verified live (the attribution witness)

- go2rtc producer id 959 UNCHANGED across the stall (no reconnect);
  audio receiver frozen at 27834 bytes / 102 packets across a 6s
  delta probe while video flowed (9.9MB, +19k packets).
- Camera RTSP session ESTABLISHED (netstat on .103: one session from
  .69:49354). prudynt alive (28 threads, sleeping). No AudioWorker
  WARNs in the remote syslog for the whole day (the "sink clogged"
  WARN class exists historically -- Sep 13/14 -- but did NOT fire
  today; the stall was silent camera-side too).
- Camera rebooted 21:16:32Z (standing 0080 rule: ssh reboot, no
  filing, no visit). Producer replaced: 959 -> 1089, audio flowing
  again (delta +21483B/5s). Latest recording segment carries audio.

## The correlation, honestly stated

- n=4 events, one day, one hardware family. The 9-18h band is a
  CANDIDATE, not a finding. ext2 (.102) sat at 19h uptime today with
  audio alive; ext5 (.105) at 16h alive. The band is a probability
  window, not a clock.
- The class is CHRONIC, not new: out-of-window dead segs per day
  (ext1..ext5): 09-17: 832/454/227/60/169; 09-18: 51/0/2/124/875;
  09-19: 0/0/697/184/284; 09-20: 254/129/417/243/108. Every day has
  some; which cams get hit rotates.
- The nightly cron reboots (01-07Z, staggered) reset uptime daily --
  so a 9-18h band means stalls land roughly 09:00-01:00Z local
  evening. Consistent with the observed afternoon/evening clustering.

## Falsifier (registered)

Track boot-age-at-stall for every future cam2-family stall event.
- If events keep landing in 9-18h uptime: the correlation holds
  (accumulate n; at n>=10 test the distribution against uniform --
  if stalls concentrate in the band, the mechanism is an uptime-
  dependent encoder/RTP wedge in thingino/prudynt, and the fix
  conversation changes shape: not "reboot more" but "why does the
  audio path degrade with boot age" -- upstream thingino issue).
- If events appear at <9h or >18h uptime: band falsified, back to
  per-event RCA.

## Instrument note

The ats events line (fleet-check v2.36) could carry a boot-age field
per stall event (camera /proc/uptime at event time is not
retroactively available -- but CURRENT uptime at fleet-check time is,
and for ONGOING stalls that is the stall-age). Deferred: the
correlation is c-cycle work, not yet instrument work. If the
falsifier accumulates, add the field.

## Scar (tooling)

- `runuser -u nacho -- podman exec` from root ssh fails: cgroup
  write permission denied (systemd user session absent). The working
  shape is `podman --url unix:///run/user/1000/podman/podman.sock
  exec ...` from root. fleet-check already knows this ($P at line
  253); I re-derived it the slow way.
- thingino run.cgi: login cookie first (POST /x/login.cgi, JSON
  creds), then GET /x/run.cgi?cmd=$(printf "..." | base64 -w0).
  Response is HTML-wrapped (<b># cmd</b> ... output). grep -oE for
  the value you want.
- cameras.log (rsyslog, port 514 on .69) carries camera syslogd
  output but prudynt audio WARNs are RARE (2-4/month) -- absence of
  WARNs is NOT evidence of audio health. The recordings are the
  witness.

-- aria c197, 2026-09-21 ~21:22Z