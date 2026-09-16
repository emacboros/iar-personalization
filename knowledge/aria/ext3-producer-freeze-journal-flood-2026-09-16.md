# ext3 producer-audio-freeze + sophon journal flood (c371, 2026-09-16)

## Finding 1: ext3 = second camera in the producer-audio-freeze class

Fleet 15:00Z (12:00 local) flagged ext3 WATCH run 1 (producer audio
stuck, video flowing). Segment forensics (ffprobe audio-frame counts,
sophon local time):

- Death #1: ~11:21 local (short segments 62/7 frames, then 378/336 =
  producer reconnects). Fleet 12:00 run caught the tail (3/3 sampled
  segments dead). Audio RECOVERED by 12:11 local (250-frame segments
  resume).
- Death #2: 15:30-15:37 local. Linear ring-drain decay: 260 -> 10
  frames over ~7 min (15:26.28 -> 15:36.58), then N/A (no audio
  stream) from 15:37 onward. Video keeps flowing. Camera alive
  (prudynt session-config storms 15:30-15:46 = reconnect churn).
- State: still dead at 16:59 local. Next fleet run 18:03 local should
  show run 2 = PRODUCER-AUDIO-FROZEN (detector escalates).

Class match with ext1 (0073): go2rtc producer audio receiver froze;
recorder encodes from a shrinking buffer then loses the track; video
unaffected. Heal = producer replacement (camera cron reboot) or
go2rtc restart. 0073 amended with the ext3 sighting.

## Finding 2: sophon journal is rate-limited -- my probes blinded it

The ext3 onset window (18:30-18:45Z) returned ZERO journal entries --
not because nothing happened, but because journald was dropping.

- 12:00-14:00 local: 326k journal entries (204k are audit: lines).
- rsyslogd 13:56:05 local: "imjournal ... begin to drop messages due
  to rate-limiting".
- 14:00-16:00 local: 293 entries. After: ~1 per probe.
- Flood source: the auditd devnull-watch rule logs EVERY open of
  /dev/null (key="devnull-watch"). Every ssh probe's 2>/dev/null,
  every fork of every probe script = 4-6 audit records. One
  history-clock-audit run = ~2500 proctitle records in 10 min
  (per-line git forks). My cycle's probe volume alone saturated it.

LAW (new, c371): an instrument's read of the host journal must first
verify the journal is not rate-limited -- an empty window under an
active rate-limit is a fake-clean record by construction (c358 class,
one level up: the host's own telemetry is the blinded instrument).

Fixes:
1. (Nacho, relay filed) Scope or drop the devnull-watch audit rule --
   it should watch WRITE opens (O_WRONLY) on /dev/null, not every
   open. Every ssh probe is a flood source.
2. (mine, next cycle) history-clock-audit.sh: batch the per-line git
   calls (one git process, many lines) -- it is the single largest
   fork source.
3. (mine) fleet-check journal-freshness check should read the
   rate-limit marker too (rsyslogd "begin to drop" = journal blind).
