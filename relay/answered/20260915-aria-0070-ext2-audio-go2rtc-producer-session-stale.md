# REQ 20260915-aria-0070
filed: 2026-09-15T01:37Z
filer: aria
class: nacho-external
state: open
urgent: no
title: ext2 audio: go2rtc producer session stale, audio track dead since 09-14 15:34Z
body: |
  ROOT CAUSE FOUND (c345, evidence: knowledge/aria/ext2-audio-root-cause-c345-2026-09-15.md)
  
  ext2 (.102) audio has been dead in recordings since 09-14 15:34:07Z.
  Diagnosis: the camera is HEALTHY -- a fresh RTSP session carries both
  video and audio data (verified: 8s ffmpeg capture, 126 audio packets).
  The freeze is inside go2rtc's long-lived producer session (id 95255):
  audio receivers frozen at 7846778 bytes since the drop, video flowing
  normally. Because the TCP control channel never errored, go2rtc never
  reconnected the producer -- the 09-08 self-heal was a producer
  RECONNECT, not in-session renegotiation.
  
  ACTION NEEDED (your call, service-touching): replace the stale
  producer session. Lightest: go2rtc config reload
  (PATCH /api/streams?src=exterior_2), or restart go2rtc inside the
  container, or podman restart frigate. After the replacement, audio
  should return within one segment (~15s). Falsifier included in the
  filing. I did NOT touch the service (read-only inspection only).
  
  If you'd rather I do the lightest option myself, say so and I'll
  execute it next cycle.
answer: (none)
## AMENDMENT (c346, 2026-09-15 ~01:47Z): model VERIFIED against live counters

Re-probed go2rtc API twice, 20s apart (01:47:13Z / 01:47:37Z):
- exterior_2 producer id STILL 95255 (unchanged -- no reconnect happened).
- audio receivers bytes STILL EXACTLY 7846778 (frozen, third consecutive
  static reading across 15 minutes of wall time).
- video receivers bytes climbing: 268060858 -> 268124812 (+63954 in 20s).
- controls healthy: exterior_1 audio 11545264 climbing, exterior_3 audio
  3261022 climbing (both producers reconnected 09-14 22:00-22:34).

The root-cause model survives its first live re-derivation: the freeze is
in producer session 95255, not the camera, not the record proc. Fix
remains pending your call (options in the body). Falsifier unchanged.

## ANSWERED 2026-09-15 ~02:15Z (aria c347 -- self-resolved, no action needed)

The nightly reboot (cron `reboot -f` at 02:00Z) replaced producer
95255 with producer 103534. Verified c347: new producer's audio
receivers CLIMBING (1.55MB -> 1.88MB in 45s), bytes_recv growing,
and every closed segment in the 02Z hour carries an aac track
(ffprobe: hevc,video + aac,audio on all 31 segments). The 01Z hour
(producer 95255's last) was video-only to the end. The camera's own
cron did what 0070 asked for; no human action needed. Filing closes.
