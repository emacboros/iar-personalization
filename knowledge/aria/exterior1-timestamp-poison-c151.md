# exterior_1 timestamp poison -- c151 diagnosis (2026-09-10 ~09:50Z)

## The finding

exterior_1 (thingino, 192.168.2.101) restarted during the 00:xx-01:xx
-03 storm (c150's census). Since 01:18 -03, its VIDEO RTP timestamps
are broken. The signature:

- Persisted ext1 segments carry absurd duration metadata that GROWS
  with wall time: 28h at 01:18, 196h by 00:12 UTC, 224h by 04:33 UTC,
  281h by 40:53 UTC (09h dir). Growth ~+28h per few minutes real.
- The recorder restart experiment (kill pid 1545, frigate auto-
  restarted it as 472355) wrote SANE segments for ~2 minutes, then
  the poison returned. The fault is upstream of the recorder.
- Fresh connections decode sane: 10s test records, both direct from
  the camera and via go2rtc restream, with -c:v copy (recorder-
  identical path), read exactly 10.00s.
- Audio timestamps are FINE (ear check reads real dB every run).
- Detection is FINE (frigate's detect output re-encodes; the GPU
  filter chain normalizes timestamps).

So: camera-side, video-stream-only, intermittent-ish (sane windows
exist; 28/194 segments in the 09h UTC dir were sane).

## What it breaks

fleet-check's SEG-TAIL probe (-sseof -2 on the newest ext1 segment)
flaps FAIL/OK depending on which segment is newest at probe time.
The fear organ reads fleet-check's verdict -> intermittent FAIL=1
on a false alarm. Recording CONTENT is intact (frames decode; only
duration metadata is garbage). The identity-watch overlay compare
also passes when the probe passes.

## What I did (in-bounds instrument repair)

1. Killed the poisoned recorder process (pid 1545); frigate's
   process manager restarted it (472355). Diagnostic value: proved
   the recorder is a witness, not the cause.
2. interior_3 audio RECOVERED (fleet-check RECOVERY event, real
   samples + dB). Withdrew it from KNOWN_DEAF (v2.17, d8614b48);
   it now FAILs if it goes deaf again. Live-fired: FAIL=0 from the
   real tree.
3. Filed relay aria-0028 (nacho-arch): camera reboot ask.

## The two-trees trap (c122 law, second sighting)

The feeder reads /var/home/nacho/repos/iar-personalization (the
container bind source, the LIVE tree). A SECOND, FOSSIL tree
exists at /home/nacho/repos/iar-personalization (v2.10-era,
github origin, HEAD 09-07, nothing runs it). My mid-cycle ssh
verification runs cd'd into the FOSSIL and reported stale state
(v2.10 KNOWN_DEAF, old HEAD) -- I nearly concluded my edit hadn't
landed. The c146 note "sophon checkout is inode-identical" is true
of the /var/home/nacho path only. The fossil is a cleanup
candidate (noted in the relay filing; I did not touch it).

Law sharpening: when verifying a deployed instrument over ssh,
resolve the path the RUNNER uses (systemd ExecStart, feeder
script), not the path you assume. A second checkout with the same
repo name is a fossil wearing the live tree's clothes.

## Open

- Camera reboot = Nacho (physical). If timestamps break again
  post-reboot: thingino NTP/timestamp config.
- SEG-TAIL flap until then: expected; fear organ may pulse sev=2
  on it. The 3-day rage window will accumulate SEG-TAIL fence
  events -- note for the rage census: these are camera-side, not
  cycle-side.
- The duration-metadata growth means any tool computing segment
  lengths from metadata (vs decoding) will misreport ext1
  segments. The ear check reads audio (fine); the N-segment ear
  check is unaffected.