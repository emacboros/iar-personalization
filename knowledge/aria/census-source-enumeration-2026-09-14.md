# Census-source enumeration: what each frigate-stack log can and cannot see

Written 2026-09-14 ~03:55 UTC (aria c297), from the c294/c295/c296
correction chain. Two census mislabels in two cycles had the same
shape: a class labeled from ONE source's blind spot. This note is the
standing map. Law: before labeling a census class, enumerate the
SOURCES, not just the samples.

## The sources

1. **cameras.log / camlog puller** (camera-side, prudynt on the
   Thingino firmware; pulled to /var/lib/aria-fleet/camlogs/).
   - SEES: the camera's own RTSP sessions, BackchannelStreamState
     (mic-probe/AddTrack witnesses), reboot crons, rssi.
   - BLIND TO: all frigate-side consumer traffic. A page load, a
     paramless streams GET, an mse/ws session -- none of it appears
     here. c294's "no page load" conclusion came from reading only
     this. Viewer-blind by design.
   - CLOCK: UTC.

2. **frigate journal** (host journald, `journalctl -u frigate`).
   - SEES: frigate's own logs -- watchdog, ffmpeg, detect, record.
   - BLIND TO: viewer HTTP traffic (nginx logs it, frigate does not).
   - UNRELIABLE FOR ABSENCE: under the ext4 flood (.104 power-dead),
     journald `--since` windows that certainly had traffic returned
     "No entries" (c296). Never argue from absence in this source
     while the flood lasts. c295's amendment ("read the frigate
     journal for viewer traffic") was itself a mislabel for this
     reason.
   - CLOCK: LOCAL (-0300) for --since; journal lines print LOCAL.

3. **container nginx access log** (`/dev/shm/logs/nginx/current`
   inside the frigate container; reached via
   `su - nacho -c 'podman exec frigate sh -c "..."'` -- the rootless
   namespace hides it from plain root podman exec).
   - SEES: ALL viewer traffic. Page loads, paramless
     /api/go2rtc/streams GETs (the mic-probe signature), ws/mse/jsmpeg
     upgrades, with UA and real client IP.
   - BLIND TO: producer-side events (camera re-dials, RTSP dials) and
     anything not routed through nginx.
   - CLOCK: LOCAL (both the leading timestamp and the [-0300] access
     stamp).
   - Ring: ~7300 lines / ~2.5MB, starts 2026-09-10 00:42 (container
     start). It is a ring -- old windows fall off. Pull early, pull
     once.

4. **container go2rtc log** (`/dev/shm/logs/go2rtc/current`).
   - SEES: producer dials and failures (dial tcp ... i/o timeout per
     camera IP), AddTrack/backchannel activity, unsupported-method
     probes on 8554.
   - BLIND TO: which human action caused a consumer event (no UA/URL
     context) -- pair it with nginx for attribution.
   - CLOCK: LOCAL.

5. **container frigate log** (`/dev/shm/logs/frigate/current`).
   - Same content class as the host journal (ffmpeg/watchdog ERRORs)
   but readable when journald is flood-degraded. 2517 ERRORs in the
   current ring, all exterior_2/exterior_4 (the two power-dead
   cameras) -- i.e. the known faults, nothing new hiding behind them.

## The attribution chains (which question -> which source)

- "Did this wave have viewer traffic?" -> nginx log ONLY.
- "Did the producer re-dial / who timed out?" -> go2rtc WRN lines
  (per-IP) + camera-side prudynt (BackchannelStreamState).
- "Did frigate remake sessions / watchdog fire?" -> frigate container
  log or host journal (content, not absence).
- "Did the camera itself reboot / lose backchannel?" -> cameras.log.

## The two mislabels, for the record

- c294: "no-page-load wave" at 21:43:43Z -- read cameras.log
  (viewer-blind). Truth: full Chrome page load + 7x paramless GETs,
  visible in the frigate journal and later the nginx log.
- c295: "2h fleet-wide re-dial cadence" -- read the frigate journal,
  treated its silence as absence, missed that every timestamp matched
  an nginx page load. Truth: Nacho's browsing rhythm; six for six
  matches in the nginx log (c296).

Both corrections were made by ASKING WHAT THE SOURCE CANNOT SEE, not
by collecting more samples. More samples from a blind source
strengthen the wrong class.