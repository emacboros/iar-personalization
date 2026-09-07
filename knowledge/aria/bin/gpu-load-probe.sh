#!/bin/bash
# gpu-load-probe.sh -- sample sophon GPU/load during the early-morning
# failure window (00:32-03:55 local) to test the load-correlation
# hypothesis from the cycle-failure census (c94/c96).
#
# Hypothesis under test: model degradation (both glm and deepseek fail
# in bursts) is load-correlated -- Frigate (8 cams) + Ollama + Zulip on
# one RTX 3080; if the GPU is busy in those hours, the model degrades
# (longer context, more repetition -> runaway/breaker/hard-cap endings).
#
# Method: append one CSV line per minute to a dated log. Run via a
# systemd timer (OnCalendar=*-*-* 00:30:00, Persistent=false, then a
# while-loop for ~3.5h). Cheap: one nvidia-smi + uptime per minute.
#
# Output: $LOG_DIR/gpu-load-YYYY-MM-DD.csv
#   epoch,local_iso,util_pct,vram_used_mb,load1,load5,load15,ollama_reqs
#   ollama_reqs = active inference requests (ps aux | grep ollama runner)
#                 -- 0 when idle, >0 when a model is generating.
#
# Install (Nacho -- infra change, not cycle domain):
#   cp to /usr/local/sbin/gpu-load-probe.sh
#   systemd timer: OnCalendar=*-*-* 00:30:00, ExecStart=/usr/local/sbin/gpu-load-probe.sh
#   (or fold into an existing maintenance timer). LOG_DIR=/var/log/gpu-load.
#
# This file is the repo copy; the systemd unit would ExecStart THIS file
# from the sophon personalization clone (same pattern as aria-dashboard).
# No copy on the host; repo version IS the running version.

set -u
LOG_DIR="${LOG_DIR:-/var/log/gpu-load}"
mkdir -p "$LOG_DIR"
DATE="$(date +%Y-%m-%d)"
LOG="$LOG_DIR/gpu-load-$DATE.csv"

# header once
[ -f "$LOG" ] || echo "epoch,local_iso,util_pct,vram_used_mb,load1,load5,load15,ollama_reqs" > "$LOG"

# sample every 60s for ~3.5h (210 samples), then exit (timer can re-fire
# next day; Persistent=false so no catch-up after downtime)
END=$(( $(date +%s) + 12600 ))   # 3.5h
while [ "$(date +%s)" -lt "$END" ]; do
  EPOCH="$(date +%s)"
  ISO="$(date -Iseconds)"
  GPU="$(nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits 2>/dev/null | tr -d ' ')"
  UTIL="${GPU%%,*}"; VRAM="${GPU##*,}"
  [ -n "$UTIL" ] || UTIL="NA"
  [ -n "$VRAM" ] || VRAM="NA"
  LOAD="$(awk '{printf "%s,%s,%s", $1, $2, $3}' /proc/loadavg 2>/dev/null)"
  [ -n "$LOAD" ] || LOAD="NA,NA,NA"
  OLLAMA="$(ps aux 2>/dev/null | grep -c '[o]llama.*runner')"
  [ -n "$OLLAMA" ] || OLLAMA="NA"
  echo "$EPOCH,$ISO,$UTIL,$VRAM,$LOAD,$OLLAMA" >> "$LOG"
  sleep 60
done
echo "probe complete: $LOG"
