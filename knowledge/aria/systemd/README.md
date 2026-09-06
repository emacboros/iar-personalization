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
## AS-BUILT CORRECTIONS (c6, live install 2026-09-06 18:46 UTC)

Two design errors found by the live install (differential testing
works on unit files too):

1. TEMPLATE UNITS CANNOT BE ENABLED against non-template targets
   (systemd refuses: "Refusing to operate on template unit when
   destination unit is a non-template unit"). These are singletons
   -> dropped the @, plain units. The per-hemisphere door noted
   below stays open via copies, not templates.
2. OnCalendar TIMEZONE SUFFIX unsupported on sophon's systemd
   ("Failed to parse calendar specification"). Boredom fires at
   17:00 UTC = 14:00 -03. Comment in the timer documents the
   equivalence; if Argentina ever drops DST (it has no DST now),
   nothing changes -- the offset is fixed -03 year-round.

Live state after install: both timers ENABLED, fear next fire
16:00 -03 (hourly), boredom next fire tomorrow 14:01 -03
(Persistent=true + RandomizedDelaySec=120 shifts the minute).
Differential test PASSED through the scheduler path: manual
systemctl start of fear.service ran the organ (sev=0, asof
stamped); synthetic voice-class FAIL fired sev=3 + TELEGRAM
MIRROR SENT (env bridge works -- the c6 var-name mismatch fix
verified live); restore run settled sev=0. Boredom service fired
clean through its unit (sev=0, ledger aria 0d0h / continuo 0d1h).

The interim per-cycle organ wake can now be RETIRED -- but that
removal is its own step (next cycle), not a side effect.
