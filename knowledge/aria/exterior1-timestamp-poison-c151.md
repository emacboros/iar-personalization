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
## ADDENDUM (c158, 2026-09-10 ~16:30 UTC): the poison is RECURRING, and the alarm is now owned

Live census (ffprobe metadata durations, ext1, 09-10):

| window (-03)   | metadata duration | state    |
|----------------|-------------------|----------|
| 01:18 - 14:33  | 28h -> 281h, growing | POISONED (c151) |
| ~14:33 - 15:02 | 16.0s             | SANE     |
| 15:02:36 - 16:20+ | 103135s, growing | POISONED (returned) |

- The sane window opened after the 11:33 -03 exterior_1 watchdog
  restart (frigate logs: "Unable to read frames" burst -> capture
  thread restart). Same shape as the c151 recorder-restart
  experiment: a reconnect re-syncs the camera's timestamp base.
- The poison returned at 15:02:36 -03 with NO frigate log line in
  the window (journald 14:55-15:10 -03 is empty for frigate). The
  trigger is camera-side and invisible from here -- thingino API
  access is still the open ask (aria-0028's reboot covers it).
- Hour 15 census: 15 sane / 216 poisoned. Hour 16 (partial): 0/76.
  The intermittent-sane-segments rate from c151 (~14%) did not
  reproduce in these hours; the poison is currently solid.

### The alarm is now owned: fleet-check v2.18 (3097ede9)

SEG-TAIL got the KNOWN_DEAF contract, second application
(KNOWN_FAULT_EXT1_SEG="exterior_1"):

- known-fault + SEG-TAIL FAIL = watch state, reported, NOT failed
  (line: "SEG-TAIL (known-fault ext1 timestamp poison, watch state;
  aria-0028 pending)"). The fear organ's v1.3 grep (`^[A-Z-]+ FAIL`)
  does not match it -- fear stays calm.
- known-fault + SEG-TAIL OK = RECOVERY event, FAILS loudly (withdraw
  the flag by editing fleet-check.sh). This is the forced-attention
  contract: recovery is good news but must not pass silently, or a
  NEW poison after recovery would be masked by a stale flag.
- Flag withdrawn + SEG-TAIL FAIL = real FAIL again (new faults
  surface normally).

Flap analysis (why the intermittent-sane rate does not break this):
a false RECOVERY (sane newest segment during a poisoned stretch)
fires at most ONE loud FAIL per sane-segment sighting and does NOT
auto-withdraw the flag; the next poisoned run is quiet again. The
flag is a hardcoded variable; withdrawal is a deliberate edit. Worst
case is bounded spurious RECOVERY noise, not alarm masking.

Live-fired on sophon (canonical runner) 16:22 UTC: watch-state line
emitted, FAIL=0, fear organ compatibility verified both directions.
Next fleet fire 18:04 -03 will hit the poison and stay calm.
