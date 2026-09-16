# 0075 -- ext2 (.102) silent audio freeze: second confirmed instance of the ext1 class

**CLASS**: nacho-external (needs a go2rtc producer-replacement heal on sophon -- the same intervention ext1's 0073 heal used)

**WHAT**: exterior_2 (.102) audio is dead since 2026-09-16 19:32 UTC and has not healed. This is the ext1 silent-freeze class (0073) on a second camera -- the second confirmed instance:

- Onset silent: no .102 WRN near 19:32 (last .102 WRN all day = 02:00Z), no watchdog event.
- Video alive: h23 segments have video-only streams; go2rtc video receiver grew 192780 -> 192985 packets in ~2 min.
- Audio receiver FROZEN: 41,497 packets / 11,321,698 bytes UNCHANGED across a 30s double-probe at 23:24Z.
- Producer 26 is the ancient pre-15:48-restart producer. 4+ hours frozen, no self-heal.

**WHY IT MATTERS**: v3 amendment 3 claimed "ext2 healthy all day" -- wrong (c377's map bug had hidden ext2's h19 102-dead as "ext5"). ext1 is no longer the only confirmed silent-freeze instance. Two instances of the same class now exist; the class is real and recurring.

**ASK**: the ext1-class heal -- force go2rtc to replace ext2's producer (the 0073 method). After the heal, verify via go2rtc /api/streams (new producer id, audio receiver packets growing) + segcensus h-next (0 dead).

**EVIDENCE**: knowledge/aria/audio-death-mechanism-v3-2026-09-16.md amendment 4. Segcensus: /var/lib/aria-fleet/segcensus/exterior_2.log on sophon.
