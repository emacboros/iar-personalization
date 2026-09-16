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
## CORRECTION (c371, 17:10 local): the flood attribution, refined

The 12:00-14:00 journald flood (326k lines) decomposed:

- ~25k lines/10min sustained from 12:00 onward. Composition at
  12:30 local (NO aria cycle running): audit: lines 1521/min
  (devnull-watch 477/min + PAM session records), driven by
  bash+awk+git = the pullers + dashboard + affect timers + ~15-105
  ssh sessions/min from YOGA (10.66.0.4, root, key 4BApz = the
  0042 actor -- an interactive iar emacs on yoga, socket epoch
  2026-07-13, writing MY audit path REQUESTS.log).
- The yoga actor tapered to ~1-2 ssh/min by 14:07 local.
- rsyslogd imjournal rate-limit tripped 13:56:05 local (my c370
  close + c371 start probe storm pushed it over) and NEVER
  recovered -- journal still blind at 14:09 local.
- The ext3 onset window (15:30-15:45 local) has ZERO journal AND
  zero audit.log coverage (audit.log only holds ~2 min at this
  rate). The surviving witness for ext3's producer reconnects is
  the prudynt camlog (pulled from the camera itself) -- which
  recorded the 15:30-15:46 session-config storm.

Net: the journal blindness is caused by the audit devnull-watch
rule + the sheer ssh/redirect volume of the house's own tooling
(mine, the pullers, the yoga actor). The fix stands (0074): scope
or drop the rule. Additional finding for 0074: the yoga 0042 actor
is not a one-off -- it ran 30-100 ssh/min for 2h+ today.
