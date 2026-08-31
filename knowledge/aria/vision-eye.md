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
