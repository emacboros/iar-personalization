#!/bin/bash
# aria fleet-check v2.19 (2026-09-10, aria cycle 170)
# -------------------------------------------------------------
# One-command per-cycle patrol: ear check v2 + identity watch.
# Runs ON sophon as root. Executed from the i.ar container via:
#   ssh root@10.66.0.5 'bash -s' < fleet-check.sh
# The version in git IS the running version -- no copy on sophon.
# CALLER: use ssh timeout >= 300s (ear check alone runs ~2min).
#
# v2.19 (aria cycle 170, 2026-09-10 ~23:40Z): SEG-TAIL probe made
#   poison-aware (duration check). The v2.18 RECOVERY branch was
#   wrong-shaped for the poison: -sseof -2 decodes fine on a
#   poisoned-but-decodable segment (ffmpeg clamps the seek), so
#   "probe OK while flag set" fired a standing FALSE RECOVERY on
#   every run (live: 18:04 -03 feeder run, newest segment duration
#   412523s). Fix: pair the tail decode with an ffprobe duration
#   check (sane = 16.0s, threshold 60s). RECOVERY now requires BOTH
#   decode AND sane duration. Poisoned + flag = watch state (quiet);
#   poisoned + flag withdrawn = NEW sighting, fails loudly. The
#   KNOWN_FAULT contract is otherwise unchanged. Verified live on
#   sophon (canonical runner): poisoned newest segment (515652s) ->
#   watch state, no RECOVERY; sane-window segments (16.0s) ->
#   RECOVERY fires correctly.
# v2.18 (aria cycle 158, 2026-09-10): SEG-TAIL KNOWN_FAULT allowlist
#   (second application of the v2.9 KNOWN_DEAF contract). exterior_1
#   carries a camera-side video-timestamp poison (c151 diagnosis,
#   knowledge/aria/exterior1-timestamp-poison-c151.md) that makes the
#   SEG-TAIL probe flap FAIL/OK depending on which segment is newest.
#   The fault is filed (relay aria-0028, camera reboot = Nacho,
#   physical). Until it lands, every flap pulses the fear organ sev=2
#   on a KNOWN camera-side fault -- alarm fatigue on a real but
#   already-owned signal. Contract (identical to KNOWN_DEAF):
#   known-fault + SEG-TAIL FAIL = watch state (reported, not failed);
#   known-fault + SEG-TAIL OK = RECOVERY event, FAIL loudly (withdraw
#   the flag, update KNOWN_FAULT). A NEW fault on any other camera
#   fails as before. KNOWN_FAULT is a list of camera names.
# v2.17 (aria cycle 151): interior_3 RECOVERED (audio back, live-verified 09:47 UTC 09-10) -- allowlist emptied; it now FAILs if it goes deaf again. v2.16 (aria cycle 150): N-SEGMENT EAR CHECK (3-segment window).
#   The 2026-09-10 03:01Z fleet run FAILed on exterior_3 NO-AUDIO --
#   but the sampled segment (01.07.mp4, 0.79s) was a video-only STUB
#   written during a frigate watchdog restart (00:00:43 fps-limit kill
#   -> 00:01:08 restart -> corrupt segment discarded -> 0.79s stub).
#   Root cause chain: camera-side RTSP timeouts (.103, then a
#   multi-camera blip 04:06-04:07 -03) -> frigate restarts -> stub
#   segments during recovery. Census: 3 video-only stubs in ~1200
#   segments today (hours 00-07 UTC), ext3-only, all in restart/
#   timeout windows. The single-segment sample turns a seconds-long
#   transient into a FAIL -- c146's "flapping-camera noise" finding,
#   now with a mechanism. Fix: sample the newest 3 COMPLETED segments;
#   FAIL only if ALL lack audio (a stub among healthy neighbors is a
#   transient, reported but not failed). True deafness still fails:
#   all 3 stubs = no audio in ~48s of footage = real deafness.
#   Live-fired: healthy cam (3x ns=256000 -> OK), stub window replay
#   (neighbors healthy -> OK), negative case logic verified.
# v2.15 (aria cycle 119): interior_3 KNOWN_DEAF entry WITHDRAWN.
#   The v2.9-c30 premise "zero-sample since earliest recording
#   (2026-07-05)" was FALSIFIED (c118): recordings prove audio
#   08-30..09-03 ~08:00 -03; actual deaf window ~24h (09-03/08:00
#   -> 09-04/08:00 -03); recovery verified daily 09-05..09-09 AND
#   live RTSP (ns>0, real dB). v2.13's comment cited
#   retention-rotated recordings -- unverifiable and false.
#   interior_3 now FAILs if it goes deaf again (correct: new
#   deafness is news). KNOWN_DEAF is now EMPTY -- the allowlist
#   mechanism stays (a future deafness gets a flag + a
#   re-verification obligation, not a permanent pass).
#   Parse-shape note (c119): the dual n_samples lines (0 then
#   256000) are ffmpeg's PRE- and POST-decode volumedetect
#   instances on the mapped stream -- one filter instance, two
#   print points; tail -1 correctly reads the decoded count. The
#   "wrong stream block" worry from c118 resolved: recordings
#   carry ONE audio stream (aac 0:1); camera 203's ch1 RTSP is
#   404 (no second substream); all cameras ch0 = hevc+aac only.
# -------------------------------------------------------------
# One-command per-cycle patrol: ear check v2 + identity watch.
# Runs ON sophon as root. Executed from the i.ar container via:
#   ssh root@10.66.0.5 'bash -s' < fleet-check.sh
# The version in git IS the running version -- no copy on sophon.
# CALLER: use ssh timeout >= 300s (ear check alone runs ~2min).
#
# v2.10 (cycle 11): SILENT branch. interior_3 went deaf ~08:09 UTC
#   with a DIFFERENT signature: audio stream present, zero samples
#   (ext2/3/4 lost the stream entirely). volumedetect prints no dB
#   lines for zero-sample input -> old code printed empty "mean/max:"
#   and exited 0. Brand-new deafness sailed through green. Now:
#   empty dB output = SILENT = FAIL unless allowlisted. RECOVERY now
#   requires actual dB values, not mere stream presence.
# v2.13 (aria cycle 30): RECOVERY verdict hardened. The old dB-grep
#   (`grep -oE "-?[0-9.]+ dB" | head -2`) matched ffmpeg's INPUT
#   bitrate lines ("256 kb/s"), so a zero-sample segment (audio
#   stream present, n_samples=0) printed fake "mean/max: 256 kb/s"
#   and tripped RECOVERY -- FAIL=1 on a camera that never recovered.
#   interior_3 was THEN believed zero-sample-since-forever (a
#   premise falsified by c118 -- see v2.15 note). Fix: parse
#   n_samples from the LAST volumedetect block (the decoded one);
#   recovery requires n_samples>0 AND mean_volume present. SILENT
#   (n_samples=0) on known-deaf stays watch-state. Scar 29's
#   "unhandled output shape" class, one layer deeper.
# v2.12 (continuo cycle 12): agora-probe.sh retired -- this file is
#   now the sole copy of the voice-channel probe (twin-copy law:
#   a justified inline copy is still a twin; zero standalone
#   executions of the standalone on record).
# v2.9 (cycle 10): ear check v3 -- KNOWN_DEAF allowlist for the
#   ext2/3/4 audio loss (flags 262-270). Known-deaf NO-AUDIO no
#   longer fails the run; RECOVERY on a known-deaf cam fails loudly.
#   Exit code means something again. (Header said v2.7, roadmap
#   said v2.8 -- this is v2.9, discrepancy noted.)
# v2.7 (cycle 126): frigate event health check added (0c-c) +
#   FIX: the v2.6 restic block sat AFTER `exit $FAIL` -- dead code,
#   never ran. Moved before the summary. The instrument that watches
#   instruments had an unreachable check of its own.
# v2.6 (cycle 122): restic backup health check added (0c-b).
# v2.5 (cycle 77): agora voice-channel probe added (check 0c).
#   The 2026-09-01 redis MISCONF outage: Agora 500'd every authed
#   call for 6.5h while every service AROUND the channel was green.
#   agora-probe.sh (same dir) checks unauthed reachability + the
#   authed API path (auth -> redis rate limiter -> DB). Fails
#   closed if the keyfile is unreadable.
# v2.4 (cycle 74): bare-repo health check added. The 2026-09-01
#   mirror outage: root-owned files inside /home/git/repos/*.git
#   (from root file-path pushes) blocked the git user's mirror
#   pushes; rammstein bare silently fell behind sophon. Also the
#   hook root-guard landed cycle 74. Check: (a) zero root-owned
#   files in any bare, (b) sophon bare main == rammstein bare main
#   for iar-personalization (the repo the container pushes to).
#   Cheap (two git commands), catches the silent-divergence class.
# v2.3 (interactive session): /dev/null canary added. The
#   2026-09-01 incident: /dev/null became a regular file during
#   boot -2; sshd, podman/pasta, systemd, nft all degraded
#   silently for hours. A stat is cheaper than the outage it
#   detects. (Union merge: cycle-69's v2.2 body kept -- wait_file
#   retry, 120s per-call timeout, uptime-field caveat.)
# v2.2 (cycle 69): eye model downgraded gemma4:31b -> gemma3:4b.
#   Evidence: 2/2 perfect overlay reads (cycles 67 + 69) at
#   2.7GB VRAM, ~10-20s/call vs 60-90s for 31b. Fixes the
#   full-run timeout class AND removes the 31b segfault-storm
#   exposure (cycle 66: first load after eviction can segfault
#   llama-server). Per-call timeout 300 -> 120. Added
#   existence-check retry before vision reads (cycle 69 flake:
#   container->host cp visible late once; cause unresolved,
#   workaround cheap).
# v2.1: vision call retries on HTTP 5xx. Frigate GPU detection
# (cycle 64) reduced free VRAM to ~6.5 GiB; gemma4:31b (19.1 GiB
# predicted) no longer fits fully on GPU. First load attempt after
# eviction can segfault llama-server (observed live 2026-09-01
# 01:59 UTC); ollama's retry loads partial-offload and works.
# The watch must not go blind exactly when a restart re-tossed
# the camera-identity coin.
#
# Checks:
#   0. /dev/null CANARY: must be char device 1:3. Anything else
#      = the incident class; flag loudly.
#   0b. GIT BARE HEALTH (v2.4): root-owned files in bares = 0;
#       sophon iar-personalization main == rammstein main.
#   1. EAR CHECK v2: per camera, newest recording segment ->
#      age (STALE if >120s) + audio track presence + volume.
#   2. IDENTITY WATCH: direct RTSP grab of .101 vs frigate's own
#      newest exterior_1 segment tail -> vision-read both overlays
#      (gemma3:4b, think off) -> MATCH / RACE / VISION-UNCLEAR.
#      This failure class (same IP, two cameras, session-age
#      decides) is invisible to metadata instruments. Pixels only.
#      NOTE (cycle 69): the overlay "Uptime" field resets when a
#      second RTSP session connects (i.e., when THIS check's
#      direct grab runs). It is encoder uptime, not system
#      uptime -- inadmissible as camera-health evidence, same
#      tier as the frozen OSD clocks.
#   3. ARP: are .103/.104 reachable (cameras staying home)?
#
# Exit: 0 = all green, 1 = anything flagged. Output is compact,
# one line per camera + verdict lines. Cleanup: temp jpgs removed
# same-run (container /tmp and storage bind).
# ------------------------------------------------------------
set -u
R=/home/nacho/containers/frigate/storage/recordings
P="podman --url unix:///run/user/1000/podman/podman.sock"
CAMERAS="exterior_1 exterior_2 exterior_3 exterior_4 exterior_5 interior_1 interior_2 interior_3"
TODAY=$(date -u +%Y-%m-%d)
FAIL=0

echo "== fleet-check $TODAY $(date -u +%H:%M:%S) UTC =="

# --- 0. /dev/null canary (2026-09-01 incident class) ---
echo "-- /dev/null canary --"
nulf=$(stat -c '%F' /dev/null 2>/dev/null)
nudev=$(stat -c '%t:%T' /dev/null 2>/dev/null)
if [ "$nulf" != "character special file" ] || [ "$nudev" != "1:3" ]; then
  echo "/dev/null BROKEN: ${nulf:-missing} dev=${nudev:-none} -- sshd/podman/systemd degrade silently when this is wrong"
  FAIL=1
else
  echo "/dev/null ok (char 1:3)"
fi

# --- 0b. git bare health (v2.4, cycle 74 mirror-outage class) ---
echo "-- git bare health --"
rootowned=$(find /home/git/repos -user root 2>/dev/null | wc -l)
if [ "$rootowned" -gt 0 ]; then
  echo "BARE OWNERSHIP: $rootowned root-owned files in /home/git/repos -- git-user mirror pushes will fail silently"
  FAIL=1
else
  echo "bare ownership ok (0 root-owned)"
fi
sb=$(git -C /home/git/repos/iar-personalization.git -c safe.directory='*' rev-parse refs/heads/main 2>/dev/null)
rb=$(cd /tmp && runuser -u git -- env HOME=/home/git timeout 20 git ls-remote git@10.66.0.1:/home/git/repos/iar-personalization.git refs/heads/main 2>/dev/null | cut -f1)
if [ -z "$sb" ] || [ -z "$rb" ]; then
  echo "BARE COMPARE FAIL (sophon=$sb rammstein=$rb)"
  FAIL=1
elif [ "$sb" != "$rb" ]; then
  echo "BARE DIVERGED: sophon=$sb rammstein=$rb -- mirror leg broken, push from a clone to re-sync"
  FAIL=1
else
  echo "bares in sync ($sb)"
fi

# --- 0c. AGORA VOICE CHANNEL (v2.5, cycle 77; v2.12 sole copy) ---
# The 2026-09-01 redis MISCONF incident: Agora 500'd 6.5h, no
# instrument watched the channel itself. Probe inlined (reviewer
# C1: fleet-check runs via `ssh bash -s < file`, $0=bash, so
# script-relative paths resolve wrong on sophon). v2.12 (continuo
# cycle 12): agora-probe.sh RETIRED -- this block is the ONLY copy
# of the probe logic (zero standalone executions on record; the
# standalone was a twin waiting to drift). Unauthed reachability +
# authed API (auth -> redis rate limiter -> DB), fails closed.
echo "-- agora voice channel --"
APCONF=/var/home/nacho/repos/agora/bot/aria-cycle.conf
APSITE=https://agora.randazzo.ar
apcode=$(timeout 15 curl -s -o /dev/null -w '%{http_code}' "$APSITE/api/v1/messages?anchor=newest&num_before=1&num_after=0" 2>/dev/null)
case "$apcode" in
  200|400|401|403) echo "agora unauthed GET: HTTP $apcode (app server alive)" ;;
  000) echo "agora unauthed GET: TIMEOUT/UNREACHABLE"; FAIL=1 ;;
  *) echo "agora unauthed GET: HTTP $apcode -- unexpected"; FAIL=1 ;;
esac
if [ ! -r "$APCONF" ]; then
  echo "agora authed GET: keyfile $APCONF unreadable -- cannot verify primary signal, FAILING CLOSED"; FAIL=1
else
  APKEY=$(awk -F'= *' '$1 ~ /^key *$/ {sub(/\r$/,"",$2); print $2; exit}' "$APCONF")
  APBODY=$(mktemp) || APBODY=/dev/null
  apcode=$(timeout 15 curl -s -o "$APBODY" -w '%{http_code}' \
    -u "aria-cycle@agora.randazzo.ar:${APKEY}" \
    "$APSITE/api/v1/messages?anchor=newest&num_before=1&num_after=0" 2>/dev/null)
  if [ "$apcode" = "200" ]; then
    apresult=$(python3 -c 'import json,sys
try:
    d=json.load(open(sys.argv[1]))
    msgs=d.get("messages",[])
    print("success" if (d.get("result")=="success" and msgs) else "empty-or-failed")
except Exception:
    print("parse-error")' "$APBODY" 2>/dev/null)
    [ "$APBODY" != "/dev/null" ] && rm -f "$APBODY"
    if [ "$apresult" = "success" ]; then
      echo "agora authed GET: HTTP 200 result=success -- voice channel HEALTHY"
    else
      echo "agora authed GET: HTTP 200 but result=$apresult -- API-level problem"; FAIL=1
    fi
  elif [ "$apcode" = "000" ]; then
    echo "agora authed GET: TIMEOUT/UNREACHABLE"; FAIL=1
  elif [ "$apcode" = "401" ] || [ "$apcode" = "403" ]; then
    echo "agora authed GET: HTTP $apcode -- AUTH FAILED (key revoked? identity broken?)"; FAIL=1
  elif [ "$apcode" = "429" ]; then
    echo "agora authed GET: HTTP 429 -- rate limited (redis limiter ALIVE; back off)"; FAIL=1
  else
    echo "agora authed GET: HTTP $apcode -- VOICE CHANNEL DOWN (redis MISCONF / app / proxy class)"; FAIL=1
  fi
fi

# --- 1. EAR CHECK v3 (age + audio, known-deaf allowlist) ---
# v2.11 (cycle 16): interior_1 added (deaf since 09:30 UTC boundary).
# v2.9 (cycle 10, 2026-09-03): KNOWN_DEAF allowlist. The ext2/3/4
# audio loss (flags 262-270) is camera-side, reported, awaiting
# frigate restart / firmware. Without the allowlist every run
# exits 1 and the exit code stops meaning anything. Design:
# known-deaf + NO-AUDIO = expected, no fail; known-deaf + AUDIO =
# RECOVERY event, FAIL loudly (withdraw flags, update list).
# NO-AUDIO on any other camera = FAIL as before (new deafness).
echo "-- ear check --"
# v2.15 (aria cycle 119): interior_3 WITHDRAWN -- the "zero-sample
# since earliest recording" premise was falsified by c118 (audio
# existed 08-30..09-03; real deaf window 09-03/08:00 ->
# 09-04/08:00 -03; recovery live-verified). It now FAILs if it
# goes deaf again (correct: new deafness is news). KNOWN_DEAF is
# empty; the allowlist mechanism stays for future deafness.
# v2.14 (aria cycle 7): ext2 RECOVERED live-verified 2026-09-04
# 02:00 UTC (read-timeout heal + watchdog restart; see
# knowledge/aria/exterior2-recovery-c7.md). Removed from allowlist;
# it now FAILs if it goes deaf again.
# v2.13 (aria cycle 30): ext3/ext4/int1 RECOVERED live-verified
# (n_samples>0, real dB) 2026-09-03 ~16:57 UTC. Removed from
# allowlist; they now FAIL if they go deaf again (correct: new
# deafness is news).
KNOWN_DEAF=""
# v2.18: known camera-side faults that make specific probes flap.
# ext1 = video RTP timestamp poison (c151; relay aria-0028 open).
# Withdraw by emptying the list AFTER the reboot is verified.
KNOWN_FAULT_EXT1_SEG="exterior_1"
for cam in $CAMERAS; do
  # v2.16: newest 3 COMPLETED segments (tail -4 | head -3: skip the
  # in-progress newest, which frigate is still writing -- a partial
  # segment can legitimately lack audio mid-write).
  segs=$(find $R/$TODAY -path "*$cam*" -name "*.mp4" 2>/dev/null | sort | tail -4 | head -3)
  if [ -z "$segs" ]; then echo "$cam NO-SEGMENT"; FAIL=1; continue; fi
  n=$(echo "$segs" | tail -1)
  age=$(( $(date +%s) - $(stat -c %Y "$n") ))
  if [ "$age" -gt 120 ]; then echo "$cam STALE(${age}s)"; FAIL=1; fi
  # v2.16 audio verdict: probe the 3-segment window. noaudio counts
  # segments with NO audio stream OR zero decoded samples (both are
  # "no usable audio"). FAIL only if ALL 3 are dead -- a single stub
  # among healthy neighbors is a restart transient (reported, not failed).
  noaudio=0; nprobe=0; last_mv=""; last_mx=""
  for seg in $segs; do
    nprobe=$((nprobe+1))
    aout=$(timeout 30 ffmpeg -hide_banner -i "$seg" -map 0:a -af volumedetect -f null - 2>&1)
    if echo "$aout" | grep -q "matches no streams"; then
      noaudio=$((noaudio+1)); continue
    fi
    ns=$(echo "$aout" | grep -oP "n_samples: \K[0-9]+" | tail -1)
    if [ -z "$ns" ] || [ "$ns" -eq 0 ]; then noaudio=$((noaudio+1)); continue; fi
    mv_db=$(echo "$aout" | grep -oP "mean_volume: \K[-0-9.]+" | tail -1)
    mx_db=$(echo "$aout" | grep -oP "max_volume: \K[-0-9.]+" | tail -1)
    [ -n "$mv_db" ] && { last_mv="$mv_db"; last_mx="$mx_db"; }
  done
  if [ "$nprobe" -eq 0 ]; then
    echo "$cam age=${age}s PROBE-EMPTY (segs list empty)"; FAIL=1
  elif [ "$noaudio" -eq "$nprobe" ]; then
    # ALL sampled segments lack audio = real deafness (or known-deaf)
    if echo " $KNOWN_DEAF " | grep -q " $cam "; then
      echo "$cam age=${age}s NO-AUDIO (known-deaf, watch state; $noaudio/$nprobe dead)"
    else
      echo "$cam age=${age}s NO-AUDIO ($noaudio/$nprobe segments dead)"; FAIL=1
    fi
  elif echo " $KNOWN_DEAF " | grep -q " $cam " && [ -n "$last_mv" ]; then
    # v2.13 contract preserved: RECOVERY on a known-deaf cam fails loudly
    echo "$cam RECOVERED: audio present again (mean/max: $last_mv dB $last_mx dB) -- update KNOWN_DEAF, withdraw flags"; FAIL=1
  elif [ -n "$last_mv" ]; then
    # healthy audio in the window (partial stubs reported inline)
    if [ "$noaudio" -gt 0 ]; then
      echo "$cam age=${age}s mean/max: $last_mv dB $last_mx dB (transient: $noaudio/$nprobe stub segments)"
    else
      echo "$cam age=${age}s mean/max: $last_mv dB $last_mx dB"
    fi
  else
    # audio streams present with samples but no mean_volume parsed:
    # unhandled shape, fail closed (v2.13 discipline)
    echo "$cam age=${age}s VOLUME-UNPARSED (samples>0, no mean_volume)"; FAIL=1
  fi
done

# --- 2. IDENTITY WATCH (pixels, not metadata) ---
echo "-- identity watch --"
WDIR=/tmp/aria-watch
$P exec frigate sh -c "mkdir -p $WDIR && rm -f $WDIR/*.jpg /media/frigate/aria_watch_*.jpg 2>/dev/null" 2>/dev/null

# 2a. direct grab of .101 (container ffmpeg: host ffmpeg lacks hevc)
grab=$($P exec frigate sh -c "timeout 25 /usr/lib/ffmpeg/7.0/bin/ffmpeg -y -loglevel error -rtsp_transport tcp -i 'rtsp://thingino:thingino@192.168.2.101/ch0' -frames:v 1 $WDIR/direct.jpg && cp $WDIR/direct.jpg /media/frigate/aria_watch_direct.jpg && echo OK" 2>/dev/null)
if [ "$grab" != "OK" ]; then echo "DIRECT-GRAB FAIL (is .101 up?)"; FAIL=1; fi

# 2b. ext1 newest segment tail (host path -> container path)
n=$(find $R/$TODAY -path "*exterior_1*" -name "*.mp4" 2>/dev/null | sort | tail -1)
if [ -n "$n" ]; then
  nc="${n/\/home\/nacho\/containers\/frigate\/storage//media/frigate}"
  tail=$($P exec frigate sh -c "timeout 25 /usr/lib/ffmpeg/7.0/bin/ffmpeg -y -loglevel error -sseof -2 -i '$nc' -frames:v 1 $WDIR/seg.jpg && cp $WDIR/seg.jpg /media/frigate/aria_watch_seg.jpg && echo OK" 2>/dev/null)
  # v2.19 (c170): the tail probe is POISON-BLIND. With a poisoned
  # container duration (e.g. 114h of metadata for 16s of video),
  # -sseof -2 still seeks to a decodable region -- ffmpeg clamps the
  # seek into the real GOPs. The probe passes on poisoned segments,
  # so v2.18's RECOVERY branch (probe OK while flag set) fired a
  # standing FALSE RECOVERY on every run of a poisoned-but-decodable
  # camera (live: 18:04 -03 feeder run, duration 412523s, "SEG-TAIL
  # RECOVERED"). Fix: pair the decode with a duration check. Sane
  # ext1 segments are 16.0s; poisoned are >=28h (or transient stubs
  # <6s, which already fail the tail decode). Threshold 60s.
  segdur=$($P exec frigate sh -c "/usr/lib/ffmpeg/7.0/bin/ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 '$nc'" 2>/dev/null | tail -1)
  segpoisoned=0
  case "$segdur" in
    ""|*[!0-9.]*) segpoisoned=0 ;;  # unparsable: do not double-alarm, the decode result stands
    *) awk -v d="$segdur" 'BEGIN{exit !(d>60)}' && segpoisoned=1 ;;
  esac
  if [ "$tail" != "OK" ]; then
    # v2.18: known-fault watch state (ext1 timestamp poison, aria-0028
    # pending). Reported, not failed -- the alarm is owned. RECOVERY
    # (probe OK while fault listed) fails loudly below.
    if [ -n "$KNOWN_FAULT_EXT1_SEG" ]; then
      echo "SEG-TAIL (known-fault ext1 timestamp poison, watch state; aria-0028 pending)"
    else
      echo "SEG-TAIL FAIL"; FAIL=1
    fi
  elif [ "$segpoisoned" = "1" ]; then
    # v2.19: decodes clean but duration metadata is poisoned. This is
    # the fault STILL PRESENT, not a recovery. Watch state if the
    # flag is set; if the flag was withdrawn, this is a NEW sighting
    # and must fail loudly (the poison came back after a verified heal).
    if [ -n "$KNOWN_FAULT_EXT1_SEG" ]; then
      echo "SEG-TAIL (known-fault ext1 timestamp poison, watch state; aria-0028 pending)"
    else
      echo "SEG-TAIL FAIL (timestamp poison returned: duration=$segdur)"; FAIL=1
    fi
  else
    if [ -n "$KNOWN_FAULT_EXT1_SEG" ]; then
      echo "SEG-TAIL RECOVERED: ext1 segment tail decodes clean AND duration sane ($segdur s) -- withdraw the known-fault flag, update KNOWN_FAULT_EXT1_SEG"; FAIL=1
    fi
  fi
else
  echo "SEG-TAIL FAIL (no ext1 segment)"; FAIL=1
fi
# 2c. wait for host-side visibility of the copied frames, then
#     vision read both, compare overlay cam names.
#     (cycle 69: one cp was not immediately visible on the host
#     bind mount; retry-until-exists, 6 x 2s, then give up.)
wait_file() {
  for i in 1 2 3 4 5 6; do [ -f "$1" ] && return 0; sleep 2; done
  return 1
}
if [ "$grab" = "OK" ] && [ "${tail:-}" = "OK" ]; then
  HD=/home/nacho/containers/frigate/storage
  if ! wait_file $HD/aria_watch_direct.jpg; then echo "DIRECT-JPG NOT VISIBLE ON HOST"; FAIL=1; fi
  if ! wait_file $HD/aria_watch_seg.jpg;    then echo "SEG-JPG NOT VISIBLE ON HOST"; FAIL=1; fi
fi
if [ -f /home/nacho/containers/frigate/storage/aria_watch_direct.jpg ] && [ -f /home/nacho/containers/frigate/storage/aria_watch_seg.jpg ]; then
  python3 - <<'EOF'
import base64, json, re, sys, time, urllib.request, urllib.error
def look(path):
    img = base64.b64encode(open(path, "rb").read()).decode()
    req = urllib.request.Request("http://127.0.0.1:11434/api/chat",
        data=json.dumps({"model": "qwen3.6:35b-a3b", "stream": False, "think": False, "keep_alive": -1,
            "options": {"num_predict": 120},
            "messages": [{"role": "user",
              "content": "Security camera frame. Quote the overlay text exactly (camera name and timestamp). Then one sentence of scene.",
              "images": [img]}]}).encode(),
        headers={"Content-Type": "application/json"})
    r = json.load(urllib.request.urlopen(req, timeout=300))
    return r["message"]["content"]
def look_retry(path, tries=3):
    last = None
    for i in range(tries):
        try:
            return look(path)
        except urllib.error.HTTPError as e:
            last = e
            time.sleep(10)  # ollama reload after eviction/segfault takes ~10-20s
    raise last
try:
    d = look_retry("/home/nacho/containers/frigate/storage/aria_watch_direct.jpg")
    s = look_retry("/home/nacho/containers/frigate/storage/aria_watch_seg.jpg")
    dc = re.findall(r"cam\d+-\d+", d, re.I)
    sc = re.findall(r"cam\d+-\d+", s, re.I)
    print("direct overlay:", d.replace("\n", " ")[:120])
    print("segment overlay:", s.replace("\n", " ")[:120])
    if dc and sc:
        if dc[0].lower() == sc[0].lower():
            print(f"VERDICT: MATCH ({dc[0]}) -- no race")
        else:
            print(f"VERDICT: RACE -- direct={dc[0]} frigate={sc[0]}")
            sys.exit(1)
    else:
        print("VERDICT: VISION-UNCLEAR (no overlay name parsed)")
        sys.exit(1)
except Exception as e:
    print(f"VERDICT: VISION-FAIL ({e})")
    sys.exit(1)
EOF
  [ $? -ne 0 ] && FAIL=1
fi

# cleanup: same-run, both sides
$P exec frigate sh -c "rm -f $WDIR/*.jpg /media/frigate/aria_watch_*.jpg" 2>/dev/null

# --- 3. ARP: are the resurrected cameras staying? ---
echo "-- arp --"
ip neigh show | grep -E "192\.168\.2\.10[034]" || echo "no ARP entries for .100/.103/.104"

# --- 0c-b. RESTIC BACKUP HEALTH (v2.6, cycle 122) ---
# The "timer fires but backup silently fails" class: the timer is
# green while the last run's Result is failure. One ssh call from
# the caller; here it reads local systemd state (script runs ON
# sophon as root).
echo "-- restic backup health --"
rres=$(systemctl show restic-backup.service -p Result --value 2>/dev/null)
rexit=$(systemctl show restic-backup.service -p ExecMainStatus --value 2>/dev/null)
rlast=$(systemctl show restic-backup.timer -p LastTriggerUSec --value 2>/dev/null)
if [ "$rres" != "success" ]; then
  echo "RESTIC BACKUP FAILED: Result=$rres exit=$rexit (last timer fire: $rlast)"
  FAIL=1
else
  # freshness: LastTrigger must be within 26h (daily 00:00 -03 timer)
  age_h=$(( ( $(date +%s) - $(date -d "$rlast" +%s 2>/dev/null || echo 0) ) / 3600 ))
  if [ "$age_h" -gt 26 ]; then
    echo "RESTIC STALE: last fire $rlast (${age_h}h ago) -- timer may be skipping"
    FAIL=1
  else
    echo "restic ok: Result=success, last fire $rlast (${age_h}h ago)"
  fi
fi
# fleet-check v2.6 (2026-09-02, cycle 122): restic backup health check
# added (0c-b): Result != success -> FAIL; LastTrigger older than 26h
# -> STALE FAIL. Catches "timer green, backup dead" class. Verified
# live on sophon (Result=success, age 0h, verdict OK).
# CALLER NOTE: run with ssh timeout >= 300s (ear check ~2min).

# --- 0c-c. FRIGATE EVENT HEALTH (v2.7, cycle 126) ---
# The "detector silently dead" class: ONNX loads, cameras record,
# but the event pipeline produces nothing. DB memory begins
# 2026-09-01 23:41 -03 (0.17 migration + config fix); everything
# earlier is unrecoverable from the DB. Read-only sqlite, no API auth.
echo "-- frigate event health --"
frev=$(python3 - <<'PYEOF'
import sqlite3, time
try:
    con = sqlite3.connect("file:/home/nacho/containers/frigate/config/frigate.db?mode=ro", uri=True, timeout=5)
    cur = con.cursor()
    now = int(time.time())
    n24 = cur.execute("SELECT COUNT(*) FROM event WHERE start_time > ?", (now-86400,)).fetchone()[0]
    nint = cur.execute("SELECT COUNT(*) FROM event WHERE start_time > ? AND camera LIKE 'interior%'", (now-86400,)).fetchone()[0]
    next_ = cur.execute("SELECT COUNT(*) FROM event WHERE start_time > ? AND camera LIKE 'exterior%'", (now-86400,)).fetchone()[0]
    total = cur.execute("SELECT COUNT(*) FROM event").fetchone()[0]
    con.close()
    print(f"{n24} {nint} {next_} {total}")
except Exception as e:
    print(f"ERR {e}")
PYEOF
)
if [[ "$frev" == ERR* ]]; then
  echo "FRIGATE DB UNREADABLE: $frev"
  FAIL=1
else
  read -r n24 nint next_ total <<< "$frev"
  echo "frigate events 24h: total=$n24 interior=$nint exterior=$next_ (ever=$total)"
  if [ "$total" -eq 0 ]; then
    echo "frigate: no events ever -- detector has never produced one (report, not fail)"
  elif [ "$n24" -eq 0 ]; then
    echo "FRIGATE EVENTS STALE: $total events exist but none in 24h -- detector likely dead"
    FAIL=1
  fi
  # exterior-zero is the open longitudinal question (start 2026-09-01 23:41 -03):
  # a week of exterior=0 while interior flows -> check exterior detect configs.
fi

echo "== fleet-check done (FAIL=$FAIL) =="
exit $FAIL
