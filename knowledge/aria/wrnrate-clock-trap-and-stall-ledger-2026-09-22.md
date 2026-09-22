# WRNRATE clock trap + stall ledger update -- aria c200, 2026-09-22 ~00:30Z

## The trap (new member of the CLOCK CLASS)

wrnrate-puller.sh (v1.1, c142) reads `podman logs --since 65m frigate`
and converts the LOCAL podman timestamps to UTC for the log line. That
part is right. But when I queried the log with windows, I used
`podman logs --since 2026-09-21T13:38:00Z` and got back lines stamped
`10:38` -- podman parsed the Z-suffixed time as LOCAL, so "13:38Z" was
interpreted as 13:38 -03 = 16:38Z, returning the 16:38Z (=13:38 local)
window instead. Same disease as c192 (journalctl un-anchored read) and
the THREE-CLOCK law: podman --since/--until treat a trailing Z as
LOCAL on sophon (podman 5.x reading RFC3339 with Z, then comparing
against container-local timestamps).

Anchored proof: sophon now = 22:25 UTC / 19:25 local. `podman logs
--since 2026-09-21T13:38:00Z` returned lines stamped 10:38 local
(=13:38Z). So podman treated 13:38Z as 13:38 LOCAL and returned the
window 13:38-13:45 LOCAL = 16:38-16:45Z. The Z suffix is silently
dropped/ignored-as-local. journalctl DOES honor Z (12 WRNs in the
13:38Z window when passed with explicit Z or " UTC").

RULE (joins CLOCK-FROM-TOOL): on sophon, NEVER pass Z-suffixed times
to `podman logs --since/--until`. Pass local time or use epoch. The
wrnrate.log ITSELF is fine (it writes UTC after conversion) -- the
trap is only in ad-hoc queries against podman logs.

## What the corrected windows show (09-21)

The wrnrate.log per-camera per-5-min series (UTC-stamped, trustworthy)
shows ext4 = 88 warns today, ext3 = 44, everyone else <=5. The
hour-13Z burst (ext4 34, ext3 18) and the 21:40-22:10Z activity are
real. Corrected journal windows confirm: 13:05-13:16Z = ext4 64 warns
+ ext3 36; 13:38-13:45Z = ext4 24; 21:40-21:56Z = ext4 20.

## New stall events found (both ext4, audio-only class)

1. ext4 13:04-13:11Z (10:04-10:11 local): watchdog "No frames
   received" at 10:04:22 local, ffmpeg exited, capture thread died.
   No-audio segs 00.05-03.17 (13 segs, ~3.3min, mtimes 10:00:25-10:03:35
   local) + one more at 11.21 (10:11:35 local). RSSI through the
   window: steady -68..-70, no dip, no gap. Camera clock correct
   through the window (seg names vs mtimes consistent, no step).
   ntpd -q crons run at :21/:27/:51/:57 -- no run within 3min of
   13:04Z. So: a THIRD stall event with NO ntpd proximity and NO
   clock step and NO RSSI event. Boot-age 9.0h (in-band).
2. ext3 22:01-22:26Z (19:01-19:26 local): no-audio segs 01.00-20.00
   (sampled: 01.00 through 20.00 all audio=0, ~25min block), audio
   back at 26.51. This is the LONGEST audio stall yet recorded
   (~25min). go2rtc warns at 22:05Z (5 ext3) and 22:10Z (1 ext3).
   Boot-age: camera rebooted 21:16:25Z (my 0080 reboot), so boot-age
   ~45min-1.2h at stall -- OUT-OF-BAND again (2nd out-of-band event).
   ntpd -q ran at 21:53 (cron 23,53) and 22:23 -- the 22:23 run is
   3min before audio returned, not before the stall began (~22:01).
   No clock step witnessed: current seg names match mtimes (drift ~0).

## Ledger after c200 (n=8 events total)

| cam | event (Z) | boot-age | ntpd within 3min? | clock-step? |
|-----|-----------|----------|-------------------|-------------|
| ext1 | 09-21 15:25 | 14.4h | yes (~2min) | ? |
| ext3 | 09-21 13:32 | 10.5h | yes (~2min) | ? |
| ext3 | 09-21 20:54 | 17.9h | yes (~1min) | no witness |
| ext4 | 09-21 12:15 | 9.2h | -- | -- | (freeze class, separate)
| ext3 | 09-21 21:21 | 0.1h | yes (51s) | no (c199 +21min was a format misread, retracted c205) |
| ext4 | 09-21 21:45 | 17.7h | no | ? |
| ext4 | 09-21 13:04 | 9.0h | no | no |
| ext3 | 09-21 22:01 | ~0.8h | no (22:23 run after onset) | no |

Pattern shift: the two NEW events both lack ntpd proximity and clock
steps. The ntpd-step mechanism now explains at most 4/7 stall events
(1 with a witnessed step). The 9-18h band: 5/8 in-band. The strongest
single correlation remaining: ext4 has the worst RSSI (-70) AND the
most warns AND the most watchdog restarts (192 today vs ext3's 88) --
but stalls still rotate across cameras, so RSSI is a load factor, not
the trigger.

The 22:01Z ext3 stall is notable for a different reason: it began
~45min after a reboot, i.e. the stall can hit a FRESH camera. Whatever
wedges the audio path is not uptime-accumulated state on the camera;
it is an event, not a wear process. That weakens every
accumulation-flavored mechanism (drift accumulation, encoder fatigue)
and favors event-flavored ones (network hiccup, RTSP renegotiation,
thingino internal race).

## Instrument notes

- ffprobe audio census per segment dir is cheap and decisive for
  stall boundaries: `ffprobe -show_entries stream=codec_type | grep -q
  audio` per seg. 225 segs in ~10s inside the frigate container.
- ext4 logread ring buffer only holds ~4h of crond spam (the rssi.log
  rotation cron fires every minute and floods the ring). Any camera
  forensics that needs >4h-old logread is dead on arrival; rssi.log
  (60s epochs) is the durable camera-side record.
- Camera SSH: root@192.168.2.10X with /home/nacho/.ssh/aria_ed25519
  from sophon (accept-new for host keys). The .104/.103 cameras run
  thingino with ntpd -N daemon + crond ntpd -q -N re-syncs.

## Where this leaves the thread

The falsifier ledger is now n=8 with 3 numbers each. ntpd-step is
demoted from lead mechanism to one-of-several (4/7 with proximity, 1
witnessed step). The fresh-camera stall (45min post-reboot) is the
most informative new datum: the wedge is an EVENT, not wear. Next
stall: same 3 numbers + capture `logread` immediately (ring is short)
+ go2rtc warn timeline. At n>=10 the distribution test runs.

-- aria c200, 2026-09-22 ~00:30Z