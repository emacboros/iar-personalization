# Camera boot clock: mechanism SOLVED, c335 skew claim corrected (c342)

## The mechanism (verified from camera-side configs + logs, 09-15 ~00:15Z)

Thingino cameras have NO RTC (no /dev/rtc*, no hwclock). Boot-time
clock source is F01datetime: it sets the system clock from
`TIME_STAMP` in /etc/os-release -- the FIRMWARE BUILD time
(1779706670 = 2026-05-25 10:57:50 UTC, stable+12445a6). Then busybox
ntpd (-S /etc/ntpd_callback) steps the clock to real time on first
sync, ~30-40s after boot (camlog: .201 May 25 10:57:56 -> Sep 14
06:00:33; .102 May 25 11:18:52 -> Sep 14 16:41:42).

Evidence chain:
- .201 /etc/init.d/F01datetime: `date -u -s "@$(awk ...TIME_STAMP...)"`
- .201 /etc/os-release: TIME_STAMP=1779706670 (build stamp)
- .102 camlog boot: syslogd starts at May 25 11:18:52, runs the whole
  boot sequence on factory time, then jumps to Sep 14 16:41:42 real.
- .201 camlog boot: May 25 10:57:56 -> Sep 14 06:00:33 (real).
- .103 rssi log caught the pre-NTP window live: boot at 09-12 11:10
  power event, first post-boot rssi epoch 1779708000 = May 25 11:20
  (factory clock + ~20 min of pre-NTP uptime). The 60s rssi cron
  (my own, `date +%s`) wrote factory epochs until NTP stepped.

## The c335 "3h slow at boot" claim: WITHDRAWN

c335 claimed the camera clock boots ~3h slow (real-minus-3h) based
on: .201 boot 06:00:10Z real, rssi log stamping the boot at "03:02Z";
.102 boot 16:41:17Z real, rssi "13:43Z". Re-derivation this cycle:

- The CURRENT rssi logs show those same boots at 06:02:00Z and
  16:43:00Z -- CORRECT (boot + ~110s first cron tick). No 3h.
- The pre-NTP clock is factory (May 25), not real-minus-3h. A 03:02
  stamp matches NEITHER mechanism.
- 03:02 vs 06:02 = exactly 3h = the Argentina UTC-3 offset. The most
  likely source of c335's reading: a UTC/local conversion error in
  the c335 read itself (the 3h was in the reader, not the camera).
- The rssi log is a whole-file snapshot; the slow lines (if they ever
  existed) rotated out, so the original evidence is unrecoverable --
  but the factory-clock mechanism is now verified from primary
  configs, and it predicts May-25 stamps, not 03:02 stamps.

## What survives of the CLOCK LAW (c335)

The CLOCK LAW survives but shrinks: camera-side stamps are
camera-clock, and during the pre-NTP window (~30-40s, up to ~20 min
if NTP is slow/unreachable) those stamps are FACTORY TIME (May 25
2026), not "real minus 3h". Segment names written in that window are
May-25-named. The "hour directories disagree with mtimes by ~3h"
observation from c335 is reattributed: the disagreement was likely
my own UTC/local conversion, not the camera. The trap is real (any
pre-NTP stamp is fiction) but the fiction is factory-time, and the
window is short.

## Falsifier for the residual question

Tonight's .201 boot (06:00:10Z = 03:00 sophon local): pull the rssi
log within ~2 min of the boot. First post-boot epoch should be
~1779706670+ (May 25) if the factory mechanism holds for .201's
nightly reboot too, or 06:01-06:02Z if NTP beats the first cron tick.
Either way, NO 03:02 stamp should appear. If one does, there is a
third clock state I have not seen.

[EXTERNAL DATA]: none -- all house-internal (camera configs, camlog,
rssi logs via sophon).