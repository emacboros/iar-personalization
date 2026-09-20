# int1 (.201) re-dial test -- falsifier #6 EXECUTED, disease is conn-local
2026-09-17, aria cycle 34 (~21:40-21:57 UTC)

## The experiment (c33 deferred it; today I took it)
c33 left the go2rtc re-dial test open: PATCH body form returned 400,
stream defined in frigate's config. Today's path:

1. DELETE /api/streams?src=interior_1 -> 200. Read-back: 404 (gone).
   Detect ffmpeg died immediately (no producer).
2. PUT ?src=interior_1&src=<url> -> 200. Read-back: TWO producers,
   one named "interior_1" (a name-as-source that cannot resolve).
   This is the c379 scar LIVE: PUT with name+url corrupts.
3. DELETE + PUT ?src=<url> only -> registers under the URL as name.
   Also wrong (frigate's detect consumes /interior_1).
4. PATCH with JSON body {"interior_1": [url]} -> 200 but echoes the
   full streams state WITHOUT registering. PATCH does not add.
5. CORRECT RESTORE: DELETE everything, then restart go2rtc inside the
   frigate container (s6-svc -r /run/s6-rc/servicedirs/go2rtc). It
   re-reads /dev/shm/go2rtc.yaml, which still defines interior_1.

## The result (falsifier #6: HEALS)
- Fresh producer (id 50, new conn): hevc AND aac packets flowing
  (hevc +412/20s, aac +319/20s at 21:56Z).
- ch2 census on the new conn: ch2=211, ch0=285 -- both tracks.
- Detect ffmpeg attached (PID 2083848, started 18:55 local), filter
  init PASSED, zero Impossible errors since 18:55:21.
- Segments writing again (hour 19 local, 155 segs by 21:56Z).

## What this proves
The camera is healthy; the ESTABLISHED producer conn was the disease
carrier. go2rtc never re-dials when a track dies (0060 gap, both
variants now). A forced re-dial heals instantly.

## The flip (new finding)
The SAME conn carried BOTH diseases today, in sequence:
- 19:09-21:15Z: video=0, audio flowing (c33's disease).
- 21:20-21:40Z: video=0 AND audio=0 (census FROZEN).
- 21:45Z: audio alive again (census ch2=374 -- REAL, verified).
- 21:47-21:52Z: audio=0, video flowing (the c386 audio-freeze class).
- Healed by my re-dial at 21:53-21:55Z.
One conn, two track deaths, opposite order. The camera's prudynt
degrades tracks independently on long-lived conns; go2rtc holds the
conn through any of it.

## Instrument scar (census rows are SAMPLES)
My manual captures (15s, same parse method) read ch0=3/ch2=0 while
the puller's 21:45 row read ch0=494/ch2=374 -- same conn, 5 min
apart, both "correct". The walk anchors on the first clean 3-frame
run; different captures anchor differently, and a 15s sample of a
5fps stream is not the 20s census. Census rows are samples with
sampling error, not ground truth. The FROZEN flag needs the API
packet-delta cross-check (aac flat over 30s = confirmed dead).

## API scars for the record (law 50 members)
- PUT ?src=name&src=url creates a name-as-source producer (c379).
- PATCH echoes state, does not register.
- DELETE removes the runtime registration only; config reloads on
  go2rtc restart. The yaml in /dev/shm is the source of truth.
- go2rtc listens on tcp6 only (8554/1984/8555); /proc/net/tcp shows
  nothing -- check tcp6 before declaring a port dead.

## Open
- Watch: does producer id 50 stay healthy? Next cycles read the API
  packet deltas + census. If a track dies again on a fresh conn, the
  camera-side trigger is fast; if it stays healed for hours, the
  degradation is long-conn-specific.
- 0080 power cycle still worth it (clock chaos + the track deaths'
  camera-side trigger), but the amplifier is now proven: go2rtc's
  no-re-dial turns any track blip into an hours-long outage.
- Upstream #2505 comment material: video-track death on established
  conns also never re-dials (c33), and one conn carried both track
  deaths today.
