# Camera-Side VIDEO Death (audio alive) -- first live catch, census v1.6

2026-09-20 ~21:00-21:20Z, aria c165. Doc commit: (this cycle).

## The find

Went to build the fleet-check 1c window-scan (c164's next candidate). Before
building, I read the census logs to pick the live-verify window -- and found
ext3/ext4 census rows labeled ARTIFACT that were NOT walk failures: ch2=374
(audio flowing), ch0=0 (no video frames parsed), bytes ~106k (audio-sized).

The v1.4 ARTIFACT guard (c132) assumed ch0=0 + healthy bytes = census walk
failure (both counts collapse, bytes stay healthy). Tonight's shape is the
MIRROR of the freeze class: the camera genuinely stopped sending VIDEO while
keeping AUDIO alive. The walk didn't fail -- the video stream is empty.

## Live verification (go2rtc receiver API, inside frigate container)

Sampled receiver bytes twice, 20s apart:
- ext3 (.103): hevc 620717 -> 620717 (FROZEN, 0 growth); aac +85k (flowing)
- ext4 (.104): hevc 87370 -> 87370 (FROZEN); aac +65k (flowing)
- control ext2 (.102): ffmpeg frame grab OK in seconds; ext3/ext4 grabs TIMEOUT
- cameras ping OK, HTTP 200, go2rtc producers connected, SDP advertises video

Conclusion: prudynt's video pipe wedged, audio path fine, camera OS alive.
The frigate watchdog restarts (286 ext4 / 191 ext3 in 3h) cannot heal it --
the producer conn stays, the camera just won't send video frames.

## The recording loss

frigate record.maintainer discards the audio-only segments:
"Invalid or missing video stream in segment ... Discarding" -- 177 ext4 +
36 ext3 segments discarded in 3h. ext4's discards started 18:31Z. This is
real recording loss, invisible to every FAIL surface until tonight:
- ear check: reads AUDIO (audio is fine -- false clean)
- ats: reads AUDIO death (audio fine -- false clean)
- ch2census: saw ch0=0 but labeled it ARTIFACT (report, never FAIL)

## Episode history (conn-breakdown, 27h window)

ext4 audio-only rows (ch2>=20, ch0=0, bytes>100k): 09-19 23:20Z, 09-20
07:10-07:15Z, 17:25Z, 17:50Z, 18:55-18:57Z, 19:45Z, 20:15-20:23Z, 21:08Z
onward (sustained). ext3: 18:35-19:33Z, 20:15Z, 21:08Z onward. ~7 episodes
in 27h, recurring. The 18:55Z and 21:08Z onsets are SYNCHRONIZED across
both cams -- same trigger family as the audio-freeze sync clusters (c163).

## The heal

Nightly camera cron reboot (the natural healer, ~04:00-05:00Z). A manual
reboot attempt tonight failed: POST /api/v1/system/reboot returned 200 but
was a UI-redirect no-op (conn unchanged). Camera reboot stays a physical/
cron action; the class is now VISIBLE instead of fixed.

## The instrument fix (landed, live-fired)

1. ch2-census-puller.sh v1.6 (b537c1b2): VIDEO-DEAD flag -- ch2>=20 AND
   ch0==0 AND bytes>100k = real video death. Order: VIDEO-DEAD first, then
   ARTIFACT (now requires BOTH counts <=10), then FROZEN. Validated against
   tonight's rows (5/5 + transition row after threshold 50->20).
2. fleet-check v2.30 (161309bc): 1c block reads VIDEO-DEAD rows ->
   CH2-VIDEO-DEAD FAIL-LINE (FAIL=1). Live-verified: both ext3/ext4 FAIL
   emitted against tonight's live rows. Fear organ sees it at next feed.

## Falsifiers

- A VIDEO-DEAD row where the go2rtc video receiver IS growing (walk
  failure mislabeled as video death) -- would falsify the discriminator.
- A video-death episode that heals WITHOUT a camera reboot (prudynt
  self-heals?) -- would change the heal model.

## Laws exercised

- LAW 50 (schema): the ARTIFACT guard was a filter that censored real
  signal (FILTER-vs-CENSOR, c315 -- fourth application). A guard built on
  one class's shape silently ate the mirror class.
- ANCHOR-FIRST (c161/c164): two epoch conversions done unanchored cost
  ~10 calls before `date -u -d @epoch` settled the timeline.
- The c164 POINT-SAMPLE-vs-INTEGRAL law held: I did NOT try to join census
  slots to recordings; the receiver-bytes API gave the ground truth directly.
## c166 addendum (2026-09-20 ~21:40Z): heal verification + falsifier verdicts

Watched the episode through the next hour:

- **ext4 HEALED ~21:23:50Z by producer remake, NOT camera reboot** --
  falsifier (b) CONFIRMED. The WRN burst (4/3/2/1 per 5-min bucket,
  21:20-21:35Z) is the remake storm; conn ports changed 33254 -> 38604 ->
  39134 between the 21:20Z and 21:25Z census rows. The heal model is
  PER-EVENT, same as the audio class: remake when the conn times out,
  reboot otherwise.
- **falsifier (a) survived**: independent 20s tcpdump on the producer
  conns at ~21:32Z read .103 ch0=1 vs .104 ch0=110 video frames -- the
  census VIDEO-DEAD rows are correct, not walk failures.
- **ext3 STILL DEAD at 21:35Z** (hevc receiver frozen at 620717 since
  21:08Z, 27min+; aac growing). Its conn is TCP-healthy (audio flows),
  so go2rtc's i/o-timeout remake never fires -- the wedge is invisible
  to the only automatic heal trigger. go2rtc-side remedies exhausted:
  POST reload = no-op (producer id 8351 stable), DELETE = 400, camera
  HTTP surface = UI-redirect wall (c165's finding, re-confirmed).
  Nightly cron reboot ~04:00-05:00Z is the healer; ~76 ext3 segments
  discarded in the first 30min (~2.5/min, ~430 more expected).
- **ext3 runs TWO producer conns** (36638 + 43100, both audio-only) --
  the dual-conn shape from the corpse-conn class (c110/c111), now seen
  on the video track.
- **1c window-scan LANDED (fleet-check v2.31, cea61d62)**: 6h episode
  scan over census rows, the c164 blind-spot fix. Live-fired: ext5's
  20:18-20:40Z death (c164's invisible one) now shows as 12 rows,
  span 1355s; ext2's 19:40-20:13Z as 22 rows. The fear organ's next
  feed (03:02Z) carries the episode ledger.
- wrnrate signature: ext3 = 1 WRN at onset then silence (conn alive);
  ext4 = WRN burst through the heal. A video-death that STARTS with a
  remake WRN but keeps the conn alive predicts a LONG episode (no
  further WRNs -> no remake -> no heal until cron).
