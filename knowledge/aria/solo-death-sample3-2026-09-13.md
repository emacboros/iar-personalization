# Solo-death sample #3 -- ext1 00:29:04Z 2026-09-13 (c278)

## The event

- 00:29:04Z: ext1 (.101) prudynt logs TWO new BackchannelStreamState
  TCP configurations (session 4179292464, socket 17) -- a fresh RTSP
  session was accepted by the camera. Camera-side witness of a re-dial.
- 00:30:01Z (57s later): frigate watchdog restarts exterior_1's ffmpeg
  after "Unable to read frames" errors. No bad-cseq lines in the visible
  tail (unlike samples #1/#2 -- the splice garbage shape varies).
- NO camera reboot (zero init lines in syslog 00:29-00:30).
- NO go2rtc WRN for exterior_1 near the event (silent splice, exactly
  per #2404's reporter: clean re-dials log nothing).
- NO other camera affected (not a wave; zero backchannel lines fleet-wide
  in the 02:00-02:02Z window).
- Audio verified healed: 250 packets on the 02:17 local segment
  (17.17.mp4). The c264 heal law held (session remake heals).

## Classification

This is solo-death sample #3 -- the c269 class: a producer-side
session remake WITHOUT a camera reboot, invisible to go2rtc's own log,
healed by the watchdog's session remake. Distinguishing evidence vs
samples #1/#2 (int1 19:00:04, ext5 19:13-15Z on 09-12): this time the
CAMERA ITSELF logged the new session (BackchannelStreamState config
lines), which samples #1/#2 lacked (their camlog windows were rotated
away). The camera-side witness upgrades the class from inference to
observation: something re-dialed the camera at 00:29:04.

## What it is NOT

- NOT the nightly staircase: ext1's crontab hour is 01:00Z; the 01:01:11Z
  restart (22:01:11 local) IS the staircase (predicted, separate event).
- NOT the ext2 02:01:09Z event: that one has full boot lines at
  02:00:28Z (init scripts, onvif_notify_server, ledd) = the scheduled
  .102 staircase reboot at 02:00Z (second consecutive night, PASS).
  The splice signature after a reboot is EXPECTED (stale session dies
  with the reboot, new session splices) and self-heals (250 pkts at
  02:16 local). A THIRD mechanism, known and predicted -- not solo-death.
- NOT a wave: single camera, no fleet-wide same-second sessions.

## The census now

| sample | cam | time (UTC) | reboot? | camera witness | heal |
|--------|-----|-----------|---------|----------------|------|
| #1 | int1 | 09-12 19:00:04 | no | (camlog rotated) | watchdog remake |
| #2 | ext5 | 09-12 19:13-15 | no | (camlog rotated) | watchdog remake |
| #3 | ext1 | 09-13 00:29:04 | no | YES (new backchannel session) | watchdog remake |

## Open question (sharpened by #3)

WHO dialed? The camera accepted a new RTSP session at 00:29:04. If it
was go2rtc's reconnect logic, the trigger was a silent producer-session
drop (network blip / keepalive expiry) -- unobservable in go2rtc's log
per #2404. If it was something ELSE (another consumer, a probe), the
go2rtc log would also be silent. The falsifier in relay 0060 (single-cam
mic-probe GET) would distinguish: it produces the same camera-side
witness + watchdog restart on demand. Until run, the dialer's identity
stays open. The upstream issue draft (relay 0060) already carries this
class as its motivating evidence -- sample #3 strengthens it.

## Watch update

Solo-death watch continues: census method = bad-cseq/timestamp-garbage
ffmpeg tails + prudynt BackchannelStreamState lines in the camlog,
NOT WRNs in go2rtc logs (c269). The camlog puller (1-min) is now the
primary witness source -- it caught what the go2rtc log could not.