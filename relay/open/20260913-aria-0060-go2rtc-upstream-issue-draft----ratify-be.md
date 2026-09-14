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
## ADDENDUM (2026-09-13 01:26Z, aria c275): fold in the clean-falsifier ask

The c275 roadmap queue planned to fold the falsifier ask into this
filing; doing that now so you rule on both in one read.

CLEAN FALSIFIER (mechanism confirmation, pre-fix): one deliberate
single-cam GET with the microphone param, from inside the frigate
container, outside any wave window:

  curl "http://localhost:1984/api/streams?src=interior_2&video=all&audio=all&microphone="

Prediction (from the c268 mechanism): that ONE camera's RTSP session
remakes -> single-cam fps-limit/watchdog event ~20-24s later -> audio
leg remade (self-heals). Everything else stays quiet.

Cost: one camera's audio+video stall ~20s, one watchdog restart,
self-healing. It is an intervention on the live house, so it is your
call. Value: (1) end-to-end confirmation of the mechanism from a
single probe (no page load involved) -- strengthens the upstream
issue's reproducer section; (2) establishes the baseline for
verifying fix (a) actually kills the wave when it lands.

If you OK it, any cycle can run it within a minute of a quiet-window
check. If you'd rather not touch the house, the mechanism is already
source-verified and the issue stands without it.

## Amendment 2 (2026-09-13 ~02:18 UTC, c278)

Solo-death sample #3 landed overnight: ext1 (.101) 00:29:04Z -- the
camera's OWN prudynt logged a new BackchannelStreamState TCP session
57s before frigate's watchdog restart. No reboot, no go2rtc WRN,
single camera, audio healed. This is the first CAMERA-SIDE witness of
the silent-splice class (samples #1/#2 had only frigate-side tails).
Doc: knowledge/aria/solo-death-sample3-2026-09-13.md.

What this changes for this filing: the issue draft's motivating
evidence now includes a camera-side observation of the exact mechanism
the draft describes (unconditional session remake splicing into open
producers). The falsifier ask is unchanged -- it would settle WHO
dialed (go2rtc reconnect vs external consumer) on demand. Draft is
ready; still waiting on your eyes before anything is posted.

## ADDENDUM (2026-09-14 02:20Z, aria c295): falsifier source amendment

The falsifier test (dialer-open: does a fleet remake occur without
viewer traffic?) must read the FRIGATE JOURNAL for viewer traffic, not
cameras.log. c294 mislabeled the 21:43:43Z wave as "no page load" by
reading cameras.log alone; the frigate journal shows the full Chrome
page load + 7x mic-probe GETs at that second. Viewer traffic is
invisible camera-side. Doc: knowledge/aria/c294-corrections-c295-2026-09-14.md
## Amendment 3 (2026-09-14 ~03:45 UTC, c297): falsifier source re-amended -- the container nginx log

c295's amendment (read the frigate journal, not cameras.log) is itself
superseded. c296 found that journald under the ext4 flood is NOT
trustworthy for absence claims: journalctl --since windows that
certainly had traffic returned "No entries". And cameras.log is
viewer-blind by design.

The correct source for viewer traffic is the nginx access log INSIDE
the frigate container:

  su - nacho -c 'podman exec frigate sh -c "tail -200 /dev/shm/logs/nginx/current"'

It sees ALL viewer traffic (page loads, paramless streams GETs, ws/mse).
c296 verified six-for-six: every "2h re-dial cadence" timestamp from
c295's census matches a page load with paramless streams GETs there.
The falsifier question (does a fleet remake ever occur without viewer
traffic?) should be answered against this log only.

Also: the "2h fleet-wide re-dial cadence" class is WITHDRAWN (c296) --
it was Nacho's browsing rhythm. The one open unexplained fleet event
remains the c265 go2rtc API hang wave.
