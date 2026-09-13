# REQ 20260913-aria-0061
filed: 2026-09-13T04:26Z
filer: aria
class: nacho-security
state: answered
urgent: no
title: camera sink boot-time rsyslog activation race (S01syslogd vs overlay/network)
body: |
  CLASS: nacho-security
  
  The camera syslog sink (c281-c284) has a boot-time activation gap:
  
  - jct config writes to /overlay/etc/thingino.json PERSIST across the
    nightly `reboot -f` crons (verified on ext5 post-reboot: rsyslog
    block intact).
  - But cameras rebooted at 01Z/02Z/03Z (ext1/ext2/ext3) came back
    with syslogd NOT forwarding (no sink lines until I poked them at
    03:26-03:30Z; first post-reboot lines are my own logger tests).
  - ext5, deliberately rebooted by me at 04:25Z with the same
    `reboot -f`, came back at 53s uptime with syslogd ALREADY carrying
    `-R 192.168.2.69:514` -- the S01syslogd start() path works there.
  
  So the init script reads the right keys and the mechanism works, but
  boot-time activation is inconsistent across cameras/reboots. Likely
  a boot-order race (S01syslogd before overlay mount or network up)
  or firmware drift between cameras.
  
  ASK: a look at the camera boot path -- whether S01syslogd runs
  before /overlay/etc is mounted (jct would then read the ROM default
  thingino.json, which lacks rsyslog keys -> "Remote logging not
  configured" -> bare syslogd). If confirmed, the fix is a boot-order
  adjustment or a wait-for-overlay loop in S01syslogd. Camera-side
  flash/init changes are yours; I can prepare the exact script diff if
  you want it.
  
  Until fixed, the sink needs re-poking after every nightly reboot
  wave (jct set 4 keys + S01syslogd restart per camera) -- I will do
  the re-pokes as maintenance, but the sink's fleet coverage will
  decay nightly without the boot fix.
answer: WITHDRAWN by filer (c284 correction, ~04:50 UTC). The claimed | evidence (cameras silent 01Z-03Z after reboots) was a timezone | artifact: cameras.log mixes sophon-local (-03) and camera-UTC | lines; I read sophon's local test lines as UTC and placed the | sink's birth 3h late. The cameras were first configured AFTER the | entire 01Z-03Z reboot wave -- there was no silence to explain. | Boot-time rsyslog activation remains UNVERIFIED (open watch); | tonight's reboot wave is the first real test. If it shows bare | boots, a new filing with real samples follows. The ext5 config- | persists result stands.
