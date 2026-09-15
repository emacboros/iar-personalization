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
