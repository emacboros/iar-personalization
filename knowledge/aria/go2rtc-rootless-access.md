# Reaching go2rtc inside the rootless frigate container (from a root ssh session)

Written 2026-09-03, cycle 6, during the audio-loss forensics.
Cost ~5 failed attempts before the working path. Recording so the
next cycle pays zero.

## The problem

frigate runs as a ROOTLESS podman container under user nacho
(user 1000). From a root ssh session on sophon:

- `podman ps` (root) shows only the ROOT podman stack (zulip*).
  Frigate is invisible.
- `runuser -u nacho -- podman ...` FAILS with `cannot chdir to
  /root: Permission denied` -- the ssh session's HOME=/root
  poisons the su'd environment.
- `machinectl shell nacho@` WORKS: it starts a fresh login
  session with correct HOME and XDG_RUNTIME_DIR.

## The working recipe

```bash
ssh root@sophon 'machinectl shell nacho@ /bin/sh -c "
  export XDG_RUNTIME_DIR=/run/user/1000
  CID=\$(podman ps -q --filter name=frigate | head -1)
  podman exec \$CID curl -s http://localhost:1984/api/streams \
    > /home/nacho/out.json
"'
# then read /home/nacho/out.json as root
```

Notes:
- The nacho-session CANNOT write to /tmp (systemd PrivateTmp or
  perms -- got Permission denied); write outputs to /home/nacho/
  and read them from the root side.
- go2rtc API is unauthenticated on localhost:1984 inside the
  container network namespace.
- `machinectl shell` prints "Connected to the local host..." and
  "Connection to the local host terminated." around the output --
  filter with tail/grep if parsing.

## go2rtc /api/streams response shape (learned the hard way)

- `GET /api/streams` -> dict keyed by stream name; each entry has
  `producers` and `consumers` lists.
- `GET /api/streams?src=<name>` -> TOP-LEVEL object with
  `producers`/`consumers` keys directly (NOT nested under the
  name). Parsing it as if nested yields zero prods/cons.
- `producers[].receivers` is a LIST of receiver objects (not a
  dict): `{"id": N, "codec": {"codec_name": "aac", ...},
  "bytes": N, "packets": N, "childs": [...]}`. One receiver per
  negotiated media (hevc video + aac audio normally).
- `consumers[].receivers` is null for rtsp consumers; the
  consumer medias say `sendonly` (go2rtc SENDS to them).
- Cumulative byte totals since producer start: a receiver with
  36MB of aac bytes heard hours of audio. Delta over 10-15s
  tells you if it is STILL receiving.

## Interpretation cheat sheet (audio loss forensics)

- Producer SDP medias list audio offers -> camera still NEGOTIATES
  audio at connect time.
- Producer aac receiver bytes frozen + video receiver bytes
  flowing -> transport-level audio stop between camera and
  go2rtc, no renegotiation.
- Ear check (fleet-check.sh) NO-AUDIO on newest record segment ->
  the OUTPUT lacks audio; ground truth for "is the recording
  deaf" regardless of what any intermediate counter says.