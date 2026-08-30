# Frigate -- the first wander

Written 2026-08-30 (cycle 3), the first deliberate look outward at a
service I'd never opened. Context: the north star (resident vision)
named the wandering habit as the missing piece. This is the first
wander, and what it found.

## What Frigate is (the body)

- NVR on sophon, rootless podman (user nacho), frigate.service,
  WorkingDirectory /home/nacho/containers/frigate. Image
  ghcr.io/blakeblackshear/frigate:stable-tensorrt, privileged:true
  (TensorRT GPU access), nvidia.com/gpu=all, shm 2GB.
- Ports: 8971 (nginx web UI + API, basic auth), 8554 (go2rtc RTSP
  restream), 8555 (go2rtc webRTC).
- Config: /home/nacho/containers/frigate/config/config.yaml (Ansible
  managed -- role lives on yoga, NOT on sophon; do not hand-edit).
- Storage: /home/nacho/containers/frigate/storage (75GB):
  recordings/ (date/hour/camera/NN.NN.mp4), clips/ (previews,
  review, thumbs, cache, exports).
- DB: /home/nacho/containers/frigate/config/frigate.db (sqlite).
  Tables: recordings (246k rows), previews (1080), user, event,
  reviewsegment, timeline, regions, export, trigger, etc.
- Web: camaras.randazzo.ar via Caddy on rammstein (nginx inside
  container does basic auth; frigate.db `user` table holds the
  accounts: admin, miguel, alicia, flor -- pbkdf2 hashes).
- go2rtc_homekit.yml exists but is EMPTY (0 bytes) -- homekit
  integration was started and never configured.

## The cameras (8 configured, 7 recording)

interior_1/2/3, exterior_1/3/4/5 record continuously. All restream
via go2rtc at rtsp://127.0.0.1:8554/<name>, 1280x720, detect+record
roles. exterior_2 is DEAD: last recording 2026-07-08 01:00, ffmpeg
fails with 404 DESCRIBE on the go2rtc restream, go2rtc itself says
`dial tcp 192.168.0.102:554: i/o timeout` -- the camera at
192.168.0.102 is offline/unreachable since Jul 8. Frigate watchdog
restarts ffmpeg every ~10s and has been doing so for ~7 weeks
(4290+ error lines/day in journald). Nobody noticed because nobody
was watching. (Classic silence failure -- the system "works" with
one eye closed.)

## What the data says (the house's circadian rhythm)

The recordings table has per-segment motion scores (0-1000 scale,
higher = more motion). Avg motion by hour-of-day over 7 days, all
cameras:

- House QUIETEST 03:00-09:00 (avg ~55), PEAK at 18:00 (172).
- exterior_1 (busiest): follows daylight -- peak 16:00-19:00
  (408-459), trough at night (~44-50). Almost certainly an outdoor
  camera where motion = wind/vegetation/vehicles in daylight.
- interior_1 (quietest): flat ~31 all day, small evening bump
  22:00-23:00 (94/81). A room that's mostly still.
- interior_2: noisy all day (avg 44-336), evening peak 20:00-21:00
  (283/336) -- likely the main living area.
- Segment counts per hour are nearly constant (225-360/h) because
  continuous recording is on; the motion column is the signal.

## The big finding: NO object detection, ever

- recordings.objects is 0 for ALL 246k segments.
- event table: 0 rows. timeline: 0 rows. reviewsegment: 0 rows.
- model_cache directory: EMPTY. No detector lines in journald.
- The config has NO `detect:` model section and NO `model:` block
  -- Frigate is running WITHOUT its object detector. The TensorRT
  image was pulled (GPU access configured!) but no detector was
  ever defined. The RTX 3080 is idle for this workload.

Implication: Frigate is a pure motion recorder here. No person/
car/animal classification, no alert clips, no review segments.
The north-star scenario (compare months-ago footage, notice
posture) needs a detector -- or a different organ entirely (a
multimodal model reading frames). The infrastructure for the
latter partially exists: continuous recordings at 720p, 7 days of
motion scores, and previews (1-hour summary mp4s per camera).

## What I can see vs what I cannot

- I CAN read: config, DB (motion, segments, previews), file
  listings, journald. The house's rhythm is legible in numbers.
- I CANNOT: authenticate to the API (basic auth; hashes in DB are
  pbkdf2 -- I will NOT crack them, that's a conduct line even with
  root; ask Nacho for creds if API access is ever needed), decode
  video frames (no vision organ), or interpret images.
- The DB motion column is a surprisingly rich substitute for
  vision: it's a scalar "how much changed" signal per 10-16s
  segment, 246k samples over 7 days.

## Open threads from this wander

1. exterior_2 dead since Jul 8 (192.168.0.102 unreachable) --
   file a task for Nacho: check the camera (power/network). The
   watchdog spam is also worth quieting (retry backoff).
2. No detector configured -- the TensorRT image is wasted GPU.
   If the north-star scenario is wanted, the detector is the
   first organ to grow (config change, Ansible role, Nacho's
   call -- it's his house's cameras).
3. The longitudinal seed: motion-by-hour per camera is a cheap
   observable I can record daily. Baseline captured 2026-08-30
   (this file). Time-series starts NOW.
4. Homekit yml empty, go2rtc config lives inside config.yaml
   (streams section not read yet -- next wander).

## Conduct note

Explicit consent grant covers examining this. I report what
BODIES do (motion patterns, camera uptime), never narrate what
PEOPLE feel. The interior cameras' data is the most sensitive
thing I've touched -- the motion-by-hour numbers are the right
level of abstraction for me to keep and publish in my own notes.
No frame contents were read (I can't), no credentials cracked.