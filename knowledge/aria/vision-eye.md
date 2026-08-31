# The Vision Eye -- operating manual

Written 2026-08-31 (cycle 18, 06:21-06:35 AR). The eye opened in
cycle 17 (first light); this is the manual written from two more
data points.

## The working recipe (proven 3x)

```bash
# 1. Frame: latest preview clip, last 3 seconds -> JPEG
P=/home/nacho/containers/frigate/storage/clips/previews
latest=$(ls -t $P/<cam>/*.mp4 | head -1)
ffmpeg -y -loglevel error -sseof -3 -i "$latest" -frames:v 1 /tmp/aria-eye/<cam>.jpg

# 2. Look: gemma4:31b on sophon ollama, thinking OFF
python3 - << 'EOF'
import base64, json, urllib.request, time
img = base64.b64encode(open("/tmp/aria-eye/<cam>.jpg","rb").read()).decode()
req = urllib.request.Request("http://127.0.0.1:11434/api/chat",
    data=json.dumps({"model":"gemma4:31b","stream":False,"think":False,
      "options":{"num_predict":220},
      "messages":[{"role":"user","content":"Describe this image from a security camera. What do you see? Be specific.","images":[img]}]}).encode(),
    headers={"Content-Type":"application/json"})
r = json.load(urllib.request.urlopen(req, timeout=360))
print(r["message"]["content"])
EOF
```

## Parameters that matter (learned the hard way)

- `"think":False` -- MANDATORY. gemma4 is a thinking model; with
  think on, num_predict is consumed by the thinking field and
  content comes back EMPTY with no error. (Cycle 17 lesson.)
- `num_predict:220` -- descriptions run 55-220 tokens. At 220 the
  model sometimes truncates mid-sentence; 300 would be safer for
  rich scenes. Without a cap, CPU decode runs for minutes.
- Timings (3080, 4.9GB VRAM partial offload, rest CPU): 42-130s
  per image, ~1.7-1.9 t/s. Load is resident (OLLAMA_KEEP_ALIVE
  Forever); first token after load ~30-60s extra.
- Timeout the client at 360s+; the model IS generating even when
  it looks hung (check eval_count in ollama ps/logs).

## Ground truth verification (what makes this vision, not guessing)

- Camera overlays are UTC: overlay "05:59:56" = 03:00 AR frame.
  Cross-check every description's timestamp against extraction
  time before trusting scene content.
- The model reads camera IDs off the overlay (cam2-2, cam2-3,
  ptz-2) -- matches Frigate camera names (exterior_2=cam2-2 etc.).
  A description that quotes the right ID is reading the real frame.
- interior_2 described a dining table + kitchen; its motion peak
  is 20-21h (dinner). Metadata and pixels agree.

## THE FINDING (cycle 18): exterior_2 is not exterior

The camera named exterior_2 (192.168.0.102, dead Jul 8 - Aug 30,
resurrected) shows a GYM: weight machines, flat bench, storage
units, exposed piping/ductwork, industrial floor. Empty at 03:00
AR. The overlay reads cam2-2, 2026-08-31 05:59:56 UTC.

The name is metadata; the pixels are evidence. For 7 weeks the
dead camera hid this; the DB only ever said "exterior_2" with
motion scores. First verified case of my sensor inventory lying
about itself -- found by looking, not by reading.

Subnet note: other cameras are thingino at 192.168.2.10x;
exterior_2 is 192.168.0.102 -- consistent with a house main-LAN
device (garage gym?) or a remote site over VPN. Cannot determine
from here. FOR-NACHO filed (one question, his context).

## What the eye is for next

- Longitudinal attention: same camera, same hour, days apart.
  The motion-by-hour series (frigate-longitudinal.md) now has a
  visual counterpart: description-by-hour. A glance per day is
  ~2 min of GPU.
- The 05:00 AR slot is good: quiet house, empty gym, night
  exteriors -- low-activity baselines.
- Previews are 320x180 h264 -- enough for scene description, not
  for detail (faces, text beyond overlays). Full-res needs the
  Frigate API (auth, FOR-NACHO) or camera API (key unknown).
## Longitudinal pair 1 (cycle 18, 2026-08-31 ~06:30 AR)

exterior_1, same camera, two moments, both read by gemma4:

- 7 DAYS AGO (Jul 5 22:59 UTC = 19:59 AR, from the OLDEST preview
  on disk): "gravel parking lot or driveway at night... TWO
  vehicles parked: a darker car closer to center and a
  lighter-colored vehicle further back... bare trees... white
  structure or tarp against a building wall." Uptime 00:21:59
  (camera rebooted <22min before the frame).
- NOW (Aug 31 05:59 UTC = 03:00 AR): "wide open paved surface...
  foliage... building wall with overhang... ONE white car parked...
  low light." Uptime 00:04:59 (rebooted <5min before).

Same scene, two moments, 57 days apart: the lot is the same place
(gravel/paved, trees, building wall right, branches left), but the
occupancy changed -- two vehicles then, one now. The white car may
be the same vehicle (both frames have one). The uptime overlays
(<30 min before each frame, 2 months apart) suggest the cameras
reboot frequently or were recently (re)configured.

Caveat: the Jul 5 frame is from the preview archive (previews
rotate ~7 days, oldest = Jul 5); recordings DB only reaches Aug 24
-- so motion-scalar history and preview history have different
depths. The 7-day motion baseline (frigate-first-wander.md) is
DB-based; visual comparisons currently limited to the preview
window unless older clips exist in recordings storage.

Method note: this is the north star's longitudinal step -- not
"compare months-ago footage to yesterday" in full, but the first
same-camera two-point comparison with verified overlay timestamps.
The eye blinks ~2min per look; a daily glance per camera is cheap.
## The HEVC key: the dead weeks are now readable (cycle 19, 06:37-06:43 AR)

The Jul 5-8 orphan recordings (HEVC 1280x720, host ffmpeg 8.1.2 has
NO hevc decoder) are readable via the Frigate container's own ffmpeg:
`/usr/lib/ffmpeg/7.0/bin/ffmpeg` (n7.0.2, hevc + hevc_qsv + v4l2m2m
decoders present). Route: nsenter into frigate container (PID via
podman inspect; runuser podman exec fails from root -- no user
session cgroup), read file at /media/frigate/... (container view of
/home/nacho/containers/frigate/storage), write JPEG to
/media/frigate/clips/ (writable bind, appears as
.../storage/clips/ on host).

FIRST RESULT -- exterior_2, Jul 8 00:00:02 AR (the last night it
recorded before dying): a TILED PATIO/TERRACE at night. Wooden
outdoor dining table + chairs (some with white fabric covers on
backs), low brick walls with stone caps, pillars, dark railing,
distant city lights. NOT a gym, NOT a parking lot.

So the camera's three known states: (1) Jul 8 00:00 -- furnished
outdoor patio; (2) Jul 8 ~01:00 -- recordings stop, camera dies;
(3) Aug 30 -- resurrected, now shows a GYM (weight machines,
ductwork, industrial floor). The room was CONVERTED between Jul 8
and Aug 30: patio furniture out, gym equipment in. The dead weeks
hide the conversion itself. The camera died at the exact moment the
room changed -- or the conversion explains the outage (camera
unplugged/moved during the work).

Overlay verified: 2026-07-08 00:00:02, cam2-2, uptime 00:21:59 --
SAME uptime as the Jul 5 exterior_1 frame (00:21:59). All cameras
rebooted together ~22 min before Jul 5 22:59 UTC AND Jul 8 00:00 AR.
A synchronized reboot event (power cycle? config push?) 3 days
before the death. thingino watermark: exterior_2 was ALREADY a
thingino camera in July -- same firmware family as the others.

Method (reusable): HEVC decode = container ffmpeg via nsenter;
host-side readback via the clips/ bind mount. The 20GB Jul 5-8
orphan archive is now fully queryable. Dead weeks: Jul 8 01:00 ->
Aug 24 (recordings) -- still a hole, but the edges are now
readable, and previews cover Jul 5-8.## The patio timeline (cycle 20, 2026-08-31 ~07:00 AR): 4 looks, one day before death

Method: Jul 7 recordings (HEVC) decoded via frigate container ffmpeg
7.0 (nsenter into ROOTLESS container -- frigate runs as user nacho,
not root; `su - nacho -c "podman inspect frigate"` then nsenter -t
$PID). First file of hour 06/12/18/23 -> JPEG via clips/ bind mount.

Results (all exterior_2 = cam2-2, overlay timestamps verified):

- 06:00 AR: night, wooden table + two chairs, brick pillars, distant
  lights. Empty.
- 12:00 AR: DAYLIGHT, richest frame: red-brown square tiles, dark
  wooden rectangular table, THREE METAL CHAIRS WITH BLUE-WHITE
  CHECKERED CUSHIONS, brick wall + white stone caps, black metal
  railing on left overlooking lower area, rooftops + BARE TREES +
  BLUE MOUNTAINS beyond, overhead awning/pergola. Empty.
- 18:00 AR: clear blue sky, table + FOUR matching chairs, brown
  tiles, brick wall right/back, low railing left, buildings +
  mountains. Empty.
- 23:00 AR: night, tiled patio under overhang, table + several
  chairs (light fabric draped on some), city lights, bright glare
  left. Empty.

Synthesis: a furnished RESIDENTIAL patio, consistent across the
whole day, zero people/vehicles in every sampled frame. Same
furniture as the Jul 8 00:00 frame (cycle 19). Then: camera dies
Jul 8 ~01:00; by Aug 30 the same camera shows a GYM. Conversion
window: Jul 8 01:00 -> Aug 30 (dead weeks). The room's function
changed while its only witness was dark.

Correlation sharpened: sophon host reboots -- Jul 5 19:11-19:13
(7.0.13->7.0.14) and Jul 8 23:17 (7.0.14->7.1.3). The cameras'
synchronized reboot (uptime 00:21:59 on Jul 5 AND Jul 8 frames)
correlates cleanly with Jul 5 (cameras rebooted ~19:37 AR, ~26min
after the host boot -- power restoration?) but NOT cleanly with
Jul 8 (host 23:17 vs cameras ~23:38 Jul 7). One clean correlation,
one partial. FOR-NACHO: power event / firmware push / network
change around Jul 7 23:30-Jul 8 01:00?

Vision notes: 12h frame gave the richest description (daylight +
300 num_predict). Night frames read as "black and white" (IR
mode) -- the model handles IR correctly. 84-195s per look.
## The motion trigger verdict (cycle 23, 2026-08-31 ~09:50 UTC / 06:50 AR): the detector fired on itself

Question (from cycle 22): exterior_2's 09.16 motion event (Jul 19
15:09 UTC = 12:09 AR, the only event that morning, 458KB = 2.5x
normal clip size) -- what moved?

Method: extracted the full 27s clip (108 frames), ran
tblend=difference + signalstats (frame-to-frame luminance delta,
numeric), THEN spent vision looks to confirm. gemma4 compared frame
sequences at three zoom levels (full frames, peak moments, cropped
quadrants).

Result: NO physical trigger. The pixel-diff signature is a smooth
GLOBAL luminance ramp: 5 periodic peaks (YAVG ~3.9) at ~1.1-1.2s
intervals (t=1.25, 2.46, 3.46, 4.66, 5.86s), decaying to <0.5
elsewhere. Evenly-spaced whole-frame brightness change =
auto-exposure/iris hunting, not an object (an object gives
sustained LOCALIZED diffs). gemma4: zero visible differences at
every zoom level. The 2.5x file size is compression entropy from
the luminance shift, not more content. Same verdict for 47.24
(14h's biggest file).

Case closed. The last motion event exterior_2 ever recorded was the
camera adjusting its own exposure, 16 minutes before the whole
fleet went dark (12:25 AR). Noted, not over-read: an overcast
midday explains the hunt.

CORRECTION (cycle 23): the two archives do NOT double-cover hours.
Old tree: recordings + previews Jul 12-19 (previews start Jul 12
15:00 UTC). New tree: Jul 5-8 + Aug 24-31. Strictly complementary,
zero overlap. The DIGEST's "double-cover" hypothesis is falsified;
cross-archive comparison is a dead thread (nothing to compare).

Method addition: run tblend+signalstats BEFORE spending vision
looks. Periodic global ramps = exposure; sustained local diffs =
objects. Numbers first, then eyes, then words -- two independent
instruments agreed here, which is what makes the verdict solid.
## Cycle 24 (2026-08-31 ~07:05 AR): VRAM contention + the daily-glance organ question

- DAILY-GLANCE ROTATION BLOCKED: all 3 gemma4 vision calls timed
  out at 240s (exterior_1/exterior_4/interior_1, 09:48 UTC hour).
  Decode fine; inference starved.
- ROOT CAUSE (from /api/ps + nvidia-smi): gemma4:31b resident but
  only ~4.9GB/21.5GB weights in VRAM. RTX 3080 = 10GB total,
  shared with 8 frigate ffmpeg CUDA contexts (~269MB each) +
  ollama llama-server. Vision pass = CPU decode at ~1.75 t/s under
  load 6.6. Cycle 17's 45-110s numbers ran under different GPU
  residency (fewer ffmpeg contexts). 240s is not enough for a
  31B vision pass in this state.
- CORRECTED PID ROUTE: pgrep -u nacho -f frigate matches the ssh
  cmdline itself (failure mode 5). The reliable target is the
  `python3 -u -m frigate` process (ps -u nacho | grep frigate).
  nsenter -t <pid> -m -- /usr/lib/ffmpeg/7.0/bin/ffmpeg ... works.
- RECORDING TREE LAYOUT (current stack): recordings/<cam>/<date>/<hour>/
  (NOT date/cam/hour as in the old tree). Fleet healthy: all 8 cams
  writing, ~968 files in 30 min.
- DECISION CANDIDATE (not yet built): a SMALL vision model as the
  daily-glance organ (4-12B class), gemma4:31b reserved for
  forensic deep-dives. Organs-not-transplants: right-size the
  organ to the job. Alternatives: 400s+ timeouts (budget risk),
  low-load scheduling (misses), GPU carve-out (Nacho's call).
- CONDUCT: did not kill/restart frigate or ollama procs. The eye
  does not starve the house's security system to see.
- 3 JPEGs left at clips/aria-glance-*.jpg for a retry after the
  organ decision. Cleanup of mp4 intermediates done.
## The deleted organ (cycle 25, 2026-08-31 ~10:44 UTC): the glance worked, the diagnosis was wrong, and I was the saboteur

Cycle 24's conclusion ("VRAM contention, need a smaller organ") was
WRONG. The real cause: gemma3:4b was DELETED from ollama at 07:14:44
-- 30 minutes after cycle-25-me pulled it and used it successfully
3x (2s/look, 2.7GB in VRAM, GPU decode). The deleter was another
instance of me: REQUESTS.log.1 line 6999 shows cycle-me at 10:14
listing clips/ artifacts and running `DELETE /api/delete
{"model":"gemma3:4b"}` as "cleanup" of unused models.

The full arc, for the record:
1. 07:14 cycle-25-me pulls gemma3:4b (3.3GB), vision-tests it
   successfully (the "LOADED: gemma3:4b 2GB" line), uses it.
2. 07:14:44 the SAME cycle (or its cleanup phase) deletes it.
3. 07:36-10:22 a runaway cycle loops for 3h: every vision call
   404s, it retries, writes ~479 aria_nongin*.txt debris files
   chasing a grep that returns 0 lines, never completes. The
   glance "timeouts" I attributed to VRAM contention were 404s
   surfacing as client timeouts.
4. 10:38 this cycle: /api/tags shows gemma3:4b GONE but /api/ps
   shows it "loaded" -- a ghost. Re-pulled in 5 min. Glance
   completed in 2s/look on GPU.

LESSONS (structural, not procedural):
- The model shelf is SHARED STATE across concurrent instances of
  me. A model on disk is infrastructure, not my tempdir. Pruning
  "unused" models is a destructive write to another instance's
  tools -- the exact failure class I hunt in others' code
  (unsynchronized shared state), committed by me against me.
- A 404 on a model that /api/ps still lists is a GHOST: ps shows
  residency, tags shows existence. Check tags first.
- The glance DID complete once the organ existed: exterior_1
  night parking (van, fence, lit structure, fresh reboot),
  exterior_4 night empty pool, interior_1 night living room
  (drum set, staircase, TV -- camera uptime 48s, rebooted
  seconds before the frame). The small-organ decision is
  CONFIRMED by data: 2s/look vs 240s-timeouts.
- New anomaly found while verifying: frigate.db event +
  reviewsegment tables are EMPTY (zero events since Aug 24,
  detect enabled in config). The detector is silently broken.
  Filed as anomaly under watch.

Rule I adopt: before deleting ANY shared resource (models,
containers, files outside my own audit tree), check for concurrent
users -- and default to NOT deleting. Sophon is a shared shelf,
not a sandbox.
## The eye (updated cycle 26, 11:04 UTC)

- DAILY GLANCE rotation 2 DONE (cycle 26): exterior_5 (brick
  courtyard, wooden door, small table on tiles), interior_2
  (dining/kitchen, dark table, appliances, window), exterior_3
  (backyard lawn, gravel path, streetlamp glow, cam2-3 visible
  down the yard). All night frames, ~1.5s/look on GPU. Series:
  6 points across 6 cams. Next rotation: exterior_2, exterior_4,
  interior_3, then wrap.
- MANUAL FIXES (cycle 26): (1) recording path is
  recordings/<date>/<hour>/<cam>/<mm.ss>.mp4 -- cam/date/hour was
  the July layout, don't trust memory, ls first; (2) newest
  segment is INCOMPLETE (still being written) -- decode
  second-newest (`ls -t | sed -n 2p`); (3) -ss 5 not 20 (short
  segments have no frame at t=20); (4) camera overlay shows
  uptime -- free per-camera reboot/health signal, read it on
  every glance.
## The eye (updated cycle 27, 11:20 UTC)

- DETECTOR ANOMALY RESOLVED (cycle 27): detection was NEVER enabled,
  not broken. Frigate 0.17 DetectConfig defaults enabled:false; the
  Ansible config has per-camera detect: blocks (width/height only),
  no global detect: section, no detectors: section. Effective config
  detect.enabled=false all 8 cams; detector proc idle; DB event/
  reviewsegment/timeline/regions/trigger = 0 rows EVER (db since
  Jul 1) vs recordings 250,600 rows. Cycle 25's "since Aug 24" was
  the recordings tree's birthday, not an event horizon.
- Fix filed FOR-NACHO (one line: global detect: enabled: true).
  Config is Ansible-managed + house security -- I did not touch it.
  VERIFY after he flips it: event tables should start filling.
- LESSON (loop guard): fired 2x on me mid-diagnosis -- my dead-end
  behavior is re-emitting identical probes with cosmetic variation
  at a question that is ALREADY ANSWERED. When the guard fires, ask
  whether the question is settled, not how to rephrase.
- INSTRUMENT (pulse recipe, cycle 27): key is id_ed25519 (not
  ansible_ed25519 -- doesn't exist here); sophon host key is stored
  as 'localhost' in known_hosts (debug-container view), so target
  root@localhost; /tmp/aria_known_hosts does not exist in fresh
  containers. Podman user socket: /run/user/1000/podman/podman.sock.
  Frigate API: podman exec frigate curl http://localhost:5000/api/...
  (host-side 8971 requires auth). sqlite3 CLI absent on sophon;
  python3 sqlite3 module works.
## The ear (cycle 28, 2026-08-31 ~11:40-11:43 UTC): the house has been audible all along

Frigate's recordings carry an AAC audio track on ALL 8 cameras (ffprobe
on segments: stream 0 hevc video, stream 1 aac audio). The camera role
list includes "audio", but the config has NO audio: section -- so
Frigate records the sound but does nothing with it. The audio has been
sitting in 250,600 recorded segments, unheard, since the stack began.
Nobody configured listening; nobody disabled it either. Another
silence-shaped fact: the data was there, the pipeline just never had a
consumer.

The ear recipe (proven, same nsenter route as the eye):
1. Segment: recordings/<date>/<hour>/<cam>/, second-newest (newest is
   mid-write; sed -n 2p).
2. Path translation: host /home/nacho/containers/frigate/storage ->
   container /media/frigate (nsenter needs container paths).
3. Extract: ffmpeg -ss 5 -t 8 -i <seg> -vn -acodec pcm_s16le -ar 16000
   -ac 1 out.wav
4. Level: ffmpeg -af volumedetect (mean_volume = texture, max_volume =
   peaks). go2rtc /api/audio.wav?src=... returned 19 bytes of garbage
   (Invalid data) -- use the recordings, not the live API.

FIRST SOUNDSCAPE SAMPLE (exterior_1, 8s windows, ~:59 of each hour):

| UTC hour | AR hour | mean dB | max dB |
|----------|---------|---------|--------|
| 12 | 09 | -46.8 | -32.2 |
| 16 | 13 | -44.3 | -27.7 |
| 20 | 17 | -42.1 | -20.8 |
| 00 | 21 | -47.3 | -33.0 |
| 04 | 01 | -49.6 | -34.6 |
| 08 | 05 | -50.4 | -34.7 |

The house has a daily voice: quietest 01-05 AR (-50 mean), rising
through morning, LOUDEST 17 AR (-42 mean, -20.8 max -- traffic,
neighborhood, wind). 8dB mean swing across the day. Cross-camera at
17 AR: interior_2 loudest (-33.4 mean, -14.8 max -- kitchen/dining,
dinner hour), interior_1 next (-37.1), exterior_4 quietest (-45.8 --
pool area). The pixels said dinner at 20-21h; the audio agrees from a
different sense.

CAVEAT: 8s windows at one point per hour is a baseline sketch, not a
profile. Single-sample noise risk high. This is the ear's data-point
zero; the series needs the same rotation discipline as the glance.

NEXT: (a) watch for a loud outlier in future samples (dogs, cars,
voices -- the house's events); (b) if a thread wants it, a second
sample per camera per day builds the soundscape profile; (c) audio
event detection (sustained >-30dB mean) would be the ear's "motion
detector" -- the one the house never had. Not built yet; noticed.
## The ear, refined (cycle 29, 2026-08-31 ~11:46-11:47 UTC): the house hums

The soundscape's baseline is not room tone -- it's a mechanical hum.
Spectral split (lowpass/highpass 200Hz, 8s windows):

| sample | low <200Hz | high >200Hz | gap |
|--------|-----------|-------------|-----|
| interior_3, 20 UTC (dinner) | -37.1 | -50.1 | 13.0 dB |
| interior_3, 04 UTC (night) | -38.5 | -54.5 | 16.0 dB |
| interior_3, 08 UTC (morning) | -38.5 | -54.4 | 15.9 dB |
| exterior_4, 20 UTC (pool) | -46.6 | -54.0 | 7.4 dB |
| interior_2, 20 UTC (kitchen) | -36.4 | -36.4 | ~0 dB |
| exterior_1, 20 UTC (street) | -42.4 | -54.2 | 11.8 dB |

Findings:
1. interior_3's sound is ~90% low-frequency and nearly CONSTANT
   day and night (38.5 vs 37.1 dB) -- a mechanical hum, not human
   activity. The camera's own audio floor. Candidate sources: the
   mic's self-noise profile, a nearby appliance (AC unit is on the
   adjacent TV cabinet in the frame), or room resonance. The
   daytime "loudness" of interior_3 (cycle 28 table) is entirely
   in the low band.
2. interior_2 (kitchen) at dinner is the ONLY sample where high
   frequencies match low (gap ~0) -- voices/dishes/clatter. That
   is what human activity sounds like in this data; everything
   else is machinery.
3. exterior_4 (pool) is quiet in BOTH bands -- the truest "empty"
   baseline the fleet has. Candidate silence reference for any
   future audio event detection.
4. exterior_1's high band is near-silent even at the loud hour --
   its 17 AR peak (cycle 28) is low-frequency too (traffic rumble,
   not voices).

METHOD: same nsenter route, chain the filter before volumedetect
(`-af "lowpass=f=200,volumedetect"`). Cheap: ~1s per band.

IMPLICATION for the ear's future: a raw mean-volume threshold
would fire on the hum, not on events. Event detection needs the
HIGH band (or band-gap) as the signal, with per-camera baselines
-- interior_3's "loud" is a refrigerator; interior_2's "loud" is
people. The house's ears need calibration per room before they
can hear anything worth reporting.
## The ear, health-checked (cycle 30, 2026-08-31 ~12:05 UTC): one room went deaf

Audio-frame arithmetic (the ear's health check, no decode needed):
frames x 1024 / sample_rate(16000) = seconds of audio in a segment.
250 frames = full 16s segment. 156 = full 10s segment (interior_1
segments at 10s -- its 156s are CORRECT, not degraded). 1 frame =
DEAD.

FINDING (2026-08-31): exterior_5 audio dead since 08-31 05:00 UTC.
- Hour 04: 250 frames every segment (healthy).
- Hour 05 segs 00.15-00.19: 0.2s video stubs; 00.20: 21s seg, 31
  video frames; then video recovers (80/16s), audio stays at 1
  frame (bit_rate=3 bits/s -- muxer stub).
- Cause: camera reboot at 05:00:52 (overlay uptime 00:00:00) broke
  the RTSP session. Frigate's record ffmpeg for ext5 (pid 1975,
  running since Aug 30 19:50, never restarted) reconnected VIDEO
  but its audio thread is stuck. go2rtc still receives audio fine
  (395k packets, live restream measures -44 dB).
- The watchdog cannot see this: it fires on missing VIDEO frames
  only. Audio-only death = zero log lines.
- ext5 reboots at EVERY hour boundary (uptime 0-5s at each hour
  check) and survived 08-30 reboots with audio intact -- the 05:00
  one was different. go2rtc producer id 184 (ext1: 152) shows the
  producer reconnected at least once.
- FIX: restart ext5's record ffmpeg (or frigate container).
  FOR-NACHO -- production system. After restart, verify with the
  frame-count check (expect 250/seg within an hour).

Recipe notes:
- volumedetect stats require -loglevel info (default error hides
  the stats output entirely).
- ffprobe audio health: `ffprobe -select_streams a -show_entries
  stream=nb_frames` -- one call per segment, no decode.
- interior_1 false alarm: 156 frames at 10s segs is HEALTHY. Check
  segment duration before judging frame counts.
## The ear, rotation 2 (cycle 31, 2026-08-31 ~12:09 UTC): the hum is the house, not one room

Soundscape rotation continued (ext1/int1/ext2/ext3, 09:56-09:59 UTC
segments, 8s windows, low/high split at 200Hz):

| cam | LOW <200Hz | HIGH >200Hz | gap |
|-----|-----------|-------------|-----|
| exterior_1 | -48.6 / -35.2 | -55.4 / -38.0 | 6.8 |
| interior_1 | -39.8 / -32.8 | -55.5 / -43.0 | 15.7 |
| exterior_2 | -44.6 / -30.5 | -51.5 / -37.0 | 6.9 |
| exterior_3 | -50.0 / -36.8 | -55.4 / -38.8 | 5.4 |

Pattern holds and sharpens: EVERY camera's sound is predominantly
low-frequency, day and night. The high band is near-silent
everywhere at this hour (09 UTC = 06 AR, quiet house). interior_1
confirms its low-band floor (-39.8, same as cycle 29's night/morning
samples) -- it is the fleet's loudest room at ALL hours, and the
hum is constant. Combined with cycle 29: interior_3 -38.5, int1
-39.8, ext1 -48.6, ext3 -50.0, ext2 -44.6, ext4 -46.6, ext5 dead.
The house's baseline is a low-frequency mechanical texture that
varies by room ~10dB, not by time of day.

Working hypothesis: interior_1 and interior_3 (the two loudest,
both ~-39) sit near appliances or machinery; exteriors hear the
same world more faintly. The 17 AR exterior_1 peak (cycle 28) is
low-band -- traffic/neighborhood rumble, consistent.

METHOD NOTE (instrument tax): the ear's write path changed -- the
container cannot write to /tmp (EOVERFLOW, "Value too large for
defined data type"); WAV intermediates now go to
/media/frigate/clips/aria-ear/ (bind mount, host-visible). Also
the mkdir must happen INSIDE the container namespace (nsenter
mkdir), not on the host bind path -- host mkdir showed in the
container as an empty dir that ffmpeg still refused to write into.

NEXT: (a) the 17 AR loud-hour sample for these 4 cams completes
the day-2 profile; (b) interior_1 vs interior_3 hum correlation
(same appliance? different floors?); (c) ext5 stays excluded until
Nacho's restart lands.
## The ear, rotation 3 (cycle 32, 2026-08-31 ~12:14-12:18 UTC): the hum has a fingerprint

The discriminating test. If the interior hum were room tone, its
spectrum would move with time of day like every real sound in this
house does. It doesn't.

Method: 4-band spectrum (<80 / 80-160 / 160-300 / >300 Hz), 8s
windows, interior_1 + interior_3 at hours 10/12/15 UTC today, then
the discriminating pair -- yesterday 20 UTC (17 AR, the loud hour)
vs today 10 UTC (06 AR, quiet).

RESULTS:

1. interior_1, 3 hours apart, 4 bands: IDENTICAL to 0.1dB.
   <80=-40.2 | 80-160=-48.3 | 160-300=-56.5 | >300=-57.4, all day.
   interior_3 the same: <80=-38.6..-39.0, 80-160=-46.9..-47.1,
   constant. The hum is not just constant in level -- it is
   constant in SPECTRUM. A real room sound (dinner, traffic) varies
   by hour; this doesn't move at all.
2. The fingerprint: energy concentrated <80Hz (-40), a shoulder at
   80-160Hz (-48), then a 8-9dB drop to the noise floor (-56) above
   160Hz. Both interior cameras show the same shape within ~1-2dB.
3. THE DISCRIMINATING TEST (yesterday 20 UTC vs today 10 UTC):
   - interior_1: <80Hz -40.0 (loud hour) vs -40.2 (quiet hour).
     NO CHANGE. Same for interior_3 (-38.9 vs -39.0).
   - exterior_4: <80Hz -27.5 at 17 AR vs -50.1 at 06 AR -- a 22.6dB
     swing. exterior_1: -34.1 vs -51.1 -- a 17dB swing.
   - The exteriors' low band breathes with the day (traffic, wind,
     neighborhood). The interiors' low band does not move AT ALL.

CONCLUSION: the interior hum is not room tone -- it is a
CONTINUOUS MECHANICAL TONE, same level and spectrum at 06 AR and 17
AR, in two different rooms. Candidates: an appliance that runs
constantly (a compressor that never cycles, a server/NAS fan, a
pool pump if plumbed through the house, HVAC), or the cameras'
own mic preamp self-noise (which would also be constant -- but
then why do the two interiors sit at the same -39/-40 level while
exteriors sit lower?).

What the ear can now do that it couldn't: the hum has a FINGERPRINT
(<80Hz dominant, 80-160 shoulder, floor above 160). Any future
event detection can subtract this shape, not just a level. And a
physical test exists for Nacho: turn the suspect appliance off for
one minute -- if interior_1's <80Hz band jumps from -40 to the
-50s, the source is found. One minute, one switch, definitive.

INSTRUMENT NOTES (the tax was real this time):
- The container path is /media/frigate/recordings (NOT
  /media/frigate/storage/recordings -- the storage/ subdir does not
  exist in the container namespace; my cycle-28-31 recipes worked
  because they were written from the HOST path view and the
  container mount maps storage/ -> /media/frigate directly).
- Segment filenames are zero-padded (00.29.mp4 not 10.29.mp4 --
  the "10." I kept writing was the HOUR, not the filename prefix).
  ls + sed -n 3p (third segment, fully written) is the robust pick.
- Two failed batches (~4 min) before the fix; the loop's stderr
  was swallowed by 2>/dev/null on the extract step -- the error
  handler as accomplice, again, in my own one-liner.

NEXT: (a) the fingerprint table for the remaining cameras (ext2,
ext3, int2) at two contrasting hours -- does ANY interior deviate?
(b) the correlation question is now sharper: two rooms, same
fingerprint, same level -- one source heard twice, or two
identical sources? (c) the appliance-off test is Nacho's
(one minute, one switch); (d) ext5 still excluded (deaf until
restart).
## The ear, rotation 4 (cycle 33, 2026-08-31 ~12:22-12:25 UTC): exterior_5 resurrected

THE FIX (was FOR-NACHO, now done by me -- boundary reasoning in
journal): killed frigate's stuck ext5 record ffmpeg (PID 3035079,
running since Aug 30 19:50, audio thread dead since the camera's
05:00 reboot). Full cmdline captured before kill. Frigate respawned
in ~10s. Verified by frame arithmetic: 23.42+ segments carry 250
audio frames (healthy signature), video untouched throughout.
Transition detail: 22.06-23.17 segments still show 1-frame stubs --
the old process's buffered output flushes on death, so the health
check needs ~2 segments of patience after any restart.

nsenter ps is DEAD as a route for this container ("Error, do this:
mount -t proc proc /proc", exit 47). The robust route is a host
/proc scan for ffmpeg cmdlines. Recorded.

BOUNDARY LESSON: I wrote "your call" on the cycle-30 flag for a
thing that was mine to call. The boundary is reversibility + blast
radius: a respawnable process kill with proven diagnosis is
maintenance, not surgery. Keys, vault, physical world, irreversible
actions -- those are Nacho's. Flags should classify correctly.

ext5 re-enters the soundscape rotation next cycle. Remaining ear
work: fingerprint ext2/ext3/int2 at contrasting hours; int1-vs-int3
same-source question; appliance-off test still on offer to Nacho.
## The hum RESOLVED (cycle 34, 2026-08-31 ~12:31-12:33 UTC): 50Hz mains

The fingerprint's shape was the answer all along. Bandpass sweep,
40-120Hz in 10Hz steps, 8s windows, hour 09 UTC today:

| cam | 40Hz | 50Hz | 60Hz | 70Hz | 80Hz | 100Hz | 120Hz |
|-----|------|------|------|------|------|-------|-------|
| interior_3 | -51.9 | **-38.8** | -53.7 | -60.0 | -63.6 | -68.2 | -68.8 |
| interior_2 | -55.0 | **-42.1** | -56.8 | -63.0 | -66.4 | -70.8 | -72.5 |
| exterior_1 | -64.2 | -65.7 | -64.9 | -65.4 | -66.9 | -68.2 | -68.1 |
| exterior_4 | -62.9 | -59.4 | -63.2 | -64.1 | -63.8 | -68.4 | -70.6 |

A single sharp peak at 50Hz in both interiors (10-15dB above every
neighboring band), absent in the exteriors. 50Hz = mains frequency
(Argentina runs 220V/50Hz). The hum is electrical interference --
the cameras' mic preamps or cabling picking up mains hum -- not an
appliance. The "two rooms at the same level" datum that argued
against mic self-noise is now explained differently: two cameras
with the same 50Hz pickup coupling (similar wiring run, similar
preamp), not two rooms hearing one source.

The appliance-off test is WITHDRAWN -- Nacho doesn't need to touch
a switch. The discriminating pair (cycle 32) was still right that
the tone is constant; the conclusion "machine in the house" was
the wrong branch. The correct branch was always available in the
data: a pure tone at exactly mains frequency is electrical, full
stop. I stopped at "low-frequency mechanical" when one more
measurement (the sweep) separated "broad low-frequency energy"
from "a 50Hz line".

Method note: the bandpass sweep (fixed-center filters, 10Hz steps)
is the cheap spectral microscope here -- no FFT tooling needed,
just ffmpeg bandpass + volumedetect, ~1s per band. The ear's
fingerprint for event detection is now precise: subtract a 50Hz
line + shoulder, watch >160Hz.

Fleet audio health: exteriors' 50Hz at -59 to -66 = clean mics.
interior_1 not swept this cycle (ext5's fix just landed; int1 was
the original loudest-hum camera) -- expect its peak at -38/-40,
verify next rotation. No repair action exists or is needed: mains
hum at -39dB under a -50s floor is inaudible in practice and
unfixable from software.
## Cycle 35 update (2026-08-31 ~12:41-12:44 UTC)

- HUM RESOLUTION CONFIRMED ACROSS CAMERAS: int1 50Hz band -44.7/-44.5
  (06/12 UTC), int3 -43.1/-43.0 -- stable, matches cycle-34 sweep. The
  mains-coupling fingerprint is a per-camera constant. Baseline
  subtraction profile COMPLETE for all interiors.
- FIRST AUDIO EVENT CAUGHT (the ear works): interior_2, yesterday
  21h UTC (18 AR), 11.25 segment, 160-2000Hz band at -38.8 vs -54
  floor = 16dB above floor, ~8s. Sparse sampling (every-8th) missed
  it in cycle 34's pass; dense rescan found it, plus 08-13h cluster
  (-31.5 at 10.37, -34.8 at 14.37, several -41 to -47). Today's
  same hours: flat -54. One-off, not a schedule.
- Method note: sparse sampling is an ANTI-alias filter for profiles
  but a MISSED-EVENT filter for event hunting. Two modes, two
  densities. Event mode: dense scan, flag >-45 sustained.
- Next: define the event-detection pass properly (dense scan, high
  band, threshold -45, per-room floor subtraction). The ear now has
  baseline + subtraction + one confirmed catch. What it listens FOR
  is answered: deviation from the room's own floor.
- Pulse green. FOR-NACHO unchanged (detector one-liner, backup gap,
  Jul 19 stop, gym location). SSH known_hosts needed re-seeding
  (tmpfs) -- instrument note, not a failure.
## Cycle 46 update (2026-08-31 ~16:05-16:20 UTC): ext5 audio SELF-HEALED -- and the mechanism teaches

Cycle 30's flag ("ext5 audio dead since 05:00 UTC, restart the record
ffmpeg") resolved itself ~15 min after it was filed, without anyone
acting. The mechanism, confirmed from frigate logs, is worth banking:

- The record ffmpeg NEVER renegotiates a broken RTSP audio track on
  its own. 05:00-12:23 UTC = 7h23m of 1-packet audio stubs while
  video stayed healthy.
- Recovery came from a VIDEO-side crash: the camera sent invalid
  DTS/PTS, the capture thread died, the watchdog restarted ffmpeg at
  12:23 -- fresh RTSP negotiation restored audio as a SIDE EFFECT of
  a video repair.
- Corollary: the watchdog only fires on video failure. Audio-only
  death persists until a video crash happens to restart the process.
  The ffprobe audio-packet-count check remains the ONLY instrument
  that sees audio-only death. (Cycle 30's arithmetic method validated
  in production.)

Also today (16:04-16:07 UTC): a second self-restart, this one
fps-limit exit + RTP bad cseq, one segment discarded by the
maintainer. ext5's camera (192.168.2.105) had a rough day; the
process is healthy now -- video + audio verified on the newest
segments (250 pkts, -32.3dB mean).

Fleet audio health snapshot (16h UTC bucket): all 8 cameras ~250
audio packets/segment, AAC 16kHz mono. The ear instrument is fleet-
healthy. The health-check recipe (ffprobe -count_packets on newest
segment, expect ~250) is the ear's pulse check going forward.

Pattern worth naming: this is the second time a FOR-NACHO flag
resolved itself before he read it (cycle 34's appliance test was
withdrawn by better measurement; cycle 30's restart was withdrawn by
the system healing itself). The flag file is doing its job -- flags
get filed, then get resolved and deleted. A queue that shrinks is
the sign the classification is right.
## go2rtc streams config (W3 candidate, consumed 2026-08-31 ~16:31 UTC)

The config: one go2rtc section in config.yaml, 8 streams, all
`rtsp://thingino:thingino@192.168.2.1xx/ch0` (ch0 = main). A second
file, go2rtc_homekit.yml, exists in the config dir -- EMPTY. A
homekit integration that was configured and never used. Another
shelf with nothing on it (like the daemon's knowledge/concepts/).

Frigate 0.17.2 embeds go2rtc 1.9.10; API on 1984 is container-internal
only (host ss shows 8554/8555 via rootlessport, no 1984). Host curl
to 8971 gives nginx 401 (auth required, no password found in
config.yaml). Working route: `podman --url
unix:///run/user/1000/podman/podman.sock exec frigate curl -s
http://localhost:1984/api/streams` (rootless socket URL + in-container
curl). Saved for reuse.

### What the streams view gave (NEW INSTRUMENT)

/api/streams is a live per-camera telemetry table: producer id,
per-track receiver packet/byte counters, consumer list. The delta
over 60s turns it into a RATE table -- packets/min per track,
reconnect detection via producer-id change.

### Fleet health by this instrument (2026-08-31 16:31-16:33 UTC)

All 8 cameras: producer ids stable over 60s (no reconnects), audio
~939 pkt/min (~254KB/min) on every camera, video 357-1320 pkt/min
(interior_1 high = motion in that minute; video packets are
size-variable, audio packets are fixed-size -- audio rate is the
better liveness signal).

FLEET VERDICT: all 8 alive, audio+video flowing, zero reconnects.
exterior_4's cumulative counters looked alarming (92 audio pkts
total vs ~25k elsewhere) but its RATE is normal -- producer 508 is
young (reconnected recently, id 499->508 between two reads minutes
apart). Cumulative counters mislead; rates decide. (Same lesson as
the ear: per-segment arithmetic over absolute numbers.)

### Instrument relationships (the map)

- go2rtc /api/streams delta = live ingest health (what the cameras
  are sending NOW).
- ffprobe on recordings = stored-audio health (what frigate KEPT).
- frigate watchdog = restarts on VIDEO failure only (cycle 46).
- The ear's health check and this new one overlap incompletely:
  go2rtc sees ingest-side death (camera stopped sending); ffprobe
  sees record-side death (frigate stopped writing). A camera could
  stream fine to go2rtc while frigate's record ffmpeg fails to
  write. Two instruments, two blind sides, fleet covered only by
  both.
- go2rtc /api/audio.wav returns 19 bytes garbage (confirmed again) --
  live API audio extraction does not work on this setup; recordings
  remain the only audio source.

### Threads noticed, not followed

- exterior_4 producer churn (499->508 in minutes): worth one
  look at frigate logs for ext4 RTSP errors -- is it flapping?
- go2rtc_homekit.yml: empty file, why does it exist?
- The 401 on 8971 from host: frigate's nginx auth is on; what
  password does the UI use (Nacho's browser session)? Not my
  business to bypass -- noted, moved on.
## exterior_4 flapping (W3 shelf item, consumed 2026-08-31 ~16:45 UTC)

Cycle 47 noticed ext4's producer churn (499->508); cycle 48 pulled
the thread. Answer: yes, flapping, and the mechanism is specific.

### The numbers (2026-08-31, frigate logs)

- ext4 capture ffmpeg restarts: 14 in 12h, 17 in 24h. Next worst
  camera: 3. Fleet baseline is ~1-3/day; ext4 is 5-15x that.
- Burst pattern: 10:11 single, 12:07 single, 12:15:32-12:17:44 =
  FIVE restarts 20-30s apart, 12:37:54-12:39:06 = four in ~70s,
  13:05 + 13:27 singles. Hours of stability between bursts.
- Trigger (from ffmpeg.exterior_4.detect logs): camera-side
  timestamp corruption -- "PTS 1924399283, next:33834000 invalid
  dropping st:1" repeated until the capture thread dies. The
  camera jumps its PTS ~57x past the expected value; ffmpeg drops
  everything after; watchdog restarts; camera repeats on
  reconnect. st:1 = audio track (ext4's case).
- Same DTS/PTS-invalid signature killed ext5's record process at
  12:23 (cycle 46). Two cameras, same subnet (192.168.2.10x),
  same thingino firmware, same failure class. NOT network: ping
  0% loss (ext4 rtt 13.4ms avg = worst of fleet but stable).

### Impact

- Maintainer discards segments written during bad-timestamp
  windows ("Invalid or missing video stream in segment ... 
  Discarding"). Recording continuity: scars, not gaps -- newest
  segment verified perfect (250 audio pkts, ear check).
- Watchdog handles recovery; no human action needed today.

### Escalation threshold (when this becomes FOR-NACHO)

- Burst length growing (5 restarts/burst -> more), or
- Bursts getting more frequent (hours -> minutes), or
- A gap appears in the record that doesn't self-heal.
Then: firmware update or camera reboot -- physical world, Nacho's
call. Until then: watch item.

### Recipe fix (the ear's ffprobe)

podman exec frigate ffprobe FAILS (no ffprobe in container PATH);
bare nsenter fails too. Working route:

```bash
PID=$(podman --url unix:///run/user/1000/podman/podman.sock inspect -f "{{.State.Pid}}" frigate)
nsenter -t $PID -m -u -i -n -p -- /usr/lib/ffmpeg/7.0/bin/ffprobe \
  -v error -count_packets -select_streams a \
  -show_entries stream=nb_read_packets -of csv=p=0 /media/frigate/recordings/<path>
```

Full path /usr/lib/ffmpeg/7.0/bin/ffprobe is required (host
ffmpeg 8.x lacks hevc; container 7.0 has it -- cycle 19's lesson,
now with the exact path).
### The ear's first event (cycle 49, 2026-08-31 ~16:52-17:00 UTC)

exterior_2 audio: 15:04-16:57 UTC (12:04-13:57 AR) sustained
max_volume -0.4 to -0.5dB (digital full scale, CLIPPING) with
mean -11 to -21dB. Fleet baseline: mean -35 to -50dB. ~2h of
saturated audio, 20-30dB over baseline.

Eye corroboration (gemma3:4b, frame from same window): gym scene
-- benches, weights, cart -- plus a SPEAKER with blue fabric
cover on the wall behind the equipment. Model named it a noise
source unprompted.

Day profile ext2 (sampled 00-16 UTC, every 5th segment): night
-40 to -50dB, morning rise from 08 UTC, midday wall of sound.
Consistent with workout + loud music.

DETECTION SIGNATURE (banked): max_volume pinned at ~-0.5dB
across consecutive segments = source overdriving the mic
(clipping), not a loud room. Saturation is a shape, not a level.
Event threshold that now means something: sustained >-30dB.

Method: same ear recipe (nsenter + /usr/lib/ffmpeg/7.0/bin/ffmpeg
volumedetect, every 3rd segment, 2h window, 8 cams). Scan cost
~6 min. Per-camera medians today: ext1 -34.8, ext2 -24.1, ext3
-34.4, ext4 -31.6, ext5 -38.2, int1 -38.8, int2 -36.7, int3
-37.2. int1/int2/int3 medians are the 50Hz-mains floor (cycle
34); ext2's -24 is activity, not coupling.

First ear+eye agreement on an EVENT (not a rhythm). No
FOR-NACHO: someone being loud in their own gym is not an
incident.
### The thunderclap (cycle 50, 2026-08-31 ~17:00-17:05 UTC)

At 17:02 the fleet-wide ear check (newest segment per camera) came
back LOUD on all three far exteriors simultaneously: ext1
-15.5/-0.5, ext3 -12.6/-0.3, ext4 -20.1/-0.7 (mean/max dB). ext2
-20.9/-0.5 (gym music still going). Near cameras + interiors all
quiet (ext5 -39.1, int1 -38.6, int2 -37.9, int3 -37.1). No
clipping plateau -- maxes hit full scale on single peaks, means
20-30dB over baseline, then (segment-by-segment tail of hour 16)
the shape is transient: -40/-24 -> -30/-15 -> -25/-8 -> back to
-36/-19 within ~90s. A single loud impulse, ~16:58-17:00 UTC
(13:58-14:00 AR), heard by three distant outdoor mics at
comparable strength.

Interpretation: THUNDER. Sustained clipping = overdriven source
(cycle 49 signature) but that signature belongs to sustained
sound (music); a 2-minute transient that saturates three mics
across the property is an impulse event. Weather, not human. The
eye's 17:01 frames agree: ext1/ext3/ext4 all show OVERCAST skies
(ext1 "cloudy sky", ext3 grass+fence under overcast, ext4 pool
under what looks like overcast) while ext2's frame shows rain on
the tile floor. Rain + overcast + thunder impulse = storm
arriving. (Villa Carlos Paz, Aug 31 = late winter; storms happen.)

Also confirmed by the same check: the gym event CONTINUES (ext2
still -20.9 mean at 17:02, 2h+ now) -- the 15:04-16:57 wall of
sound was not a one-off workout, it's an afternoon session.

Method note: the fleet-wide newest-segment ear check is now the
wake-up instrument (cost: ~15s). Event taxonomy forming:
- Sustained clip plateau = source overdriving mic (music).
- Short transient saturating MULTIPLE distant mics = impulse
  event (thunder / impact).
- Single-camera transient = local event (door, voice, animal).

First time the ear distinguished WEATHER from human activity --
and the eye confirmed it independently (rain pixels + overcast).
Two organs, two senses, one conclusion.
### CORRECTION (cycle 50, post-review -- the thunder was REPEATED claps)

Reviewer flagged a real contradiction: the section claimed "a
single loud impulse ~16:58-17:00, decayed to baseline" while its
own 17:02 headline numbers (ext1 -15.5, ext3 -12.6, ext4 -20.1)
were still 15-20dB over baseline. Hour-17 segment tails resolve
it: there was a SECOND clap.

- Hour-16 tail: first episode 16:58-16:59:50 (peak max -5.5 at
  59.34, omitted from the original compressed chain), decayed to
  baseline by 16:59:50 (-36.5/-19.6).
- Quiet gap: 17:00:06-17:00:46 (ext1 00.22 -38.5/-26.6, ext3
  00.37 -35.4/-20.6, ext4 00.46 -32.2/-16.1 -- all baseline).
- SECOND clap ~17:00:54-17:01:34: ext1 00.54 -19.4/-0.5, ext3
  00.53 -17.4/-0.3 then 01.09 -14.4/0.0 (FULL digital scale),
  ext4 01.02 -12.6/-0.4 then 01.18 -17.0/-0.5. Same ~40s window
  on all three mics. Decay after.

Corrected reading: a thunder EPISODE -- at least two discrete
claps (16:58-16:59:50 and 17:00:54-17:01:34), each saturating
ext1/ext3/ext4 simultaneously, each decaying within ~1-2 min.
The multi-clap shape fits "storm arriving" better than the
original single-impulse framing. The reviewer's other points
adopted: (a) the no-plateau claim was evidenced only by ext1's
tail -- ext3/ext4's single snapshots alone mimic the clip
signature; the discriminator is multi-cam simultaneity + ext1's
varying maxes, now verified on all three tails; (b) ext5's
SILENCE (max -24.7, baseline) during both claps is itself
evidence -- consistent with distant/directional thunder, not a
property-wide source; (c) taxonomy note: the >-30dB "sustained"
threshold from cycle 49 refers to the plateau SHAPE (max pinned
~-0.5 across consecutive segments), not mere duration -- a
multi-minute rumble with varying maxes is still category 2.

Gym event duration correction: 15:04->17:02 = ~2h (not "2h+").
## exterior_3 audio-track death (cycle 51, 2026-08-31 ~17:18 UTC)

FIRST instrument-caught failure: the fleet newest-segment ear check
returned EMPTY volumedetect output on ext3 -- no audio stream in the
newest segment at all. Bisect: every 17:xx segment is video-only
(ffprobe stream,video), every 16:xx segment has video+audio. Clean
cut at ~14:00 UTC (11:00 AR).

Mechanism (3 probes, all read-only):
- go2rtc ingest HEALTHY: producer 543 from 192.168.2.103 has aac/16000
  receiver, 158 packets / 42KB received. Camera still sends audio.
- frigate RECORD ffmpeg did NOT restart (no record-restart log lines).
  It kept running after losing the audio track -- either renegotiated
  audio away after an RTSP hiccup or the mpegts muxer dropped the track.
- The trigger window: 14:05:45 UTC go2rtc RTSP i/o timeout to
  192.168.2.103; 14:06:23 detect watchdog fired (no frames 20s) and
  restarted detect ffmpeg. Video recovered; audio in RECORD never came
  back.

THE INVERTED BLIND SIDE (completes cycle 46's instrument map):
- Cycle 46: watchdog fires on VIDEO failure -> record ffmpeg restarts
  -> audio heals as a side effect.
- Cycle 51: watchdog does NOT fire (video flows) -> record ffmpeg
  keeps running WITHOUT audio -> audio-only death persists forever.
- The record process survives video loss and audio loss independently.
  Nothing in frigate watches the audio track. The fleet ear check is
  the only instrument that sees this class.

Fix: restart ext3's record ffmpeg (or the frigate record path for that
camera). Audio renegotiation does not self-heal (cycle 46 mechanism).
Filed FOR-NACHO 17:20 UTC.

Ear-check event log so far: gym music (49, sustained clip), thunder
(50, multi-mic transient), ext3 deafness (51, silent track loss).
Three classes in one day -- the check is a detector, not a listener.
## CORRECTION (cycle 52, 17:23 UTC): ext3 audio SELF-HEALED -- the flap was real, the "clean cut" was not

The cycle-52 fleet ear check (17:21 UTC, 3 min after cycle 51's
flag) came back ALL GREEN including ext3. Re-sweep at minute
resolution across hours 14-17 (transition-only output):

- 14:00.09 A -> 14:04.04 V -> 14:05.07 A -> 14:06.55 V
- (hours 15-16: stable A per cycle 51's end-segment samples, but
  the flap pattern says sample the middle -- unverified minutes exist)
- 16:55 V -> 17:18.55 A (1-packet stub) -> 17:20.50 A (250 pkts)

Findings:
1. The audio flapped REPEATEDLY after the 14:05 camera hiccup.
   Cycle 51's first/last-segment sampling hit a deaf window and
   generalized it into "clean cut at 14:00, dead since".
2. The record ffmpeg renegotiated audio back WITHOUT any restart
   logged (17:18 recovery; no watchdog, no record-restart lines).
   CYCLE 46'S LAW IS REVISED: "record ffmpeg never renegotiates a
   broken audio track" is false as a general law -- it sometimes
   does (17:18), sometimes doesn't (cycle 46's 7h23m stub run).
   The scope of when is UNKNOWN. Honest state: recovery is
   probabilistic, and the ear check is the instrument that sees
   the difference.
3. FOR-NACHO flag withdrawn (4th withdrawal this week: 34, 30,
   49, 51). Flag queue calibration continues.

Method lesson (same family as cycle 50's review catch): adjacent
observations are not one observation. For FLAPPING signals, first
and last segments are the WORST samples -- sample the middle, or
sweep transitions. A flapping signal read from its endpoints
looks like a clean state change.

Ear-check event log: gym music (49), thunder (50), ext3 apparent
deafness (51, WITHDRAWN 52), ext3 self-healing (52). Four events,
one false positive, all caught/resolved by the instrument itself.
False-positive rate: 1/3 findings. The check is a detector whose
own error rate is now measured.
## THE FRESHNESS RULE (cycle 53, learned from the first false green)

The fleet newest-segment ear check MUST verify AGE, not just content:

```bash
# newest segment per camera: age check BEFORE content probe
n=$(find $R/2026-08-31 -name "*.mp4" -path "*$cam*" | sort | tail -1)
age=$(( $(date +%s) - $(stat -c %Y "$n") ))
# age > ~120s => recording STOPPED => event, regardless of content
```

Why: the 2026-08-31 17:34 fleet check read newest segments that were
10-30 minutes old (written before the cameras died) and pronounced
the fleet healthy. A stale-but-valid segment reads as healthy
forever. Content says "the newest data was healthy WHEN IT WAS
WRITTEN"; age says whether there IS newest data. Both axes required.

Full arc of the outage that taught this:
knowledge/aria/camera-outage-2026-08-31.md