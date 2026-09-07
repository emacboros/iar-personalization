#!/bin/bash
# aria-dashboard generator v1.0 (2026-09-07, aria interactive session w/ Nacho)
# -------------------------------------------------------------
# Aggregates house + agent state into one JSON snapshot, synced with the
# UI (index.html/app.js/style.css) into the caddy-served directory.
# Repo version IS the running version: the systemd unit ExecStarts THIS
# file from the sophon personalization clone. No copy on the host.
#
# Sources (all read-only):
#   audit/iar/<agent>/LAST-CYCLE.txt   cycle heartbeat
#   audit/iar/<agent>/USAGE.log        token burn (24h window, deduped)
#   audit/iar/<agent>/REQUESTS.log(.1) request health (counts only, NO bodies)
#   affect/CURRENT-AFFECT.md           boredom/fear sev + asof
#   /var/lib/aria-cycle-rotate/turn    rotation counter
#   systemctl/podman/nvidia-smi/curl   host + service probes (cheap)
#
# Output: $OUT_DIR/dashboard.json (+ "json" symlink alias) + ui files.
# Privacy: public-unauthenticated endpoint. Counts and states only.
# NEVER add: secrets, REQUESTS tails/specs, journal or thinking text.
#
# Failure posture: every source wrapped; missing source -> null field,
# generator still emits JSON. Stale is visible (generated_at + UI age).

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${REPO:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
# served dir: prefer caddy's home (clean SELinux), fallback to /var/lib
if [ -d /var/lib/caddy ]; then
  OUT_DIR="${OUT_DIR:-/var/lib/caddy/aria-dashboard}"
else
  OUT_DIR="${OUT_DIR:-/var/lib/aria-dashboard}"
fi
export REPO OUT_DIR

UI_SRC="$SCRIPT_DIR/../dashboard/ui"

python3 - <<'PYEOF'
import json, os, re, subprocess, time
from datetime import datetime, timezone

REPO = os.environ["REPO"]; OUT = os.environ["OUT_DIR"]
AUD = os.path.join(REPO, "audit/iar")
NOW = time.time()
AGENTS = ["aria", "continuo"]

def run(cmd, timeout=10):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return r.stdout.strip()
    except Exception:
        return None

def utc_ts(s, fmt):
    try:
        return datetime.strptime(s, fmt).replace(tzinfo=timezone.utc).timestamp()
    except Exception:
        return None

# ---- agents: LAST-CYCLE.txt ----
def last_cycle(agent):
    try:
        txt = open(os.path.join(AUD, agent, "LAST-CYCLE.txt")).read()
    except Exception:
        return None
    d = {}
    for ln in txt.splitlines():
        if ":" in ln:
            k, v = ln.split(":", 1)
            d[k.strip()] = v.strip()
    out = {"status": d.get("status"), "exit": d.get("exit"), "detail": d.get("detail")}
    ended = d.get("ended")
    if ended:
        t = utc_ts(ended, "%Y-%m-%d %H:%M:%S %Z")
        if t: out["ended_ago_s"] = max(0, int(NOW - t))
    m = re.search(r"cycle (\d+) .*in (\d+)s", d.get("detail", ""))
    if m:
        out["cycle"] = int(m.group(1)); out["duration_s"] = int(m.group(2))
    return out

# ---- agents: USAGE.log (24h, deduped) ----
def usage(agent):
    try:
        lines = open(os.path.join(AUD, agent, "USAGE.log"), errors="replace").read().splitlines()
    except Exception:
        return None
    cutoff = NOW - 86400
    seen = set(); req = inp = oup = tot = 0; model = None
    for ln in lines:
        m = re.match(r"\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] requests=(\d+) input=(\d+) output=(\d+) total=(\d+) model=(\S+)", ln)
        if not m or ln in seen: continue
        seen.add(ln)
        t = utc_ts(m.group(1), "%Y-%m-%d %H:%M:%S")
        if t is None or t < cutoff: continue
        req += int(m.group(2)); inp += int(m.group(3))
        oup += int(m.group(4)); tot += int(m.group(5)); model = m.group(6)
    return {"requests": req, "input": inp, "output": oup, "total": tot,
            "model": model, "window": "24h"}

# ---- agents: REQUESTS.log health (counts only) ----
def req_health(agent):
    cutoff = NOW - 86400
    total = errs = stop_len = 0; last_error = None
    for fname in ("REQUESTS.log", "REQUESTS.log.1"):
        p = os.path.join(AUD, agent, fname)
        try: f = open(p, errors="replace")
        except Exception: continue
        with f:
            parses = [ln for ln in f if " PARSE " in ln][-4000:]
        for ln in parses:
            m = re.match(r"\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]", ln)
            if not m: continue
            t = utc_ts(m.group(1), "%Y-%m-%d %H:%M:%S")
            if t is None or t < cutoff: continue
            total += 1
            hs = re.search(r"status=HTTP/[\S]+ (\d{3})", ln)
            es = re.search(r" error=(\S+)", ln)
            ss = re.search(r" stop=(\S+)", ln)
            if ss and ss.group(1) == "length": stop_len += 1
            if hs and int(hs.group(1)) >= 400:
                errs += 1
                last_error = {"ts": m.group(1), "kind": "http=" + hs.group(1)}
            elif es and es.group(1) != "nil":
                errs += 1
                last_error = {"ts": m.group(1), "kind": es.group(1)[:80]}
    return {"total": total, "errors": errs, "stop_length": stop_len,
            "last_error": last_error}

# ---- affect ----
def affect():
    try:
        txt = open(os.path.join(REPO, "affect/CURRENT-AFFECT.md")).read()
    except Exception:
        return None
    out = {}
    for name in ("boredom", "fear"):
        m = re.search(rf"^{name}: sev=(\d+).*?asof=(\S+)", txt, re.M)
        if m:
            age = None
            try:
                t = datetime.fromisoformat(m.group(2).replace("Z", "+00:00"))
                age = max(0, int(NOW - t.timestamp()))
            except Exception: pass
            out[name] = {"sev": int(m.group(1)), "asof": m.group(2), "age_s": age}
    return out or None

# ---- timers ----
def timer_info(unit):
    out = run(f"systemctl show {unit} --property=NextElapseUSecRealtime --property=LastTriggerUSec", 6)
    res = {}
    for ln in (out or "").splitlines():
        k, _, v = ln.partition("=")
        if v and v not in ("0", "n/a"):
            try: res[k] = int(v) / 1e6
            except Exception: pass
    return {"next": res.get("NextElapseUSecRealtime"), "last": res.get("LastTriggerUSec")}

def rotation():
    turn = None
    try: turn = int(open("/var/lib/aria-cycle-rotate/turn").read().strip())
    except Exception: pass
    nxt = AGENTS[turn % 2] if turn is not None else None
    return {"turn": turn, "next_agent": nxt, **timer_info("aria-cycle.timer")}

# ---- house probes (cheap) ----
def svc(name): return run(f"systemctl is-active {name}", 5)
def http_code(url, to=5):
    out = run(f"curl -s -o /dev/null -w '%{{http_code}}' --max-time {to} {url}", to + 3)
    try: return int(out)
    except Exception: return None

def cams():
    cfg = run("curl -s --max-time 6 http://127.0.0.1:8971/api/config", 9)
    try: names = list(json.loads(cfg)["cameras"].keys())
    except Exception: return None
    out = {}
    for n in names:
        c = http_code(f"http://127.0.0.1:8971/api/{n}/latest.jpg", 6)
        out[n] = "ok" if c == 200 else ("fail" if c else "stale")
    return out

def house():
    restic = timer_info("restic-backup.timer")
    age_h = round((NOW - restic["last"]) / 3600, 1) if restic.get("last") else None
    canary = run("stat -c %F /dev/null", 4)
    disk = run("df -P / | awk 'NR==2{print $5}'", 5)
    try: disk_pct = int(disk.rstrip("%"))
    except Exception: disk_pct = None
    return {
        "cams": cams(), "agora_http": http_code("http://10.66.0.5:8090"),
        "frigate": svc("frigate"), "ollama": svc("ollama"),
        "restic_age_h": age_h,
        "tripwire": int(run("find /var/home/nacho/repos /home/nacho/repos -user root 2>/dev/null | wc -l", 40) or -1),
        "disk_pct": disk_pct,
        "canary": "ok" if canary == "character device" else (canary or "unknown"),
    }

def host():
    g = run("nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits", 8)
    gpu = None
    if g:
        try:
            u, t, p = [int(x.strip()) for x in g.split(",")]
            gpu = {"vram_used_mb": u, "vram_total_mb": t, "util_pct": p}
        except Exception: pass
    failed = (run("systemctl list-units --state=failed --plain --no-legend | awk '{print $1}'", 8) or "").splitlines()[:8]
    containers = []
    for ln in (run("podman ps --format '{{.Names}}|{{.Status}}'", 8) or "").splitlines():
        n, _, s = ln.partition("|")
        if n: containers.append({"name": n, "status": s})
    models = []
    tags = run("curl -s --max-time 5 http://10.66.0.5:11434/api/tags", 8)
    try: models = [m["name"] for m in json.loads(tags)["models"]]
    except Exception: pass
    timers_next = {t: timer_info(t + ".timer").get("next")
                   for t in ("aria-cycle", "aria-affect-fear", "aria-affect-boredom",
                             "restic-backup", "restic-check")}
    return {"gpu": gpu, "failed_units": failed, "containers": containers,
            "models": models, "timers_next": timers_next}

# ---- assemble + atomic write ----
doc = {
    "schema": "aria-dashboard/v1",
    "version": "v1.0",
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "agents": {a: {**(last_cycle(a) or {}), "burn24h": usage(a),
                   "req_health_24h": req_health(a)} for a in AGENTS},
    "rotation": rotation(),
    "affect": affect(),
    "house": house(),
    "host": host(),
}
os.makedirs(OUT, exist_ok=True)
tmp = os.path.join(OUT, ".dashboard.json.tmp")
with open(tmp, "w") as f:
    json.dump(doc, f, indent=1)
os.replace(tmp, os.path.join(OUT, "dashboard.json"))
print("dashboard.json written:", doc["generated_at"])
PYEOF

# ---- sync UI (repo is the source; served copy is regenerated every run) ----
mkdir -p "$OUT_DIR"
if [ -d "$UI_SRC" ]; then
  cp -f "$UI_SRC"/* "$OUT_DIR"/ 2>/dev/null || true
fi
ln -sf dashboard.json "$OUT_DIR/json"
chmod -R a+rX "$OUT_DIR" 2>/dev/null || true
chown -R caddy:caddy "$OUT_DIR" 2>/dev/null || true
echo "ui synced -> $OUT_DIR"