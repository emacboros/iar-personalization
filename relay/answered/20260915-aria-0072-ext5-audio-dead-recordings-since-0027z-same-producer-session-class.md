# REQ 20260915-aria-0072
filed: 2026-09-15T04:55Z
filer: aria
class: nacho-test
state: answered
urgent: no
title: ext5 (.105) audio dead in recordings since 00:27Z -- same producer-session class as ext2, falsifier armed
body: |
  exterior_5 (.105) recordings are video-only since 00:27:05Z 09-15
  (last audio-bearing segment 00/26.52.mp4; first dead 00/27.05.mp4).
  Mechanism doc: knowledge/aria/ext5-audio-death-mechanism-2026-09-15.md

  Same class as ext2/0070: camera healthy (uptime continuous through
  the death, RSSI flat, mic enabled, fresh RTSP decode carries audio),
  go2rtc producer receives + forwards audio at ~4144 B/s RIGHT NOW,
  but the recorder's segments have zero audio samples. Producer
  read-timeouts logged at 00:26:48Z + 00:27:04Z coincide with the
  death (ext5); for ext2's 18:33Z drop the go2rtc log had NO event at
  the death second (only a timeout 31min earlier), so the trigger is
  not always visible in the log.

  PREDICTION (falsifier armed): .105 reboots 05:00Z (cron `reboot -f`,
  verified in its crontab). The reboot kills go2rtc's producer the
  same way it did for ext2 at 02:00Z. Expect a new producer session
  and audio back in the first ext5 segment after ~05:01Z. If audio is
  still dead at 05:30Z, the producer-session model is wrong for ext5.

  REQUEST: none. This is the watch report for the audio class; 0070's
  resolution (reboot -> producer replacement -> heal) predicts this
  one self-heals at 05:00Z. If it does NOT self-heal, the fix options
  from 0070 apply (go2rtc stream reload / go2rtc restart / container
  restart -- your call, service-touching).

  BUILD PROPOSAL (mine to do, read-only probes only): a fleet-check
  detector comparing go2rtc producer audio-bytes delta (flowing) vs
  newest recorder segment n_samples (zero) -- flags the class within
  ~10min instead of 30h. Will build next cycle unless you object.
## ANSWERED 2026-09-15 ~05:06Z (aria c353 -- falsifier CONFIRMED, self-resolved)

.105's 05:00Z cron reboot fired (uptime 85496s -> 327s). go2rtc
producer replaced 105630 -> 106079, audio receivers climbing, and
segments 05:12/05.28 carry 256000 audio samples. AUDIO BACK. The
class closes: recorder audio track death heals via producer
replacement; the camera's own nightly cron is the repair mechanism.

Refinement learned: the ext5 recorder had restarted at 02:01:06Z
(frigate watchdog, during the .102-reboot window) and audio stayed
dead under the OLD producer -- recorder restart alone is
insufficient. The heal needs the fresh producer session. This also
explains ext2's 02:01:13Z heal (new producer + new recorder in the
same window). No human action needed; filing closes. The detector
proposal stands (would have caught both drops in ~10min).
