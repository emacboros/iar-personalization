# Audio-death law v3: the mid-life audio-leg death (int1, 2026-09-12)

## Summary

Law v2 (camera-relative: record ffmpeg audio dies when its RTSP
session predates/is born during the reboot OF THE CAMERA IT
STREAMS FROM) held for ext2 (died AT .102's 02:00:04Z reboot) and
was confirmed from the recovery side (ext3 fresh boot = healthy).
Today int1 (.201) produced a SECOND class the law does not cover:
the audio leg of a FRESH session died mid-life with no camera
reboot, while the video leg of the SAME session kept flowing.

## The int1 case (verified facts)

- Record proc 3058369 born 15:33:10Z (sophon local 12:33:10),
  AFTER .201's 13:36:49Z boot => session is FRESH, not a straddle.
- Segments: hour-15/16 audio 156 pkts/seg healthy; 16/13.42.mp4 =
  149 pkts (partial); 16/14.04.mp4 = 0 pkts AND NO AUDIO TRACK at
  all. Segment mtimes put the cut at ~16:13:42-52Z.
- .201 uptime continuous through 16:13Z (rssi uptime col monotonic,
  boot stays 13:36:49Z across the death minute). NO reboot.
- go2rtc producer 39981 (born with the record proc): audio receiver
  FROZEN at 38135 pkts from 17:48Z through 17:53Z samples; video
  receiver growing normally (173987 -> 183172 over the same window).
- Camera still produces audio on FRESH sessions: direct RTSP pull
  from .201 at 17:48Z and 17:52Z both delivered ~13 KB of AAC in 3s.
- Camera-side logread at 16:13-16:14Z: silent (only rssi cron rows).
  No prudynt restart, no audio/dsp errors logged.
- prudynt config: mic_enabled=true, tap_enabled=true,
  tap_path=/run/prudynt/audio_mic.pcm. The tap FIFO had NO reader
  (checked /proc/*/fd on camera) -- candidate mechanism, unproven.

## The two classes (law v3)

- CLASS 1 (straddle-at-reboot): session predates the streamed
  camera's reboot; audio dies AT the reboot. ext2 = the specimen.
  Heal: next staircase reboot remakes the producer (prediction
  stands for ext2 tonight).
- CLASS 2 (mid-life audio-leg death): session is fresh; audio runs
  minutes-to-hours, then dies with NO camera reboot; video leg of
  the same session survives; camera still serves audio to fresh
  sessions. int1 = the first specimen. Camera-side audio path stall
  is the leading hypothesis (prudynt tap FIFO with no reader is
  candidate mechanism); go2rtc-side track renegotiation failure is
  the alternative.

## Instrument notes (for whoever reads the go2rtc API next)

- /api/streams?src=X receivers[].packets: the audio receiver count
  can FREEZE while video grows -- that freeze is the class-2
  signature. But the counter is NOT a reliable lifetime total
  (38135 pkts = ~40 min of audio at 156/10s-seg, yet segments had
  audio for 2h37m after the session's birth) -- treat it as a
  liveness signal (frozen = dead leg), not a census.
- ffprobe per-segment audio packet counts remain the ground truth
  (250 healthy / 156 int1-normal / 1 stub / 0 stream-absent).
- My own test pulls register as go2rtc consumers (Lavf61.1.100,
  ids 41627/41638) and linger after exit -- go2rtc consumer lists
  include my instruments; do not mistake them for frigate procs.

## Open

- The tap-FIFO-no-reader mechanism: unproven. Next cycle could check
  whether OTHER cameras run tap_enabled with no reader, and whether
  class-2 deaths correlate with tap buffer state.
- int1 heal prediction: a record-proc restart (frigate watchdog or
  camera reboot) remakes the session and should restore audio.
  Killing the proc is a service intervention = Nacho's call; filed
  via relay if it stays dead through tomorrow's staircase.