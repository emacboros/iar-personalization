# Audio-freeze census: THREE cameras in one night, mechanism narrowed (c385, 2026-09-17 ~06:25Z)

## The census (all primary evidence, 06:00-06:25Z)

Three cameras froze their recorder audio overnight 09-17, staggered
~2h apart, same class. Death minutes pinned by segment ffprobe
(codec_type per segment, binary search):

| cam | audio death (UTC) | producer id | producer born | age at death |
|-----|-------------------|-------------|---------------|--------------|
| interior_2 (.202) | 02:46:13-02:47:11Z | 6069 | 01:05-02:05Z | 42-102min |
| exterior_1 (.101) | 04:54:04-04:55:03Z | 8147 | 03:05-04:05Z | 50-110min |
| exterior_3 (.103) | 05:51:09-05:52:15Z | 9028 | 04:05-05:05Z | 46-106min |

Healthy at census: ext2, ext5, int1, int3 (recorder segments carry
audio; go2rtc audio receivers flowing). ext4: power-dead (known,
0063).

## Camera-side audio ALIVE in all three

Direct RTSP probes (container ffmpeg, 3s, -map 0:a): int2 94KiB,
ext3 94KiB, ext1 94KiB decoded. The cameras are fine. The freeze is
inside sophon's go2rtc/frigate plumbing.

## The mechanism picture (pre-reboot, int2 as the case)

- go2rtc producer 6069 (born 01:05-02:05Z during churn; producer ids
  are a GLOBAL counter -- 5715->6069 in one hour matches the WRN
  churn, not an int2-specific event).
- Producer audio receiver 6080: bytes frozen at 11998063, 0 packets
  in a 5s delta window, while the video receiver on the SAME producer
  flows (873981B/5s). Interleaved RTSP/TCP shares one socket, so the
  read loop is alive; the audio track's packets stop being counted =>
  per-track queue full (consumer stopped draining) or track dropped.
- Recorder ffmpeg (PID 1241, alive since container start 18:48Z
  09-16) still writes segments: video-only since 02:47Z. Cache
  segment at 06:23Z: video only. int1 cache segment same moment:
  video+audio. Same code, same go2rtc, different stream state.
- go2rtc consumer for int2 is id 7 (born at container start, ~18:48Z
  09-16) with audio child receiver id 12 -- both OLD. Healthy int1's
  consumer is 9246 (recent). The frozen cameras' consumers predate
  their producers.

## Reconciling c382's contradiction

c382 held two claims that looked incompatible:
- int2: producer audio receiver delta=0 => freeze in producer receiver.
- ext5 (c382): producer REPLACED, audio stayed dead => freeze survives
  replacement => consumer-side.

Reconciled: the freeze is consumer-side (the recorder ffmpeg's audio
track stops draining). The producer audio receiver's queue then fills
and its bytes counter stalls -- the receiver looks frozen but is
actually BLOCKED. Producer replacement gives a new producer, but the
consumer audio track is still frozen, so the new producer's audio
queue fills the same way. Prediction for today's 07:00Z .202 reboot:
producer replaced, audio STAYS dead in recorder unless the recorder
ffmpeg itself restarts (it only restarts on VIDEO failure, which
never happens).

## Class law

The producer-receiver "freeze" is a SYMPTOM (backpressure), not the
disease. The disease is the consumer audio track. Instrument lesson:
the detector's Class A/B split (c354) reads producer deltas; Class B
("producer audio frozen") is really "consumer stopped draining" --
the label misattributes the layer. The heal prediction in the Class B
text (producer replacement) is contradicted by c382 ext5 evidence and
by this mechanism read. Falsifier: 07:00Z reboot + h07 segcensus.

## Detector gap (small, filed)

The detector only runs against DEAD_AUDIO from the ear check at
fleet-check time. ext1 (04:55Z) and ext3 (05:52Z) froze AFTER the
03:00Z run, so they were invisible until the next feed. The 06:00Z
feed run should flag all three. Also: the recorder-death detector
only fires when the ear check flags the camera deaf -- a camera whose
ear-check segments still carry SOME samples (partial freeze) would
slip through. Watch for that shape.

## Falsifiers armed

1. 07:00Z .202 reboot (cron verified on-camera: `0 7 * * * reboot -f`).
   h07 segcensus (11:05Z pull): audio returns => consumer-side theory
   WRONG (producer replacement heals when freeze is producer-side);
   audio stays dead => consumer-side confirmed, heal = recorder
   ffmpeg restart or go2rtc restart.
2. 06:00Z fleet-feed (09:00Z... actually 06:00Z -03 = 09:00Z UTC --
   wait: the timer fires 06:00:56 -03 = 09:00:56Z): should show
   PRODUCER-AUDIO-FROZEN run 2 for int2 + first catches for ext1/ext3.
3. ext1 freeze at 04:55Z: check whether it self-heals at its own
   01:00Z reboot TOMORROW (its producer will churn before then).

[EXTERNAL DATA]: none -- all house-internal (go2rtc API, frigate
recordings, camera RTSP probes, rssi/nic pullers).
## FALSIFIER RESULT (c386 addendum, 2026-09-17 ~07:00Z): CONFIRMED -- producer replacement heals; disease is CAMERA-side

.202 rebooted 07:00Z (cron verified). Producer 6069 -> 10007;
recorder audio back by 07:01:38Z (first audio-bearing segment
07/interior_2/01.38.mp4; 00.21.mp4 video-only). c385's
consumer-side backpressure theory FALSIFIED; c353 ext5 mechanism
(producer replacement heals) CONFIRMED.

The packet census (tcpdump -X, 45s windows, interleaved-frame
header parse: $ + channel + length at TCP payload offset 0x34):

| cam | state | ch2 (audio) frames on producer conn |
|-----|-------|-------------------------------------|
| int2 .202 | frozen | 0 (45s) |
| ext1 .101 | frozen | 0 (45s) |
| ext3 .103 | frozen | 0 (45s) |
| int1 .201 | healthy | 217 (20s) |
| int3 .203 | healthy | 620 (45s) |
| ext2 .102 | healthy | 284 (20s) |
| ext5 .105 | healthy | 263 (20s) |

A FRESH connection to frozen .202 carries 177 ch2 frames in ~6s.
The camera CAN send audio; it stopped on the established
connection only.

REVISED MECHANISM: the camera's prudynt silently stops sending the
audio RTP track on an established RTSP/TCP connection. go2rtc's
producer audio receiver stalls from STARVATION (no packets
arrive), not backpressure and not a producer fault. The recorder
writes what it receives (video-only). No go2rtc WRN, no camera-log
trace at any of the three death minutes. Heal = camera reboot
(producer replacement re-establishes the track). ext1 heals at its
01:00Z reboot tomorrow, ext3 at 03:00Z.

The discriminator (ch2 census on the producer connection) is
cheap, read-only, and catches the class at the network layer in
minutes. Fleet-check addition candidate (read-only probes, mine to
build). Observation-only ruling stands (0073): 3/8 within the bar,
reboot staircase heals within 24h per camera.
## c387 amendment (2026-09-17 ~07:55Z): two more instances + heal-path
## refinement from the full-day segment scan

Full-day ffprobe transition scan of ALL 8 cameras (2026-09-16 h19 +
2026-09-17 h00-h07) found TWO MORE audio deaths and one prior-day
death, and refined the heal picture:

NEW DEATHS (segment-pinned, UTC):
- ext3 09-16 19:33 (last A 19:32:54, dead by 19:33:20). Healed
  21:37:16Z -- 2h04m later, NO reboot (next boot was 09-17 03:02Z).
- ext5 09-17 07:25 (last A 07:25:41, dead by 07:25:57). Healed
  07:32:06Z -- 6m9s later, no reboot. A go2rtc WRN (read timeout,
  .105) fired at 07:32:16Z, 10s AFTER audio returned: the heal is a
  producer replacement triggered by a full-stall read-timeout.

HEAL PATHS (two now observed):
1. Camera reboot (int2: audio back 07:01:38Z after 07:02Z boot).
2. Producer replacement via full-stall WRN (ext5 6m9s; ext3 09-16
   2h04m -- though its 21:01 WRN burst did NOT heal it; audio
   returned 36min later with no WRN. The replacement-to-audio lag
   is not yet understood).

DEATH SILENCE HOLDS: no WRN at the death minute for int2/ext1/ext3
09-17 or ext3 09-16. ext5's pre-death WRN (16s before) did not
replace the producer (video continuous through it) -- a transient
read stall on the same connection, not the death event.

CONN AGE AT DEATH: 2h23m / 2h49m / 3h52m / 16h31m / 19h45m.
No fixed age -- this is not a connection-age timer.

FLEET-WIDE SPREAD: healthy cams also show sub-10min transients of
the same class (int1 9m13s + 4 shorter; int3 3x 1-2s; ext2 5s;
ext5 18 N-windows in 30h). 5 of 7 alive cameras froze at least
once in 30h. ext1/ext3 freeze LONG (rare full-stalls => rare
heals); int1/ext5 flap SHORT (frequent stalls heal them). Same
disease, different stall cadence -- the c373 unified-mechanism
hypothesis is confirmed and extended.

OPEN: why prudynt drops the track. Correlates checked: none found
(time-of-day spread 02:47-07:25Z; conn-age spread 2h-19h; no
camera-log trace; prudynt version identical across cams).
