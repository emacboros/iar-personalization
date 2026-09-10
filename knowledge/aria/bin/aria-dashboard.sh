#!/bin/bash
# aria-dashboard generator v2.0 (2026-09-09, aria interactive session X w/ Nacho)
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
#
# v2.0 (2026-09-09, session X): D-013 connectome data layer -- connectome()
#   (co-firing edges, file-touch, shared load-bearing files, token percentiles,
#   fires, silence, fence rejections from sophon audit logs, 24h window),
#   burn_series() (hourly tokens_in per agent from REQUESTS.log PARSE lines).
#   Schema -> aria-dashboard/v2 (v1 keys unchanged; oracle context unaffected).
#   Live connectome = sophon logs ONLY (cycle traffic; full population =
#   weekly snapshot, provenance stated in JSON). Nacho-ratified session X.
# v2.1 (2026-09-10, aria interactive w/ Nacho): board() semantics fixed --
#   working/thinking derive from GIT history (commit recency), not mtimes
#   (mtimes conflate sprint bursts + pull refreshes with active work);
#   working window 12h (sprint cadence: 24h kept stale-sprint tasks in working);
#   done = task dir removed <7d (house convention), replacing the
#   hand-maintained relay_map (which misfired: qwen36 slug matched the
#   eye-swap request, not the benchmark task). NEW open_questions():
#   UI open-questions tab. Schema unchanged (v2, additive); version v2.1.
#   Security-class titles redacted on the public endpoint (nacho-security
#   -> '[security item -- details in relay]'; fail-closed on unparseable).
# v1.9 (2026-09-09, aria c116): board() -- task-tree digest (D-013 addendum),
#   thinking/working/done from tasks/iar/ mtimes + relay verdicts. Real data only.
# v1.8 (2026-09-07, aria c21): affect() parses rage too (additive; rage organ live since c20).
# v1.7 fix (2026-09-07, cycle 2): req_health anchored both ends --
#   specs= self-pollution (echoed diagnostic greps) manufactured fake
#   errors/stop-lengths; status now re.match'd at line start, error/stop
#   read from the $-anchored PARSE tail only.
# v1.1 fixes (live-install differential test, 2026-09-07):
#   - timer_info: systemctl show returns HUMAN timestamps ("Sun 2026-09-06
#     23:21:09 -03"), not epoch ints. Parse via list-timers instead; aria-cycle
#     is monotonic (empty NextElapseUSecRealtime) so list-timers is the source.
#   - sophon local time = fixed UTC-3 (Argentina, no DST); convert naive
#     list-timers stamps by +3h to get UTC epoch.
#   - canary: sophon stat -c %F says "character special file" (not
#     "character device"); accept both.
#   - cams: frigate API 8971 is 401 unauth, 5000 unreachable -> file-based
#     freshness from the recordings dir (newest mp4 mtime per camera).

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
import glob, json, os, re, subprocess, time
from datetime import datetime, timezone

REPO = os.environ["REPO"]; OUT = os.environ["OUT_DIR"]
AUD = os.path.join(REPO, "audit/iar")
NOW = time.time()
AGENTS = ["aria", "continuo"]
# sophon local time = fixed UTC-3 (Argentina has no DST)
LOCAL_UTC_OFFSET = 3 * 3600

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

# ---- timers: parse `systemctl list-timers` (human stamps, works for
#      monotonic timers where NextElapseUSecRealtime is empty) ----
# list-timers columns: NEXT | LEFT | LAST | PASSED | UNIT | ACTIVATES.
# Monotonic timers (aria-cycle) have "-" for NEXT -> only one stamp (LAST).
STAMP_RE = re.compile(r"(\w{3}) (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (-\d{2})")
def local_to_epoch(naive_str):
    try:
        t = datetime.strptime(naive_str, "%Y-%m-%d %H:%M:%S")
        return t.replace(tzinfo=timezone.utc).timestamp() + LOCAL_UTC_OFFSET
    except Exception:
        return None

def timer_info(unit):
    out = run(f"systemctl list-timers --all {unit} --no-pager --no-legend", 6)
    if not out:
        return {"next": None, "last": None}
    stamps = STAMP_RE.findall(out.splitlines()[0].strip())
    if not stamps:
        return {"next": None, "last": None}
    if len(stamps) >= 2:
        nxt = local_to_epoch(stamps[0][1])
        lst = local_to_epoch(stamps[1][1])
    elif stamps:
        # one stamp: either NEXT-only (never fired, e.g. boredom timer) or
        # LAST-only (monotonic aria-cycle while running). Disambiguate by
        # position: list-timers puts NEXT first; a "-" NEXT shifts LAST to front.
        first_is_next = not out.splitlines()[0].strip().startswith("-")
        if first_is_next:
            nxt = local_to_epoch(stamps[0][1]); lst = None
        else:
            lst = local_to_epoch(stamps[0][1])
            nxt = lst + 600 if unit == "aria-cycle.timer" else None
    else:
        nxt = lst = None
    return {"next": nxt, "last": lst}

def rotation():
    turn = None
    try: turn = int(open("/var/lib/aria-cycle-rotate/turn").read().strip())
    except Exception: pass
    nxt = AGENTS[turn % 2] if turn is not None else None
    return {"turn": turn, "next_agent": nxt, **timer_info("aria-cycle.timer")}

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
            # PARSE tail is structural: `... error=X stop=Y tokens_in=N
            # tokens_out=M` ends the line. Anchor BOTH ends: the specs=
            # field mid-line carries echoed grep/python text (REQUESTS.log
            # is self-polluting) that unanchored ` error=` / ` stop=`
            # pattern-matches -- that manufactured 22 fake errors + 48
            # fake stop=length in 24h (found 2026-09-07, cycle 2).
            hs = re.match(r"\[[^\]]+\] REQ \S+ PARSE status=HTTP/[\S]+ (\d{3})", ln)
            mt = re.search(r"error=(\S+) stop=(\S+) tokens_in=\d+ tokens_out=\d+\s*$", ln)
            if mt and mt.group(2) == "length": stop_len += 1
            if hs and int(hs.group(1)) >= 400:
                errs += 1
                last_error = {"ts": m.group(1), "kind": "http=" + hs.group(1)}
            elif mt and mt.group(1) != "nil":
                errs += 1
                last_error = {"ts": m.group(1), "kind": mt.group(1)[:80]}
    return {"total": total, "errors": errs, "stop_length": stop_len,
            "last_error": last_error}

# ---- affect ----
def affect():
    try:
        txt = open(os.path.join(REPO, "affect/CURRENT-AFFECT.md")).read()
    except Exception:
        return None
    out = {}
    for name in ("boredom", "fear", "rage"):
        m = re.search(rf"^{name}: sev=(\d+).*?asof=(\S+)", txt, re.M)
        if m:
            age = None
            try:
                t = datetime.fromisoformat(m.group(2).replace("Z", "+00:00"))
                age = max(0, int(NOW - t.timestamp()))
            except Exception: pass
            out[name] = {"sev": int(m.group(1)), "asof": m.group(2), "age_s": age}
    return out or None

# ---- house probes (cheap) ----
def svc(name): return run(f"systemctl is-active {name}", 5)
def http_code(url, to=5):
    out = run(f"curl -s -o /dev/null -w '%{{http_code}}' --max-time {to} {url}", to + 3)
    try: return int(out)
    except Exception: return None

# cams: frigate API needs auth -> file freshness from recordings dir.
# Recordings layout: <dir>/<camera>/<YYYY-MM-DD>/<HH>/<file>.mp4
def find_recordings_dir():
    # sophon frigate compose: /home/nacho/containers/frigate/storage -> /media/frigate
    for cand in ("/home/nacho/containers/frigate/storage/recordings",
                 "/var/lib/frigate/recordings", "/var/frigate/recordings",
                 "/srv/frigate/recordings"):
        if os.path.isdir(cand): return cand
    return None

REC_DIR = None
def cams():
    # layout: <recordings>/<YYYY-MM-DD>/<HH>/<camera>/*.mp4
    global REC_DIR
    if REC_DIR is None:
        REC_DIR = find_recordings_dir()
        if REC_DIR is None: return None
    out = {}
    try:
        days = [d for d in sorted(os.listdir(REC_DIR)) if os.path.isdir(os.path.join(REC_DIR, d))]
        if not days: return None
        latest_day = os.path.join(REC_DIR, days[-1])
        hours = [h for h in sorted(os.listdir(latest_day)) if os.path.isdir(os.path.join(latest_day, h))]
        if not hours: return None
        latest_hour = os.path.join(latest_day, hours[-1])
        for cam in sorted(os.listdir(latest_hour)):
            camdir = os.path.join(latest_hour, cam)
            if not os.path.isdir(camdir): continue
            newest = 0
            try:
                for f in os.listdir(camdir):
                    m = os.path.getmtime(os.path.join(camdir, f))
                    if m > newest: newest = m
            except Exception:
                pass
            age = NOW - newest if newest else None
            if age is None: out[cam] = "stale"
            elif age < 300: out[cam] = "ok"
            elif age < 1800: out[cam] = "stale"
            else: out[cam] = "fail"
    except Exception:
        return None
    return out or None

def house():
    restic = timer_info("restic-backup.timer")
    age_h = round((NOW - restic["last"]) / 3600, 1) if restic.get("last") else None
    canary = run("stat -c %F /dev/null", 4)
    disk = run("df -P / | awk 'NR==2{print $5}'", 5)
    try: disk_pct = int(disk.rstrip("%"))
    except Exception: disk_pct = None
    # agora: fleet-check's unauthed API probe (200/400/401/403 = app alive);
    # plain root 400s on Host-header behavior and /login 500s on this build.
    ap = http_code("https://agora.randazzo.ar/api/v1/messages?anchor=newest&num_before=1&num_after=0", 10)
    agora_ok = ap in (200, 400, 401, 403)
    return {
        "cams": cams(), "agora_http": ap, "agora_ok": agora_ok,
        "frigate": svc("frigate"), "ollama": svc("ollama"),
        "restic_age_h": age_h,
        "tripwire": int(run("find /var/home/nacho/repos /home/nacho/repos -user root 2>/dev/null | wc -l", 40) or -1),
        "disk_pct": disk_pct,
        "canary": "ok" if canary in ("character device", "character special file") else (canary or "unknown"),
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


# ---- board: task-tree digest (D-013 addendum; v2.1 semantics) ----
def _fmt_age(h):
    return ("%.1fh" % h) if h < 24 else ("%.1fd" % (h / 24))

def board():
    """thinking/working/done digest from tasks/iar/ (real-data rule:
    state derives from GIT HISTORY + the removal convention, never
    hand-edited status fields or bare mtimes).

    v2.1 semantics (Nacho, 09-10 session: 'working' held tasks nobody
    was working on -- mtime recency conflates sprint bursts and pull
    refreshes with active work):
      working = a commit touched the task in the last 12h
                (sprint cadence: cycles commit every ~10-60min when
                active; 12h of silence = nobody is on it)
      thinking = task exists, idle >= 12h (parked / awaiting)
      done    = top-level task dir removed < 7d ago
                (house convention: remove_task on completion)
    """
    tbase = os.path.join(REPO, "tasks/iar")
    out = {"thinking": [], "working": [], "done": []}
    if not os.path.isdir(tbase):
        return out
    now = time.time()
    # done: task dirs whose description.org was deleted within 7d
    try:
        log = run("git -C " + REPO + " log --diff-filter=D --name-only "
                  "--since=7.days --format=@%at -- tasks/iar/ 2>/dev/null", 10) or ""
        cur_ts = None
        removed = {}
        for ln in log.splitlines():
            ln = ln.strip()
            if ln.startswith("@"):
                try: cur_ts = int(ln[1:])
                except Exception: cur_ts = None
                continue
            m = re.match(r"tasks/iar/([^/]+)/description\.org$", ln)
            if m and cur_ts:
                top = m.group(1)
                if top not in ("aria", "continuo", "agora"):
                    removed[top] = min(removed.get(top, 1e9),
                                       (now - cur_ts) / 3600)
        for top, age in sorted(removed.items(), key=lambda x: x[1]):
            out["done"].append({"task": top, "note": "removed %s ago" % _fmt_age(age)})
    except Exception:
        pass
    # done: landed artifacts (connectome snapshots -- standing patrol)
    try:
        if glob.glob(os.path.join(REPO, "knowledge/aria/connectome/snapshot-*.md")):
            out["done"].append({"task": "connectome-snapshot",
                                "note": "latest snapshot landed"})
    except Exception:
        pass
    # working/thinking: last COMMIT age per top-level task dir
    # (git history is the shared truth; file mtime only as >30d fallback)
    ages = {}
    try:
        log = run("git -C " + REPO + " log --since=30.days --name-only "
                  "--format=@%at -- tasks/iar/ 2>/dev/null", 10) or ""
        cur_ts = None
        for ln in log.splitlines():
            ln = ln.strip()
            if ln.startswith("@"):
                try: cur_ts = int(ln[1:])
                except Exception: cur_ts = None
                continue
            if not ln or cur_ts is None:
                continue
            parts = ln.split("/")
            if len(parts) < 4 or parts[0] != "tasks" or parts[1] != "iar":
                continue
            top = parts[2]
            if top in ("aria", "continuo", "agora") or top == "ROADMAP.org":
                continue
            ages[top] = min(ages.get(top, 1e9), (now - cur_ts) / 3600)
    except Exception:
        pass
    # inventory: every task dir on disk (catches tasks with no commit in window)
    tops = set(ages)
    try:
        for d in os.listdir(tbase):
            if os.path.isdir(os.path.join(tbase, d)) and d not in ("aria", "continuo", "agora"):
                tops.add(d)
    except Exception:
        pass
    for top in sorted(tops, key=lambda t: ages.get(t, 1e9)):
        if any(top == d["task"] for d in out["done"]):
            continue
        age = ages.get(top)
        if age is None:
            # no commit in 30d: newest file mtime, coarse
            newest = 0
            for root, _, fs in os.walk(os.path.join(tbase, top)):
                for f in fs:
                    try:
                        newest = max(newest, os.path.getmtime(os.path.join(root, f)))
                    except Exception:
                        pass
            if not newest:
                continue
            age = (now - newest) / 3600
        if age < 12:
            out["working"].append({"task": top, "note": "last touch %s" % _fmt_age(age)})
        else:
            out["thinking"].append({"task": top, "note": "idle %s" % _fmt_age(age)})
    out["working"] = out["working"][:6]
    out["thinking"] = out["thinking"][:4]
    return out

# ---- open questions: the relay queue awaiting Nacho (v2.1) ----
def open_questions():
    """relay/open/ = questions awaiting Nacho. Real data: the ledger IS
    the queue. Ships header fields only (id/class/urgent/title/age) --
    never bodies (bodies can carry prompt fragments; titles are queue
    states). Oldest first: the neglected questions lead the list."""
    qdir = os.path.join(REPO, "relay", "open")
    out = []
    if not os.path.isdir(qdir):
        return out
    now = time.time()
    for f in sorted(os.listdir(qdir)):
        if not f.endswith(".md"):
            continue
        entry = {"id": f[:-3], "age_h": None, "class": None,
                 "urgent": False, "title": ""}
        try:
            head = open(os.path.join(qdir, f), errors="replace").read(2048)
            for ln in head.splitlines():
                s = ln.strip()
                if s.startswith("filed: ") and entry["age_h"] is None:
                    try:
                        t = datetime.strptime(s[7:].strip(), "%Y-%m-%dT%H:%MZ")
                        entry["age_h"] = round(
                            (now - t.replace(tzinfo=timezone.utc).timestamp()) / 3600, 1)
                    except Exception:
                        pass
                elif s.startswith("class: ") and entry["class"] is None:
                    entry["class"] = s[7:].strip()
                elif s.startswith("urgent: ") and not entry["urgent"]:
                    entry["urgent"] = s[8:].strip() == "yes"
                elif s.startswith("title: ") and not entry["title"]:
                    entry["title"] = s[7:].strip()[:110]
        except Exception:
            pass
        m = re.match(r"\d{8}-([a-z]+)-(\d+)", f)
        if m:
            entry["id"] = "%s-%s" % (m.group(1), m.group(2))
        # security-class items: title redacted on the public endpoint
        # (Nacho-ratified default, 09-10 session: a title like 0023's
        # "unrestricted root key" must not sit on an unauthenticated
        # URL). id/class/age still ship. Fail-closed: unparseable
        # class also redacts. One-line revert if Nacho wants raw.
        if entry["class"] is None or entry["class"] == "nacho-security":
            entry["title"] = "[security item -- details in relay]"
        out.append(entry)
    out.sort(key=lambda x: x["age_h"] if x["age_h"] is not None else 1e18,
             reverse=True)
    return out

# ---- connectome (D-013 data layer, session X) ----
# 24h window over sophon audit logs ONLY (cycle traffic; the weekly
# snapshot is the full-population instrument -- both hosts -- and stays
# authoritative for history). Anchors per c115/c32: PARSE lines anchored
# on '] REQ <id> PARSE '; fires tail-anchored on
# 'stop=length tokens_in=N tokens_out=M$'; census-echo law honored
# (patterns never match their own specs= echo because specs= text never
# ENDS a line with the fire tail).
AUD_ROOT = os.path.join(REPO, "audit")
COFIRE_WINDOW = 5
TOPN = 12
TS_RE = re.compile(r"^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]")
PARSE_RE = re.compile(r"\] REQ \d+-\d+ PARSE ")
FIRE_TAIL_RE = re.compile(r"stop=length tokens_in=\d+ tokens_out=\d+\s*$")
WRITE_TOOLS = ("write_file", "append_file", "write_subtask", "create_task",
               "read_file", "list_directory", "read_knowledge")

def _ts(line):
    m = TS_RE.match(line)
    if not m: return None
    try:
        return datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc).timestamp()
    except Exception:
        return None

def _read(path):
    try:
        with open(path, errors="replace") as f:
            return f.read().splitlines()
    except Exception:
        return []

def connectome():
    cutoff = NOW - 86400
    out = {"window": "24h",
           "source": "sophon audit logs (cycle traffic; full population in weekly snapshot)",
           "cofire": {}, "files": {}, "shared_files": [], "tokens": {},
           "burn_series": {}, "fires_24h": {}, "silence_24h": {},
           "fence_rejections_24h": 0}
    try:
        merged = _read(os.path.join(AUD_ROOT, "audit.log.1")) + \
                 _read(os.path.join(AUD_ROOT, "audit.log"))
    except Exception:
        merged = []
    tool_lines = []
    fence = 0
    for ln in merged:
        if " | tool_call | " not in ln: continue
        if "name=nil" in ln: continue
        if re.search(r"\| (mirror|convagent|bessie|unknown|agent-assistant) \|", ln): continue
        # END-ANCHORED (c189 census law): a true rejection line ENDS with
        # 'status=rejected result_len=N' -- no cmd= field. Self-echo (audit
        # census greps quoting the pattern inside cmd=) has cmd= AFTER the
        # status field, so the substring match inflates the count (c129:
        # 6/6 'rejections' in the 24h window were my own grep commands).
        if re.search(r"status=rejected result_len=[0-9]+$", ln):
            fence += 1
            continue
        t = _ts(ln)
        if t is None or t < cutoff: continue
        tool_lines.append((t, ln))
    out["fence_rejections_24h"] = fence

    cofire = {a: {} for a in AGENTS}
    files = {a: {} for a in AGENTS}
    for a in AGENTS:
        prev_t = prev_tool = None
        for t, ln in sorted(tool_lines, key=lambda x: x[0]):
            if f"] {a} | tool_call | " not in ln: continue
            m = re.search(r"name=([a-z_]+)", ln)
            if not m: continue
            tool = m.group(1)
            if prev_t is not None and 0 <= t - prev_t <= COFIRE_WINDOW:
                pair = prev_tool + "->" + tool
                cofire[a][pair] = cofire[a].get(pair, 0) + 1
            prev_t, prev_tool = t, tool
            if tool in WRITE_TOOLS:
                pm = re.search(r'(?:path|filepath)="([^"]+)"', ln) or \
                     re.search(r"(?:path|filepath)=(\S+)", ln)
                if pm:
                    files[a][pm.group(1)] = files[a].get(pm.group(1), 0) + 1

    def top_pairs(d, n):
        return [[k.split("->")[0], k.split("->")[1], v]
                for k, v in sorted(d.items(), key=lambda x: -x[1])[:n]]
    for a in AGENTS:
        out["cofire"][a] = top_pairs(cofire[a], TOPN)
        out["files"][a] = [[k, v] for k, v in
                           sorted(files[a].items(), key=lambda x: -x[1])[:10]]
    shared = sorted(set(files["aria"]) & set(files["continuo"]),
                    key=lambda p: -(files["aria"].get(p, 0) + files["continuo"].get(p, 0)))[:TOPN]
    out["shared_files"] = shared

    for a in AGENTS:
        lines = []
        for suffix in (".1", ""):
            lines += _read(os.path.join(AUD, a, "REQUESTS.log" + suffix))
        toks = []; fires = 0
        max_gap = 0; over600 = 0; prev_t = None
        burn = {}
        for ln in lines:
            if not PARSE_RE.search(ln): continue
            t = _ts(ln)
            if t is None or t < cutoff: continue
            m = re.search(r"tokens_in=(\d+)", ln)
            if m:
                n = int(m.group(1))
                toks.append(n)
                hour = int(t // 3600)
                burn[hour] = burn.get(hour, 0) + n
            if FIRE_TAIL_RE.search(ln): fires += 1
            if prev_t is not None:
                gap = t - prev_t
                if gap > max_gap: max_gap = gap
                if gap > 600: over600 += 1
            prev_t = t
        srt = sorted(toks)
        def pct(p):
            return srt[min(len(srt) - 1, int(len(srt) * p))] if srt else None
        out["tokens"][a] = {"n": len(toks), "p50": pct(.5), "p90": pct(.9),
                            "p99": pct(.99), "max": srt[-1] if srt else None}
        out["fires_24h"][a] = fires
        out["silence_24h"][a] = {"max_gap_s": max_gap, "over_600": over600}
        base = int(NOW // 3600) - 23
        out["burn_series"][a] = [[h, burn.get(h, 0)] for h in range(base, base + 24)]
    return out

# ---- assemble + atomic write ----
doc = {
    "schema": "aria-dashboard/v2",
    "version": "v2.1",
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "agents": {a: {**(last_cycle(a) or {}), "burn24h": usage(a),
                   "req_health_24h": req_health(a)} for a in AGENTS},
    "rotation": rotation(),
    "affect": affect(),
    "house": house(),
    "host": host(),
    "board": board(),
    "open_questions": open_questions(),
    "connectome": connectome(),
}
os.makedirs(OUT, exist_ok=True)
tmp = os.path.join(OUT, ".dashboard.json.tmp")
with open(tmp, "w") as f:
    json.dump(doc, f, indent=1)
os.replace(tmp, os.path.join(OUT, "dashboard.json"))
print("dashboard.json written:", doc["generated_at"])
PYEOF

# ---- oracle context blob (the mouth's window; written for aria-oracle) ----
# Assembled by the TRUSTED generator; the chat model never reads files.
# Privacy contract: same as the JSON -- public-gist rule. fear/boredom
# mouth lines ARE the answer to "what do you fear" and are written for
# public speech by design. No secrets, no REQUESTS bodies, no journal.
if [ "${ORACLE:-1}" = "1" ]; then
python3 - <<'ORACLEPY'
import json, os
REPO = os.environ["REPO"]; OUT = os.environ["OUT_DIR"]
parts = []
def add(title, path, tail=30):
    try:
        lines = open(os.path.join(REPO, path), errors="replace").read().splitlines()
    except Exception:
        return
    lines = [l for l in lines[-tail:] if l.strip()]
    if not lines: return
    parts.append("### " + title)
    parts.extend(lines)
    parts.append("")

try:
    d = json.load(open(os.path.join(OUT, "dashboard.json")))
    parts.append("### DASHBOARD SNAPSHOT (live state)")
    parts.append(json.dumps(d, indent=1)[:12000])
    parts.append("")
except Exception:
    pass

add("FEAR LOG (what the house fears; mouth lines are its own words)", "affect/fear.log", 12)
add("RAGE LOG (what the house rages at; mouth lines are its own words)", "affect/rage.log", 8)
add("BOREDOM LOG (what the house is bored about)", "affect/boredom.log", 6)
for a in ("aria", "continuo"):
    add(a.upper() + " LAST CYCLE", "audit/iar/" + a + "/LAST-CYCLE.txt", 12)
add("RECENT HISTORY (last 20 operational lines)", "audit/iar/aria/HISTORY.log", 20)
add("ROADMAP TOP (current priorities)", "tasks/iar/aria/ROADMAP.org", 40)
try:
    oq = d.get("open_questions") or []
    if oq:
        parts.append("### OPEN QUESTIONS (relay queue awaiting Nacho, oldest first)")
        for x in oq[:10]:
            age = x.get("age_h")
            parts.append("- [%s] %s (%s ago)" % (
                x.get("class") or "?", x.get("title") or x.get("id"),
                ("%.0fh" % age) if age is not None else "?"))
        parts.append("")
except Exception:
    pass

blob = chr(10).join(parts)
with open(os.path.join(OUT, "context.txt"), "w") as f:
    f.write(blob)
print("context.txt written:", len(blob), "chars")
ORACLEPY
fi

# ---- sync UI (repo is the source; served copy is regenerated every run) ----
mkdir -p "$OUT_DIR"
if [ -d "$UI_SRC" ]; then
  cp -f "$UI_SRC"/* "$OUT_DIR"/ 2>/dev/null || true
fi
ln -sf dashboard.json "$OUT_DIR/json"
chmod -R a+rX "$OUT_DIR" 2>/dev/null || true
chown -R caddy:caddy "$OUT_DIR" 2>/dev/null || true
echo "ui synced -> $OUT_DIR"