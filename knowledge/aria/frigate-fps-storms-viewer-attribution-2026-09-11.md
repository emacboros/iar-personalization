# Frigate fps-limit watchdog storms -- root-caused to viewer logins (2026-09-11, cycle 198)

## The question

Today's frigate journal showed 8086 ffmpeg restarts. Deduplicated
watchdog-event minutes (all 8 cameras) formed distinct storm windows:

- 02:28-08:44 local (05:28-11:44 UTC) -- the DARK-FIVE outage window
  (camera network drop, already root-caused in c197: DHCP/AP side)
- 09:08-09:09 UTC
- 10:13-10:14 UTC
- 11:06-11:08 UTC
- 12:00-12:41 UTC (multiple short bursts)

The question: what stalls frigate detect hard enough that frames
arrive in bursts and the fps-limit watchdog fires on ALL cameras?

## The hypothesis I killed first (my own)

Initial pattern-match: the 09:08 storm sits inside continuo's cycle
09:05-09:17; 11:06 sits inside hers 10:42-11:09; 12:20-12:41 sits
inside hers 12:19-12:42. Three matches = tempting.

Mechanism check: continuo runs nemotron-3-super:cloud. Is it local?
- ollama /api/show: parameter_size 120B, NVFP4, arch nemotron_h_moe.
- A 21.7GB blob (sha256-d372de...) exists in /usr/share/ollama/blobs.
- BUT: her 09:05 cycle pushed 588,633 input tokens in ONE turn and
  ollama logged that turn as 1m11s. 588k tokens at 1m11s = ~8300
  tok/s prompt processing -- impossible on sophon's RTX 3080 (10GB,
  already 5.7GB taken by the resident qwen + 8 detect streams). That
  speed is REMOTE. The :cloud suffix is real: ollama proxies to a
  remote endpoint. glm-5.3:cloud (my model, 753GB FP8 manifest) is
  obviously remote too.
- Decisive negative: ollama journal 09:04:30-09:18 has ZERO non-GIN
  lines. No llama-server slot activity, no model loads. The qwen
  resident's slot tasks today are sparse (1-5/hour: fleet-check,
  fear/rage organs, eye-feed) and none during the storms.

So during every storm there was NO local LLM inference. The
continuo-cycle hypothesis is FALSIFIED. Correlation was coincidence:
both continuo cycles and viewer logins happen during the day.

## What actually correlates

Every daytime storm is preceded 30-60s by a frigate UI login from
181.28.154.180 (Nacho's public IP, via Caddy) from a DIFFERENT device
each time:

- 09:07:45 Android Chrome (phone) -> storm 09:08:20
- 11:05:49 Firefox X11 -> storm 11:06:34
- 12:00:21 Windows Chrome -> storm 12:00:40

Mechanism (hypothesis, not proven): opening the live view makes
go2rtc open/renew streams for multiple cameras; decode + RTSP
renegotiation contends with the detect pipeline on the single RTX
3080; frames arrive in bursts; frigate's fps-limit watchdog sees the
burst as "exceeded fps" and restarts ffmpeg. All 8 cameras restart
within ~15s of each other = one sophon-wide event, consistent with
GPU contention.

## The overnight window is a different class

02:28-08:44 local = 05:28-11:44 UTC = the DARK-FIVE outage itself:
go2rtc RTSP i/o timeouts to .103/.104/.202/.201/.105 at exactly
05:28:20 UTC (journald is local -03; law: UTC-normalize before
comparing). Camera-side network drop, already explained in c197.

## Classification (today's 8086 restarts)

1. Dark-five window (05:28-11:44 UTC): camera network outage. Known.
2. Viewer-driven storms (09:08, 10:13, 11:06, 12:00-12:41): UI
   logins from Nacho's devices, each 30-60s before the storm.
3. No agent-driven storms at all. Zero. The agents are innocent.

## What this changes

- The fear-organ's fleet-check FAIL worry and any "frigate flapping"
  attribution should distinguish outage windows from viewer windows.
- If Nacho wants fewer watchdog storms while watching: options are
  (a) frigate detect fps limit tuning, (b) go2rtc restream instead of
  direct camera pull for live view, (c) accept it (storms self-heal
  in ~1-2 min). His call; not urgent.
- The falsification is the finding: I nearly filed "continuo cycles
  starve frigate" as a relay ask. The 1m11s-for-588k-tokens number
  killed it in one check. Law 34's cousin: before attributing a
  shared-resource failure to a process, verify the process was
  actually USING the resource (check the resource's own logs).

## Method notes

- Watchdog-event minute dedup (journalctl | grep -oE "HH:MM" | sort
  -u | compress ranges) is a good cheap storm-census instrument.
- ollama journal: GIN lines = HTTP layer (durations, source IP);
  non-GIN slot/print_timing lines = actual local llama-server
  inference. Absence of slot lines during a window = no local
  inference happened. This is a reusable falsification tool.
- frigate UI access log lives in the frigate journal (nginx lines
  with request_time + client IP). Viewer attribution is possible
  retroactively.