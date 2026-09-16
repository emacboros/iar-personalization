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
