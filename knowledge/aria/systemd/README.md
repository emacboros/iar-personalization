# aria-affect systemd units -- install notes (aria c6, 2026-09-06)

The affect host timers (roadmap queue #1, approved 2026-09-04).
Design correction this build: the original "piggyback the hourly
digest timer" premise was doubly dead -- sophon has no hourly
digest timer (c3 finding), and agent-failure-notify.sh is a
rate-limited telegram SENDER, not a timer (c6 finding, read the
source). Own timers, then.

## Files
- aria-affect-fear@.service + .timer -- hourly fear check
- aria-affect-boredom@.service + .timer -- daily boredom check
- aria-affect.env.example -- TG mirror env bridge (TG_TOKEN/TG_CHAT
  names the organ reads; values sourced from telegram.sh)

## Install (sophon, as root)
1. cp aria-affect.env.example /etc/aria-affect.env
   (verify TG_TOKEN matches
    /var/home/nacho/repos/i.ar/utils/telegram.sh before install;
    if the token rotates, update BOTH places or re-source)
2. cp aria-affect-*@.service aria-affect-*@.timer /etc/systemd/system/
3. systemctl daemon-reload
4. systemctl enable --now aria-affect-fear@.timer aria-affect-boredom@.timer
5. Verify: systemctl list-timers | grep aria-affect
6. Differential test (before removing the interim per-cycle wake):
   - synthetic FAIL through the timer path (c5's test, but fired
     by the scheduler): temporarily inject a fake FAIL file, run
     systemctl start aria-affect-fear@.service, check fear.log
     sev=3 + telegram mirror FIRES (env bridge is the new part),
     restore, check sev=0.
   - boredom: systemctl start aria-affect-boredom@.service, check
     boredom.log + CURRENT-AFFECT asof stamp.

## Interim regime (stays until differential test passes)
Both organs also run per-cycle at wake (cycle-me, manual). The
interim wake is REDUNDANT but harmless (emit-on-delta + asof
stamps make double-runs idempotent). Removal is its own step.

## Why templates (@) for single instances
Costs nothing, keeps the door open for per-hemisphere instances
(aria-affect-fear@aria / @continuo) if the one-mind clock ever
needs per-writer fear. The units are hemisphere-agnostic today.