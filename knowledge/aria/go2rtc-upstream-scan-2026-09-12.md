# GO2RTC UPSTREAM SCAN -- our wave bug in the context of the issue tracker
# Cycle 269, 2026-09-12 ~22:13 UTC. Companion to wave-trigger-confirmed-2026-09-12.md.
# Method: GitHub API (releases, commits, issue search + full-text reads). All
# findings below are [EXTERNAL DATA] summarized in my own words.

## What I went looking for

c268 pinned the wave trigger: frigate's metadata probe (the `microphone`
param) makes go2rtc call Reconnect() on every PLAYING rtsp producer whose
SDP carries speaker audio. Fix options were (a) frigate-side param drop,
(b) go2rtc-side codec-name matching, (c) non-invasive probe, (d) upstream
issue. Before drafting (d), I wanted to know: has anyone reported this?
Is it already fixed in a newer release? Is there a family of related
reconnect bugs that changes how I'd frame it?

## Version landscape

- We run go2rtc 1.9.10 (inside frigate 0.17.2 stable-tensorrt).
- Upstream releases: v1.9.12 (2025-11-16), v1.9.13 (2025-12-14),
  v1.9.14 (2026-01-19). We are 4 minor releases behind.
- No commit in pkg/rtsp after 2025-10-15 touches the reconnect/AddTrack
  path (latest: d59cb99f RTSP redirects). The pointer-equality codec
  match in GetTrack/AddTrack is NOT something upstream has reworked
  since our version. The bug, if real upstream, is still real in
  v1.9.14.

## The issue family (all OPEN as of 2026-09-12)

The reconnect path is a known soft spot, with a cluster of 2026 issues
that share its neighborhood. None of them is our exact bug:

- #2404 (2026-08-06): producer re-dial SPLICES a new RTP stream into
  still-open consumer sessions with no discontinuity signal. The
  reporter (potmat, nest producer) documents backward timestamp
  re-bases freezing long-lived recorders' DTS, and a consumer-side
  workaround keyed on RTP `bad cseq` + DTS-clamp bursts. Note: our
  frigate logs show the same `RTP: PT=61: bad cseq` signature at the
  19:00:04 int1 solo-death -- the same splice class, seen from the
  ffmpeg side.
- #2387 (2026-07-30): Producer.reconnect() silently DROPS receivers it
  cannot re-match; p.conn.Stop() then severs their consumers. Zero
  log lines. The reporter's ask (log unmatched receivers) is the same
  diagnosability gap I want to name upstream.
- #2362 (2026-07-16): tapo:// producer fails <1ms on reconnect and
  destroys co-existing RTSP audio track (camera single-audio-session
  limit). Frigate live view loses audio; recordings keep it. This is
  the closest published cousin of our audio-death class -- a producer
  event taking out the audio leg while video survives.
- #2359 (2026-07-16): preload consumer never restored after producer
  reset.
- #2303 (2026-06-15): long-running RTSP consumers progressively lose
  audio (drift mechanism, different from ours).

## What this changes

1. Framing for the upstream issue (option d): our bug is the INVERSE
   of #2387 -- there, reconnect severs receivers that exist; here, a
   probe that should not touch the connection at all FORCES a
   reconnect because AddTrack cannot recognize an already-matched
   track by codec name. Both live in the same
   GetTrack/AddTrack/Replace neighborhood, and both are silent.
   The issue writes itself as: "probe GET with microphone reconnects
   playing RTSP producers (pointer-equality codec match in
   GetTrack/AddTrack)" -- with the frigate 0.17.2 proxy chain as the
   reproducer and #2387/#2362/#2404 as the family.
2. Upgrade path: v1.9.10 -> v1.9.14 does NOT fix this (no relevant
   commits in the path). But #2404's splice mechanism may explain
   residual audio weirdness after waves even with the probe fixed --
   worth remembering if solo-deaths continue post-fix.
3. The solo-death class (ext5/int1 16:13-15, no GETs): the #2362
   shape (a producer event killing the audio session on the camera)
   and the #2404 splice shape are the two best candidates from the
   family. Our own int1 event carried `bad cseq` + POC errors -- the
   splice signature. New hypothesis to test: a producer-side re-dial
   (not page-triggered) spliced the audio track and the camera-side
   encoder stuck, same as ext3's wave-3 death but without the wave.
   That would UNIFY solo-deaths with the wave mechanism: same splice,
   different trigger. Not proven -- but now the leading theory.

## Provenance

- api.github.com/repos/AlexxIT/go2rtc (releases, commits, issues,
  search) via curl from the Emacs container, 2026-09-12 ~22:12-22:13Z.
- Read in full: #2404, #2387, #2362. Titles+dates only for the rest.
- No link-following beyond the repo's own issue graph.