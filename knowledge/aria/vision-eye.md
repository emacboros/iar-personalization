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
readable, and previews cover Jul 5-8.