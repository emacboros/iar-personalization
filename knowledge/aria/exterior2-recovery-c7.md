# Exterior_2 audio recovery + the deafness autopsy -- cycle 7 (2026-09-04 02:10-02:20 UTC)

## Headline

exterior_2 RECOVERED. Audio present again since 02:00:41 UTC Sep 4
(23:00:41 log-local). The flag-326 deafness lasted 21h34m
(04:27 UTC Sep 3 -> 02:00 UTC Sep 4). KNOWN_DEAF allowlist updated
(ext2 removed; int3 remains, zero-sample-since-forever).

## The autopsy (all times UTC unless noted)

**Onset -- 04:27 UTC Sep 3 (01:27 log-local), inside burst A.**
Segment-level walk: last audio-bearing segment 04:26:45, first
NO-AUDIO 04:27:07. Zero log lines at the boundary -- no WRN, no
watchdog event for .102 in the window. The camera's video never
dropped (segments continuous, sizes stable). The audio track died
inside a surviving session: the SILENT-TRACK-LOSS class, and the
onset of what we later called flag 326.

**Burst A context (c5's census, confirmed):** 01:00-01:53 log-local
brought 13 watchdog restarts (ext1 x2, ext5 x6, int1 x5) and WRN
i/o-timeout storms on .101 (29), .104 (4), .105 (31), .201 (31).
ext2 (.102) had NO WRNs in the burst -- but its audio died silently
mid-burst. Burst A hurt cameras in two different ways: loudly
(session loss) and silently (track loss inside a surviving session).

**The zombie period -- 04:27 UTC Sep 3 -> 02:00 UTC Sep 4.**
21.5 hours of: video flowing, audio track absent from every segment,
zero frigate/go2rtc log lines (the logless class). This is the state
flag 326 described. The producer SDP offered audio the whole time
(verified: current SDP has the full audio m-line set). The zombie
session received video but its audio track was dead.

**The heal -- 02:00 UTC Sep 4 (23:00 log-local).** Two go2rtc WRN
i/o-timeouts at 23:00:06 + 23:00:30 log-local killed the zombie
producer session (read-timeout-healer law, same mechanism that
healed ext4 in c38-39). Watchdog noticed no-frames 20s later
(23:00:36), restarted detect ffmpeg. Fresh session negotiated
audio correctly. First audio-bearing segment 02:00:41 UTC -- a
5-second recovery, one hop further than ext4's heal (watchdog
restart in between).

## The daily 23:00 log-local pattern (new finding)

.102's WRN pair at exactly 23:00 log-local appears on BOTH Sep 2 and
Sep 3. Two data points make a line, never a mechanism -- but a
daily-repeating read-timeout at the same wall-clock time is either
a network event at 02:00 UTC or the producer's own timeout horizon
coming due. The Sep 2 pair did NOT produce deafness (audio OK at
02:00 UTC Sep 3); the Sep 3 pair healed a 21.5h zombie. Same
trigger, different outcomes -- the difference is what the
renegotiation finds.

## Instrument lesson: the allowlist worked as designed

fleet-check v2.9's RECOVERY-on-known-deaf = FAIL design fired
exactly as intended: the recovery was loud (FAIL=1), not silent.
This is the second live-verified recovery catch (ext4 c38-39 was
the first). The allowlist is not a blindfold; it's a tripwire that
fires in the direction of news.

## What remains open

- interior_3: still SILENT (zero-sample-since-forever, different
  class -- camera never produced audio samples, not a session
  zombie). Stays allowlisted. Flag 326's int3 half stays open.
- The 23:00 log-local daily WRN pair on .102: watch for a third
  occurrence. If it repeats daily at 02:00 UTC, look for what
  else happens at 02:00 UTC (router? cron? DHCP lease?).
- Burst A cause: still unknown (flag 375, router scheduled-reboot
  question, unanswered).

## Method notes

- The loop-guard caught me mid-enumeration (13-call walk through
  hour-04 segments). The batched rewrite (one ssh, one loop,
  paste -sd" ") answered in one call what six calls were crawling
  toward. The guard is right: enumerate in ONE compound command.
- Segment names in hour directories are MM.SS-of-hour, not
  wall-clock minutes -- 26.45 = 26min45s into the hour. Reading
  them as wall-clock minutes cost a re-walk.
- podman logs has NO timestamps before Sep 2 00:01 (22.6k lines,
  ~3 days retention). All-time census = ~3-day census. The
  "all-time" numbers in the census file are bounded by log
  retention -- note the horizon.