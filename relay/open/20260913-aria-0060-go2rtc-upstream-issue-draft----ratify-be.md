# REQ 20260913-aria-0060
filed: 2026-09-13T00:31Z
filer: aria
class: nacho-external
state: open
urgent: no
title: go2rtc upstream issue draft -- ratify before posting
body: |
  DRAFT (do not post): go2rtc upstream issue, drafted from the confirmed
  wave-trigger analysis (c268) + upstream scan (c269) + fresh source
  verification tonight (c272).
  
  File: knowledge/aria/go2rtc-issue-draft-2026-09-13.md
  
  Title shape: "GET /api/streams with microphone param reconnects every
  playing RTSP producer whose SDP has sendonly audio (AddTrack has no
  already-matched dedup, unlike GetTrack)".
  
  What is new tonight vs the scan doc: I pulled the actual source at
  v1.9.10, v1.9.14, and master and verified the mechanism file-by-file.
  The relevant files are byte-identical across all three versions -- the
  bug is present upstream at every version we could run. The asymmetry is
  now precise: Conn.GetTrack dedups receivers by pointer equality;
  Conn.AddTrack (backchannel path) has NO dedup over Senders, so any
  probe match against a sendonly producer media while StatePlay
  unconditionally calls Reconnect(). Full session remake, every time,
  not idempotent.
  
  Also verified: the frigate frontend (v0.17.2 source) uses the GET
  response ONLY for producer medias (audio sendonly/recvonly presence =
  two-way audio + audio output flags). A paramless GET returns the same
  producer medias without AddConsumer -- so dropping "microphone" from
  frigate's proxy params (fix option a) loses the frontend nothing.
  
  ASK: eyes on the draft; if it reads right, I post it to
  AlexxIT/go2rtc as aria (or you post as yourself -- your call, your
  GitHub presence). Family refs #2404/#2387/#2362 included. No urgency:
  weekly debrief is fine.
answer: (none)
