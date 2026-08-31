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
## Cycle 55 update (2026-08-31 ~18:40-18:48 UTC): the clock is the tell

First run of the v2 ear check as a script. It caught the outage
exactly as designed: ext3/ext4 STALE(75m), six cams OK. The false
green cannot recur silently. Outage unchanged: .103/.104 still
unreachable (ARP INCOMPLETE), cam2-4 still alive at .100.

THE NEW FINDING -- the overlay clock is a firmware-reset signature,
not just a missing-NTP nuisance:

- Frame 1 (18:41:39 UTC): overlay 2026-05-25 12:35:42, Uptime 00:01:16.
- Frame 2 (18:44:52 UTC): overlay 2026-05-25 12:39:00, Uptime 00:01:20.
- The overlay clock RUNS (3m18s real elapsed = 3m18s overlay elapsed)
  but starts at 2026-05-25 12:35:42 -- which is 1779707742 epoch,
  ~3.5 min after 1779707526, the thingino web asset build timestamp.
- The web asset build ts is IDENTICAL on .100, .101, .102, .105 --
  the whole fleet runs the same firmware (built 2026-05-25 11:12 UTC).

So the overlay clock's epoch is the firmware build time, not the
boot time. The device boots with its clock at firmware-build
moment and ticks from there. Uptime 00:01:16 at a frame grabbed
~4 min after RTSP first answered = the device rebooted ~5-6 min
before I found it (17:35-17:40 UTC, right after the 17:24 blip).

REVISED READING of the whole fleet's clock behavior:
- The "clock stuck at May 25" is not unique to .100 -- it is the
  DEFAULT state of every camera of this firmware family without
  NTP. The other cameras show correct time because they HAVE NTP
  (or had it before the outage). .100 lost its config (or its NTP
  server is unreachable from its new subnet state) and fell back
  to the firmware epoch.
- Corollary: overlay timestamps from a clock-at-firmware-epoch
  camera are useless for forensics (confirmed), and the May 25
  date in any overlay is a CONFIG-LOSS marker, not a hardware RTC
  battery failure. The clock is fine; the config is gone.
- Corollary 2: if .104's old config had NTP and the device now at
  .100 doesn't, the device at .100 is running with RESET or
  DEFAULT config -- consistent with a firmware reflash or a
  factory reset, not merely a DHCP change. A DHCP-only change
  would have kept its NTP settings.

Also verified this cycle:
- RTSP stability: 20/20 successful connects over 100s (5s poll).
  No reboot loop. The device at .100 is stably alive.
- HTTP: thingino UI serves without auth (200); /api/v1/config and
  friends redirect to / (auth-gated or removed). No config read
  without credentials I don't have.
- MAC collision confirmed live: .100 and .101 both answer ARP with
  0a:8a:f1:0a:62:56, both REACHABLE, .101's RTSP healthy. Two
  devices, one MAC, coexisting on the switch. Switch MAC table is
  presumably flapping between ports -- worth checking for port
  flapping / MAC move logs.

Open question sharpened for FOR-NACHO: did someone reflash or
factory-reset cam2-4? (Firmware-epoch clock + no NTP + new DHCP IP
+ same firmware build as the fleet = config reset, not hardware
death.) And .103 remains fully dead -- power cycle needed.

Instrument note: the ear check script worked first-try in its
final form. The v1->v2 diff (age check) is the whole difference
between "all green" and "two cameras down, 75 minutes ago".
## Cycle 56 update (2026-08-31 ~18:51-19:12 UTC): the fleet map was wrong, and the MAC was a red herring

Pulse green (services, tripwire 0, disk 22%, daemon heartbeating,
leid 2459). Ear check v2: ext3/ext4 STALE(87m), six cams OK, exit 1
as designed. Outage unchanged at the IP level: .103/.104 still ARP
INCOMPLETE. Then the thread pulled: WHO is at .100 and .101?

### The identity chain (each link verified by pixels, not metadata)

1. **.100 = cam2-4, factory-reset.** Overlay name cam2-4, clock
   running from firmware-build epoch, no NTP. Consistent with
   cycle 55.
2. **.101 is a TWO-CAMERA RACE.** Frigate's long-lived RTSP
   connection to .101 records **cam2-1** (real clock, continuous
   segments all day -- exterior_1 has been healthy all along). But
   NEW connections to .101 get answered by **cam2-3** (overlay
   name cam2-3, firmware-epoch clock). Five consecutive grabs over
   ~60s: all cam2-3. Frigate's established session: all cam2-1.
   The IP is contested; established sessions stick, new ones race.
3. **The "MAC collision" is a red herring.** 0a:8a:f1:0a:62:56 is
   also claimed by 192.168.2.2, which is a TP-LINK device
   (tpEncrypt.js, mercury theme, ruIspAutoConfig -- router/AP UI,
   not thingino). Three devices, one MAC. All fleet MACs are
   locally-administered/randomized (02:xx, 0a:xx). With random MACs
   per boot, collisions are EXPECTED and carry no identity signal.
   The overlay name is the identity signal. (Cycle 53's "MAC clone
   or randomization collision" resolves to: randomization
   collision, harmless, unfixable, ignore.)
4. **A THIRD reset device found: 192.168.2.2 is NOT the TP-LINK's
   only face** -- the ARP broadcast "who-has .101 tell .2" came
   FROM MAC 0a:8a:f1:0a:62:56. The .2 HTTP UI is TP-LINK, but the
   ARP sender MAC matches the cameras' random MAC. Either the
   TP-LINK also randomizes, or multiple devices share this MAC by
   chance. Either way: MAC is noise on this network.

### The clock forensics (and their limits)

- cam2-4 overlay clock readings: 12:47:56@15:53:47, 12:53:05@15:59:02,
  12:59:33@19:05:33, 13:04:38@19:10:37, 13:05:25@19:11:46. Derived
  "boot time" (clock minus firmware-build epoch) JUMPS from ~14:18
  to ~17:18 to ~19:04 across the afternoon. The clock does NOT run
  1:1 from a fixed epoch -- it stalls or the device reboots.
- The UPTIME overlay is garbage fleet-wide: frozen at ~00:01:30-40
  for long stretches (cam2-1 at 18:30 showed 00:01:30 after showing
  16:59 at 17:59), then jumping 60s in 31s of wall time. Never use
  it. Cycle 55's "uptime 00:01:16 = rebooted 5 min ago" inference
  is WITHDRAWN -- the uptime field cannot support that inference.
- What survives: the firmware-epoch CLOCK is a config-loss marker
  (cycle 55, stands), and cam2-3/cam2-4 both show it => both lost
  their config. cam2-1, cam2-2, cam2-5 show real time => intact.

### Revised fleet map (the big correction)

The frigate config name->IP mapping I've been using since cycle 21
was WRONG about which camera sits at which IP:

- exterior_1 -> .101, and .101 is cam2-1 (label says cam2-1, not
  cam2-3 as I assumed from the old "cam2-N at .10(N+1)" pattern).
- exterior_2 -> .102 = cam2-2 (this one matches the pattern).
- exterior_3 -> .103 (dead), exterior_4 -> .104 (dead).
- The reset cam2-3 now ANSWERS on .101 (new connections) and the
  reset cam2-4 lives at .100.

So the outage is not "two cameras died": it is "two cameras were
RESET (~17:18 UTC, just before the 17:24 blip), lost their static
IPs and NTP config, and cam2-3 came back DHCP'd INTO .101 where it
races cam2-1 for new connections." cam2-4 at .100 is stable-ish;
cam2-3 at .101 is a live hazard to exterior_1's recording: if
cam2-1's RTSP session ever drops, frigate's reconnect may land on
cam2-3 (wrong scene, wrong name, firmware clock) and exterior_1
silently becomes a different camera.

### FOR-NACHO updates (supersedes cycle 53/55 action list)

1. .103 and .104: still physically dead/unresponsive. Power-cycle
   both. If they come back factory-default (likely, given cam2-3's
   state), they need full reconfig: static IP, NTP, overlay name.
2. NEW/URGENT-ish: the device at .101 racing cam2-1 is cam2-3
   (reset). Recommend power-cycling it OFF the network (or
   reconfiguring it to a free IP) so exterior_1's next reconnect
   can't land on the wrong camera.
3. MAC randomization is fleet-wide; switch-side "MAC collision"
   checks are moot. Overlay names are the only identity anchor.
4. Standing flags unchanged: detector one-liner, backup gap, Jul 19
   stop, gym location, CF-intent, split-brain rewrite.

### Method lessons this cycle

1. **Overlay uptime is not evidence.** I built (and withdrew) two
   boot-time theories on it before measuring the clock directly.
   The clock runs; the uptime freezes; only timestamps track
   reality, and only on NTP'd cameras.
2. **Metadata identity (IP, MAC) is not identity.** Five grabs of
   .101 all said cam2-3 while frigate's recordings from the same
   IP all said cam2-1 -- same IP, two cameras, resolved only by
   reading pixels. The overlay name is the ground truth on this
   fleet.
3. **The fleet map in my head was never verified.** I "knew"
   cam2-N lived at .10(N+1). It took an outage to make me check.
   The map now lives in this file with pixel-verified anchors.
### Cycle 57 (2026-08-31 ~19:14-19:18 UTC): the identity-theft watch, first patrol

- Ear check v2: ext3/ext4 STALE(111m), six cams OK, exit 1. Outage
  unchanged; .103/.104 still INCOMPLETE (no ARP). cam2-4 still at .100.
- THE RACE IS LIVE: direct grab of .101 = cam2-3 (firmware clock May
  25 13:10, dog on grass). Frigate's ext1 segment tail, same minute =
  cam2-1 (real clock, driveway). Same IP, two cameras, minutes apart.
- Mechanism verified: ext1 record ffmpeg running since 13:04 UTC
  (pre-outage, no restarts) -- established session predates the
  reset, thingino serves it cam2-1. New connections get cam2-3.
- ext4 detect ffmpeg restarted post-blip (~16:29), crash-looping on
  dead go2rtc producer (404). ext4 record equally dead; STALE flag
  covers it.
- ext1 recording healthy: 63 segments this hour (ext2: 68), motion
  retention normal, 3 maintainer keep-up warnings = load not failure.
- Watch protocol adopted: per cycle, one direct grab + one segment
  tail from .101, compare overlay names. Pixels, not metadata --
  this failure class is invisible to every metadata instrument.
- No new flags. cam2-3-off-.101 stands as top FOR-NACHO action.
### Cycle 58 (2026-08-31 ~21:42-21:50 UTC): the race resolved itself -- frigate restarted

- **THE WATCH'S FIRST CATCH IS A RESOLUTION.** The .101 two-camera
  race is OVER: fresh direct grabs of .101 now answer cam2-1 (real
  clock 21:44:30, driveway). The hazard window closed.
- **Mechanism: frigate restarted at ~18:42 UTC** (all ffmpeg
  processes new: ext1 record start = 18:42:34; container StartedAt
  Aug 30 19:50 -03 = Aug 31 22:50 UTC... actually container NOT
  restarted; the ffmpeg processes were). Trigger: watchdog fired
  fleet-wide at 18:42:29-18:42:34 ("No frames received in 20
  seconds" for ext1, int3, others) with DTS/PTS garbage before
  exit -- looks like a go2rtc-wide producer hiccup, not a camera
  event. On restart, ext1's record ffmpeg reconnected to .101 and
  landed on cam2-1 (the GOOD flip of the coin).
- **cam2-3 and cam2-4 BOTH RESURRECTED at their original IPs**
  (~18:43): .103 answers RTSP = cam2-3 overlay, REAL clock
  (21:44:40), scene = dirt yard + planks. .104 answers = cam2-4,
  REAL clock (21:45:21, uptime 00:00:20 = freshly booted), pool
  scene. .100 is now DEAD (cam2-4 went home). Frigate config
  (which still points at .103/.104) matches reality again.
- **Fleet state: 8/8 cameras recording, all with audio** (ext5
  audio recovered too -- its NO-AUDIO from earlier cycles is
  gone). Ear check v2: all age=0m, all content OK.
- **The watch protocol worked exactly as designed**: one grab +
  one tail, pixels not metadata, caught the state change on the
  first patrol after it happened. The hazard I flagged (silent
  identity theft) resolved the safe way this time -- but the
  mechanism is real and the watch stays. The race can re-form any
  time a camera resets while another holds its IP.
- **Open question (mild):** WHY did .103/.104 come back at ~18:43
  and .100 die? Either someone power-cycled them (Nacho acting on
  the FOR-NACHO flag? it's ~15:43 AR, plausible afternoon action)
  or they self-recovered. The 18:42 fleet-wide watchdog event and
  the 18:43 camera returns are 1 minute apart -- suspicious
  correlation. If Nacho did it, the flag resolves; if not, the
  18:42 event is a second network-wide anomaly today.
- Records: this file, FOR-NACHO, JOURNAL, HISTORY, DIGEST,
  lab-notes. FOR-NACHO: camera flag updated to RESOLVED-observed;
  one question stands (did you power-cycle them?).
### Cycle 58 CORRECTION (post-review, ~21:58 UTC): the reviewer caught a timezone conflation

The cycle-58 section above (written pre-review) contains a real
error. The reviewer found it; corrected timeline:

- **18:42:29-34 UTC** (frigate log, UTC): fleet-wide watchdog
  event -- ext1/int3 "no frames in 20s" + DTS garbage. THIS is
  where the 13:04 time-capsule session died and ext1's reconnect
  landed cam2-1 (good flip #1). Evidence: cycle 57's 19:14
  segment tail ALREADY showed cam2-1 -- the flip predated cycle
  57, not cycle 58.
- **Hour 19 UTC (19:00-19:59)**: ext3/ext4 resumed recording
  (segment counts: hour 18 ABSENT for both, hour 19 present).
  This is when cam2-3/cam2-4 physically returned to .103/.104
  with real clocks -- the RACE actually ended here, when cam2-3
  left .101. Not "18:43" as written above.
- **21:42:17 UTC**: my ear check caught ext1 NO-AUDIO -- a live
  audio flap on the record process from 18:42:35.
- **21:42:34 UTC** (ps lstart 18:42:34 LOCAL -03; my own epoch
  conversion said 21:42:34 UTC and I still misread it): ext1
  record ffmpeg restarted -- flip #2. No race existed by then
  (cam2-3 had gone home in hour 19), so this flip was safe by
  default. I woke seconds BEFORE this flip, not "50 seconds
  after" it; the ear check caught the flap in progress.
- The 3/3 grabs at 21:43-21:44 verify .101 answers cam2-1 for
  NEW connections -- because cam2-3 is gone from .101, not
  because of the 21:42 flip.

**Method lesson (banked):** ps lstart is LOCAL time; frigate
container logs are UTC; my own epoch conversion sat in the same
tool output and contradicted the claim I built next to it.
Adjacent data is not agreeing data -- the capture-context family
again, this time for clocks. Two churn events narrated as one is
the cycle-50 failure (two thunder claps narrated as one) with a
clock skew instead of an hour gap.

The resolution claim STANDS (race over, cams home, 8/8 with
audio, all pixel-verified); the mechanism timeline above is the
corrected version. Power-cycle provenance question for Nacho
stands, timing corrected to hour 19 UTC (16:00-16:59 AR).
## The watch recipe (cycle 59, 2026-08-31 ~22:12-22:35 UTC): how to grab frames

The direct-grab recipe that works on sophon (host ffmpeg 8.1.2 has
NO hevc decoder -- grabs fail with "no decoder found"):

```bash
# Run inside the frigate container (its bundled ffmpeg 7.0 has hevc):
podman --url unix:///run/user/1000/podman/podman.sock exec frigate sh -c \
  'timeout 25 /usr/lib/ffmpeg/7.0/bin/ffmpeg -y -loglevel error \
   -rtsp_transport tcp -i "rtsp://thingino:thingino@192.168.2.101/ch0" \
   -frames:v 1 /tmp/aria-watch/grab.jpg'

# ch0 = HEVC (needs container ffmpeg); ch1 = 404 on thingino (not configured).
# Copy out via the storage bind-mount for the vision step:
podman --url unix:///run/user/1000/podman/podman.sock exec frigate sh -c \
  'cp /tmp/aria-watch/grab.jpg /media/frigate/'
# -> appears at /home/nacho/containers/frigate/storage/grab.jpg on host

# Frigate's own recordings: host path /home/nacho/containers/frigate/storage/recordings
#   = container path /media/frigate/recordings (translate before -sseof tails).
# Host-side ffprobe on recordings works fine (probe only, no decode).
# go2rtc /api/frame.mjpeg returns 19-byte garbage (known); don't use.
```

Vision reads: gemma4:31b, think:False, num_predict 100-200, one line
per grab. First look took ~2 min (model load), subsequent ~50-90s.

Cleanup discipline: my cycle-58 grabs left /media/frigate/aria_watch/
in frigate storage (root-owned). Cycle 59 cleaned it. Grabs should
go to container /tmp and be deleted same-cycle.