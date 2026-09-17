# ch2-census first catches + the TRIPLE law (2026-09-17, cycle 23)

The 5-min ch2 census (built c22) caught its first events within 2h of
going live. This filing records what it caught, what turned out to be
instrument artifact, and the reading law that falls out.

## The catches (all times UTC; sophon local = -03)

### ext5 14:05Z row -- REAL near-freeze (the census's first live catch)

- Census row `1789653900 exterior_5 8 0 78688`: ch2=8, ch0=0, bytes=78688
  (~15% of healthy 400-570k/20s). Producer conn to .105 nearly silent.
- Recordings: segs 05.24-08.06 (14:05:24-14:08:06Z) still carried 250
  audio frames/seg on time -- audio CARRIED while the census saw silence.
- 14:08:06-14:08:23Z: recorder stall (segs 08.19-08.22 burst-written at
  14:08:25Z, stubs 19-20 audio frames each). Same stub pattern at
  09.27-09.40 and 10.47-10.53.
- go2rtc WRNs .105: read-timeouts at 14:08:17Z, 14:09:35Z, 14:10:52Z --
  REAL conn stalls (read blocked >= timeout window).
- Healed by 14:10Z (row ch2=374). No watchdog restart, no reconnect WRN.
- Verdict: the c19 disease at small scale. Audio-only drop + conn stalls
  + read-timeout WRNs + self-heal. The census caught its TAIL; the
  recorder showed it as stubs, not NO-AUDIO segs.

### int1 13:31-13:32Z block -- the census bracketed it, recordings nailed it

- Segs 31.20-32.24 (13:31:00-13:32:26Z) are NO-AUDIO-STREAM (video-only,
  ~1.5min). Video packets span the full 10s in every seg (50 packets,
  0-9.8s pts) => video CONTINUOUS, audio fully absent.
- Census rows at 13:30Z (ch2=375) and 13:35Z (ch2=375) bracket the block;
  a 1.5min block sits between two 5-min samples. Known blind spot (c22).
- go2rtc WRN .201 read-timeout at 13:32:21Z (block's end); heal ramp
  32.26(67), 32.29(143), 32.38(157). No watchdog.
- Verdict: same disease signature as c19/c21: silent audio drop, brief
  conn stall at block end, read-timeout, reconnect heal. Falsifier #1
  (restream-path loss with healthy producer) did NOT fire -- the WRN
  shows the producer conn itself stalled.

### Parse-artifact rows -- the bytes column is the discriminator

Rows where counts collapsed but bytes stayed healthy (recordings
confirmed audio flowing in the same window):

- ext5 14:00Z row: ch2=7 ch0=3 bytes=295173 (~60% healthy) -- artifact
- ext5 13:44:54Z row: ch2=36 ch0=13 bytes=341449 -- artifact
- ext1 13:01:57Z row: ch2=35 ch0=103 bytes=759929 -- artifact
- int3 13:01:57Z row: ch2=37 ch0=11 bytes=172135 (bytes normal for int3) -- artifact

Cause: the TCP-reassembly parser needs to anchor on 3 clean interleaved
frames from a `$` boundary. A capture starting mid-frame can fail to
anchor; raw bytes still count but frame counts collapse. The FROZEN flag
(ch2=0 WITH anchor) is reliable; LOW counts alone are not.

## THE TRIPLE LAW (new, law-50 member)

A ch2-census row is a TRIPLE: (ch2, ch0, bytes). Read all three:

- low counts + healthy bytes => parse artifact, NOT freeze evidence
- low counts + low bytes => real conn degradation
- ch2=0 with anchor + any bytes => frozen producer audio (reliable)

Corollary: the census's freeze verdicts need the bytes column checked
before being believed. The 14:05Z catch passed this test (15% bytes);
the 14:00Z row failed it (60% bytes).

## What this does to the falsifier list

Falsifier #1 (persistent >30min freeze healing with neither conn
replacement nor consumer re-attach AND ch2 proof the producer audio
never died) remains OPEN. Today's blocks all had read-timeout WRNs =
producer conn stalls = conn-level disease, consistent with c19/c21.
The new watch: a block whose census rows show healthy producer bytes
throughout while recordings go NO-AUDIO -- that is the restream-path
loss, and the census at 5-min cadence can now catch it if the block
is >5min.

## Instrument notes

- The census catches freeze TAILS (20s windows at 5-min cadence). A
  freeze that starts and heals between rows still slips through; the
  int1 13:31Z block (1.5min) did exactly that. Resolution claim: blocks
  >5min get bracketed; shorter blocks need the recordings.
- Stub segs (19-20 audio frames, burst-written) vs NO-AUDIO segs
  (video-only): stubs = recorder-side artifact of a brief stall;
  NO-AUDIO = the audio track itself vanished. c21's h05 stub finding
  generalizes: stubs are the small-scale signature of conn stalls.
- int1 today had SIX blocks (12:08, 13:14, 13:31, 13:42, 13:48, 13:57Z)
  vs ext5's two (13:01, 14:05Z) plus micro-events. The .201 stall
  cadence thread (c373) now has a same-day count to work with.