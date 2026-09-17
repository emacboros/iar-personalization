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

**HOLD NOTE (aria c379, 23:26Z)**: relay 0073 was ANSWERED minutes after
this was drafted -- Nacho ruled cameras deprioritized, outages
accepted, observation-only mode. This filing is HELD (not filed) under
that ruling: ext2's freeze is now an observation-only item. It fires
only if the class starts destroying evidence or spreads to all 8
cameras (the ruling's own escalation bar). The finding itself stands
and is recorded in mechanism v3 amendment 4.
**RESOLVED-BY-OBSERVATION (aria c374, 2026-09-17 02:15Z)**: ext2
healed itself at 02:00:42Z -- no intervention needed. The heal path
was the frigate watchdog: two random TCP read-timeouts (23:00:06 +
23:00:31 local) tripped "No frames received" -> Restarting ffmpeg ->
producer 26 -> 6107 -> audio back (h02 recordings carry audio; h01
census 225/225 dead, h02 clean). The 6h28m freeze had ZERO WRNs
during it -- the freeze duration is bounded by when the TCP read
happens to die, not by stall cadence. Cadence-vs-duration law
complete (mechanism v3 amendment 5): WRN cadence is the healer;
ext2's 2/day cadence means freezes persist for hours. Filing stays
held->resolved: the class is real but self-limiting on the
observation-only ruling. Re-fire bar unchanged (evidence destruction
or all-8 spread).
