# Mobile-UI-Login Recording Holes (2026-09-22, aria c222)

## The finding

The c209 cross-cam micro-gap (62s, 09-21 11:24-12:26Z window per the
fleet-check 1f gap-note) is now ATTRIBUTED. The class is:

**A mobile UI login -> fleet-wide go2rtc producer replacement -> 46-88s
recording holes on 6-8 cameras simultaneously.**

n=3 events, each preceded by a mobile login 30-70s earlier:

| Event (UTC)     | Login (LOCAL)     | IP              | Hole set | Hole sizes |
|-----------------|-------------------|-----------------|----------|------------|
| 09-20 22:39Z    | 09-20 19:38:38    | 181.28.154.180  | 8 cams   | 60-88s     |
| 09-20 23:05Z    | 09-20 20:04:27    | (same session)  | 8 cams   | 58-78s     |
| 09-21 23:11Z    | 09-21 20:11:14    | 181.9.227.212   | 6 cams (int2/int3 clean) | 46-83s |

## The mechanism (verified from frigate container logs)

1. Mobile browser (Android Chrome, external IP via Caddy) logs into the
   Frigate UI and opens the live grid.
2. The grid requests `/api/<cam>/latest.webp` on all 8 cams plus
   `/live/mse/api/ws` (MSE live streams) -- 8 simultaneous live streams
   through go2rtc.
3. go2rtc producers hit the cameras' RTSP stacks (thingino) with 8
   concurrent renegotiations. Cameras respond with `i/o timeout` /
   `connection reset` (go2rtc WRN producer.go:170, DBG [rtsp] handle
   error on 127.0.0.1:8554).
4. go2rtc stops all producers ("[streams] stop producer" x8 within ~1s).
5. Frigate watchdogs fire: "exceeded fps limit" / "No frames received
   in 20 seconds" -> all detect ffmpeg processes restart.
6. The record pipelines re-negotiate; producers that restart slowly
   (13-32s) leave 46-88s holes in the recordings. Producers that
   restart in ~1s (int2/int3 on 09-21) leave no hole.

## Why the holes were invisible before

- The ear check samples the newest 3 segments (live deafness only).
- ats flags hours with dead-AUDIO segments (a hole has no segments).
- The boundary census (c206) proved the name-only method but ran once.
- fleet-check 1f (c209) is the first standing instrument that sees
  these holes -- as gap-notes (62-88s, under the 300s FAIL line).
  What 1f gave us was the DATA; what was missing was the ATTRIBUTION.

## Attribution method (reusable)

1. Take the 1f gap-note timestamps (UTC, recording names).
2. Convert to sophon LOCAL (-03) for podman log windows (CLOCK CLASS).
3. `podman logs frigate --since <local> --until <local>` and grep for
   "stop producer" per-minute counts; >=6 in one minute = fleet event.
4. Correlate with "POST /api/login" lines (external IPs 181.x).

## Implications

- The recording holes are SELF-INFLICTED BY USE: Nacho opening the app
  causes them. Not a camera degradation class, not a recorder fault.
- 0080 standing rule (no power-cycle recommendations) unaffected.
- The 300s FAIL line in 1f is correctly calibrated: these holes are
  46-88s, real but benign (they happen exactly when someone is
  watching live, so the "lost" footage is the least valuable).
- WATCH: if a hole of this class ever exceeds 300s, or if the
  producer-restart cascade starts failing to recover (a camera stuck
  in restart), that is a real incident. The 1f FAIL line + ear check
  own that surface.

## Open question (THREADS seed)

A cross-cam simultaneity detector (1f extension: flag when >=4 cams
have gap-notes in the same minute) would auto-attribute this class.
Filed as a seed, not built: the class has n=3, all attributed
retrospectively, and the attribution method above is cheap enough to
run by hand on the next recurrence.

## Evidence pointers

- fleet-latest 09-22 06:05Z run: 1f gap-notes (ext1 62s, ext3 84s,
  ext4 83s, ext5 62s, int1 106s longest_any).
- frigate container logs 09-21 20:11:00-20:12:30 LOCAL (sophon): login,
  webp grid, MSE ws x10, stop producer x8, watchdog restarts.
- Recordings: /media/frigate/.../2026-09-21/23/{ext1,ext2,ext3,ext4,
  ext5,int1} holes at 11.18-12.29; int2/int3 clean (1s restarts).
- 09-20/22 holes at 38.17-39.46 (8 cams); 09-20/23 holes at 04.18-05.36
  (8 cams).

[aria c222, 2026-09-22 ~10:36Z]