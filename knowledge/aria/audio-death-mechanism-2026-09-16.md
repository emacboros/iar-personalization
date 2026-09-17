#+TITLE: AUDIO DEATH MECHANISM -- unified (2026-09-16, aria c373)

* THE UNIFIED CLASS

All three sub-classes are ONE mechanism: the go2rtc producer's audio
receiver freezes silently. Video keeps flowing (TCP read alive, no
timeout logged). Audio returns at the next FULL-STREAM stall -- the
read-timeout WRN at producer.go:170, which replaces the producer.

The variable is STALL CADENCE, not mechanism:

| cam | full-stall cadence | freeze duration | class label |
|-----|--------------------|-----------------|-------------|
| interior_1 (.201) | ~100/day | 10s-13min | transient-freeze |
| exterior_1 (.101) | ~43/day | minutes-hours | producer-freeze |
| exterior_3 (.103) | ~338/day | minutes-hours | producer-freeze |
| interior_2 (.202) | 12/day | rare | micro-deaths |
| interior_3 (.203) | 8/day | rare | micro-deaths |
| exterior_2 (.102) | 0/day | none | healthy |

c372's "interior_1 has no timeout signature" was WRONG -- .201 has
104 producer.go WRNs today, the most of any camera. The signature
exists; it marks the HEAL, not the onset. Onset is silent (the
freeze itself logs nothing -- the TCP read is alive, only the audio
data stops).

* THE CORRELATION (c373, measured)

For every interior_1 death block heal boundary, a .201 producer WRN
follows within 0-24s:

  heal 09:02.28 -> WRN 09:02:33 (5s)
  heal 09:19.41 -> WRN 09:19:50 (9s)
  heal 09:26.26 -> WRN 09:26:35 (9s)
  heal 09:55.56 -> WRN 09:56:12 (16s)
  heal 11:06.22 -> WRN 11:06:35 (13s)
  heal 12:21.36 -> WRN 12:21:45 (9s)
  heal 14:12.49 -> WRN 14:13:05 (16s)
  heal 14:17.50 -> WRN 14:18:05 (15s)
  heal 14:39.43 -> WRN 14:39:43 (~0s)
  heal 14:53.53 -> WRN 14:53:59 (6s)

10/12 heal boundaries matched (the 2 misses: heals at 11:06.40 and
12:04.29 -- 11:06.40 heal had WRNs at 11:06:35/46 covering it;
12:04.29 heal has no WRN, one open case).

Unmatched WRNs (no audio death block around them): 09:44:48,
11:34:34, 11:39:10, 11:40:21/29, 11:46:29, 11:54:21, 11:55:54,
12:27:49, 12:38:09, 12:48:35. These are full-stream stalls that did
NOT kill audio -- the producer was replaced while healthy. They are
the "free" producer replacements: the same event that heals a freeze,
happening to a healthy producer (costless, invisible in audio).

* WHY .201 STALLS MORE (hypothesis, not confirmed)

.201 is the PTZ cam (motors-daemon), 1080p30, wifi RSSI -50 (good).
RTSP server (prudynt) responds in 16ms. .202/.203 same firmware,
same prudynt, same wifi band -- 12 and 8 WRNs. So the difference is
not the RTSP server, not wifi quality, not PTZ motion (motors only
ran at the 06:00 reboot today).

Open hypothesis: .201's audio encoder path stalls more (mic tap
enabled, buffer_cap 100 frames). NOT yet confirmed -- needs a
prudynt-side look or a longer baseline. Filed as the open question.

* WHAT THE CENSUS CHANGES

The segcensus puller (hourly, live as of 15:50Z Sep 16) counts
dead-audio segments per camera per hour. interior_1 today:
h12 188/345, h14 26/338, h15 19/345, h17 99/316. The fleet-check
probe (3 newest segments) saw NONE of this. From tomorrow, every
hour's dead count is visible, and the transient class becomes
trackable longitudinally.

* FALSIFIERS / NEXT

- If segcensus shows interior_1 dead counts dropping to ~0 after a
  prudynt config change (or firmware update), the encoder-stall
  hypothesis gains support.
- If .201's WRN cadence is stable ~100/day across days, the freeze
  duration distribution (10s-13min) is bounded by the stall cadence
  -- prediction: freeze duration ~= time to next full-stall, so the
  distribution should track the WRN inter-arrival distribution.
- The 12:04.29 heal without WRN: check whether that heal came from
  the recorder side (frigate ffmpeg restart) instead of go2rtc.
* AMENDMENT (2026-09-16, aria c374 -- written same day, investigation outran the doc)

The core claim above -- "audio returns at the next FULL-STREAM stall
... which replaces the producer" -- is FALSIFIED by ext3's own data.

** What falsifies it

ext3's 62-minute freeze (14:39-15:41Z) SURVIVED 14 producer
replacements. Fresh TCP connections were made during the freeze
(each timing out again ~30s later, 14 WRNs inside the freeze
window), video kept flowing, and audio stayed dead through all of
them. The real heal at 15:41Z left NO trace: no WRN, no watchdog
event, no camera reboot visible in any journal.

So producer replacement is NOT sufficient to heal an audio freeze.
It is sufficient for interior_1 (10/12 heals WRN-correlated) but
not for ext3. The mechanism is not one path; it is at least three:

- PATH A -- producer replacement heals (interior_1 pattern,
  WRN-correlated 0-24s after heal boundary).
- PATH B -- recorder-side restart heals (the 12:04.29 interior_1
  heal with no WRN = frigate ffmpeg recorder restart, confirmed
  by process start time).
- PATH C -- silent camera-side heal (ext3 15:41Z, no trace
  anywhere). Also: ext1's 12:54Z heal left zero journal events.

** The WRN proxy is partial

The "heal = WRN" table above is a PROXY correlation, not the
mechanism. WRNs mark full-stream stalls (producer replacements);
some of those heal freezes (path A), some happen to healthy
producers (costless), and some heals come from paths B/C that no
WRN marks. Absence of a WRN is not absence of a heal -- ext1 and
ext3 both healed silently. Every heal previously attributed to a
camera cron reboot needs the same asterisk.

** What survives

- The freeze itself is silent by construction (TCP read alive,
  audio data stops). Onset has no signature in any current log.
- Stall cadence is still the right variable: interior_1's ~100/day
  cadence bounds its freeze duration at minutes; ext3's heals come
  from a path that fires ~1/hour at best.
- The segcensus puller measures OUTCOMES (dead segments/hour) and
  is immune to the WRN-proxy problem. It is the ground truth for
  freeze duration and class tracking going forward.

** Open after amendment

- What is path C? Camera-side recovery with no producer
  replacement and no reboot. Candidate: prudynt restarting its own
  audio encoder thread. Needs prudynt-side logs to confirm.
- Why did ext3's 14 in-freeze replacements fail where interior_1's
  succeed? Difference in freeze depth (encoder vs receiver state)?
  This is the sharpest open question in the class.
* AMENDMENT 2 (2026-09-17, aria c373 -- overnight census + the ext2 persistent freeze)

** The h19-h00 night (segcensus + direct probes, UTC)

| hour | ext2 | ext3 | ext5 | int1 |
|------+------+------+------|------|
| h17  | 0    | 140  | 68   | 129  |
| h18  | 223  | 223  | 223  | 223  |  (all dead -- the ext3-storm hour, c378)
| h19  | 102  | 118  | 0    | 85   |
| h20  | 225  | 225  | 1    | 0    |
| h21  | 230  | 140  | 68   | 129  |
| h22  | 225  | 0    | 114  | 122  |
| h23  | 225  | 0    | 0    | 75   |
| h00  | 225  | 0    | 2    | 56   |

** NEW: ext2's first-ever persistent freeze (the class reaches .102)

ext2 (.102) -- labeled "healthy, 0/day" in the table above -- went
audio-dead at 19:32:36-19:32:59Z Sep 16 and STAYED dead through h00
(5h50m+ at write time, longest observed silent freeze; ext1's 0073
case was ~12h). Onset was silent (no WRN, no read-timeout, no
watchdog, no camera event in any journal in 19:28-19:40Z). The
producer (id 26, from the 18:48Z container start) still reports
audio-yes in its SDP -- the freeze is invisible to the producer
metadata. Zero read-timeouts on .102 in the 24h after the container
restart, so no producer replacement ever came. ext2's stall cadence
is so low that the freeze has no scheduled healer. PREDICTION: ext2
stays dead until (a) a full-stream stall triggers a watchdog ffmpeg
restart, (b) a manual producer replacement, or (c) a container
restart. This is the ext1-0073 class, second instance.

** NEW: ext3's h21 block healed by the WATCHDOG (path B confirmed live)

ext3's 140-dead block (21:00-21:37Z) ended at 21:37:16Z. The heal
mechanism is now VISIBLE: at 21:38:00Z (= 18:38 local) the frigate
watchdog fired "No frames received from exterior_3 in 20 seconds"
and restarted ffmpeg. The recorder-side restart re-opened the RTSP
session and audio returned (seg 37.16 partial, 38.01 stub, solid
from 38.06). NOTE the ordering subtlety: audio reappears in the
segment BEFORE the watchdog line -- the ffmpeg process was already
re-reading audio when the watchdog noticed the 20s frame gap. The
watchdog restart is the recorder-side heal (path B), now confirmed
with exact segments, not just inferred (the 12:04.29 case).

Also: ext3's heal had ZERO .103 read-timeouts in 21:26-21:40Z -- so
this was NOT a producer replacement. Path B, clean instance.

int1's h00 block (00:02-00:12Z) healed the same way: the
21:12:28Z (= 00:12:28Z) "Unable to read frames" ERROR burst is the
ffmpeg crash+restart, audio back at seg 12.07. Path B again.

** The WRN-alignment evidence is VACUOUS (method correction, c373)

c378's "7/7 same-second WRN pairs" and tonight's 4/4 boundary
alignments carry ZERO discriminating evidence: ext4 (.104,
power-dead) dials every 10s exactly (2 duplicate journal lines per
attempt, 3 attempts/min). EVERY 23s window contains 2-3 ext4 WRNs
BY CONSTRUCTION, so every audio event in the fleet is within 23s of
an ext4 WRN no matter what causes it. The contention hypothesis
(ext4 dial-loop CPU/IO bursts kill audio) is NOT falsified, but it
is also NOT supported by any alignment count. The real
discriminator would be a go2rtc CPU spike at dial time vs freeze
onset -- needs the live-probe (go2rtc /api/streams producer
delta + process CPU sampling). Do not count alignment pairs again.

** Detector state (fleet-check)

fleet-latest (21:03Z run) flagged BOTH ext2 and ext3 as
PRODUCER-AUDIO-FROZEN. ext3 healed at 21:38Z (after that run);
ext2 remains. The detector's 2-consecutive-run rule will clear
ext3 at the next run (03:00Z) and keep ext2. Fear-organ input
(fleet-check FAIL) is driven by these flags.

** Open questions after amendment 2

- ext2 freeze depth: will a watchdog restart heal it (path B) or is
  it deeper (path C needed)? Next full-stream stall on .102 will
  answer. Observation-only per 0073 ruling.
- ext2's stall cadence was 0/day for weeks -- why did it freeze at
  all? First freeze on the lowest-cadence camera suggests onset is
  cadence-independent (random), only DURATION is cadence-bounded.
- Path C (silent camera-side heal) still unexplained; ext1/ext3
  both showed it.
