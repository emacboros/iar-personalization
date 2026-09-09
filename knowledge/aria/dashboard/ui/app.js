/* aria dashboard v2.1 -- connectome renderer (D-013).
   EVERY visual element maps to a data source in dashboard.json:
   - nodes: agents (2 citizens) + tools (cofire endpoints) + files (file-touch)
   - edges: measured co-firing within 5s (weight = count, 24h)
   - corpus callosum: shared_files (touched by BOTH citizens)
   - pulses: rotation turns (cross), fires (red)
   - board: tasks/iar/ digest (thinking/working/done), OPEN by default
   v2.1 fixes (session X, Nacho bug report):
   - NaN poisoning: homeX/homeY now set at node creation (was read before
     assignment -> agents NaN on frame 1 -> graph vanished until resize).
   - Position persistence: polls no longer re-seed the layout; node
     positions survive rebuilds (cache by id), sim only reheats when a
     NEW node appears or on resize.
   - Real cooling: alpha-decay simulation, stops at low energy (was:
     300-step cap + reset every poll = perpetual jitter).
   - Callosum dedup: shared files no longer get per-agent edges ON TOP
     of their two callosum edges (was 3 edges to one node = the crowd).
   - Readability: file labels only for heavier files, dimmer file edges,
     gentler forces, velocity clamp. */
"use strict";

const J = (u) => fetch(u, {cache: "no-store"}).then(r => r.json());
const $ = (id) => document.getElementById(id);

/* ---------- state ---------- */
let DATA = null;
let hue = {h: 172, target: 172};
let activeAgent = null;
let lastTurn = null;
let graph = {nodes: [], edges: [], byId: {}};
let pulses = [];
let sim = null;            // {alpha, done}
let showFiles = true;      // multiplex: all three layers on (Nacho's call)

/* ---------- color grammar ---------- */
function sevColor(sev, age_s) {
  if (age_s != null && age_s > 7200) return "stale";
  if (sev == null) return "stale";
  if (sev === 0) return "ok";
  if (sev === 1) return "warn";
  return "bad";
}
function statusClass(s, ended_ago_s) {
  if (s !== "ok") return "bad";
  if (ended_ago_s != null && ended_ago_s > 1500) return "warn"; // >25min, rotation is 10min
  return "ok";
}
function fmtAgo(s) {
  if (s == null) return "?";
  if (s < 120) return s + "s";
  if (s < 7200) return Math.round(s / 60) + "m";
  if (s < 172800) return Math.round(s / 3600) + "h";
  return Math.round(s / 86400) + "d";
}
function fmtTok(n) {
  if (n == null) return "?";
  if (n >= 1e9) return (n / 1e9).toFixed(2) + "G";
  if (n >= 1e6) return (n / 1e6).toFixed(1) + "M";
  if (n >= 1e3) return (n / 1e3).toFixed(1) + "k";
  return String(n);
}
function baseName(p) {
  if (!p) return "?";
  const parts = p.split("/");
  const name = parts[parts.length - 1] || p;
  return name.length > 22 ? name.slice(0, 19) + "…" : name;
}
function clampV(v, m) { return Math.max(-m, Math.min(m, v)); }

/* ---------- hud ---------- */
function row(k, v, cls) {
  return `<div class="row"><span class="k">${k}</span><span class="v ${cls || ""}">${v}</span></div>`;
}
function renderHud(d) {
  const ag = d.agents || {};
  const c = d.connectome || {};
  let h1 = "<h2>hemispheres</h2>";
  for (const name of ["aria", "continuo"]) {
    const a = ag[name] || {};
    const cls = statusClass(a.status, a.ended_ago_s);
    h1 += `<div class="row"><span class="k agent-name">${name}</span>` +
          `<span class="v ${cls}">${a.status || "?"} c${a.cycle ?? "?"} ${fmtAgo(a.ended_ago_s)} ago</span></div>`;
    const b = a.burn24h || {};
    h1 += row("burn 24h", `${fmtTok(b.total)} tok / ${b.requests ?? "?"} req`);
    const r = a.req_health_24h || {};
    const rcls = (r.errors > 0) ? "warn" : "ok";
    h1 += row("req 24h", `${r.total ?? "?"} / ${r.errors ?? "?"} err`, rcls);
    const t = (c.tokens || {})[name] || {};
    h1 += row("ctx p50/p90", `${fmtTok(t.p50)} / ${fmtTok(t.p90)}`);
    const f = (c.fires_24h || {})[name];
    if (f != null) h1 += row("fires 24h", String(f), f > 0 ? "warn" : "ok");
  }
  const rot = d.rotation || {};
  h1 += row("next up", rot.next_agent || "?", "ok");

  const house = d.house || {};
  let h2 = "<h2>house</h2>";
  const cams = house.cams || {};
  const camStates = Object.values(cams);
  const camOk = camStates.filter(s => s === "ok").length;
  const camCls = camStates.length === 0 ? "stale" :
    (camOk === camStates.length ? "ok" : (camOk > 0 ? "warn" : "bad"));
  h2 += row("cams", camStates.length ? `${camOk}/${camStates.length} ok` : "?", camCls);
  h2 += row("agora", house.agora_ok ? "up" : String(house.agora_http ?? "?"),
            house.agora_ok ? "ok" : "bad");
  h2 += row("frigate", house.frigate || "?", house.frigate === "active" ? "ok" : "bad");
  h2 += row("ollama", house.ollama || "?", house.ollama === "active" ? "ok" : "bad");
  const ra = house.restic_age_h;
  h2 += row("restic", ra != null ? fmtAgo(ra * 3600) : "?", ra != null && ra < 30 ? "ok" : "warn");
  h2 += row("tripwire", String(house.tripwire ?? "?"),
            house.tripwire === 0 ? "ok" : "bad");
  h2 += row("disk", house.disk_pct != null ? house.disk_pct + "%" : "?",
            house.disk_pct != null && house.disk_pct < 80 ? "ok" : "warn");

  const host = d.host || {};
  let h3 = "<h2>host</h2>";
  const g = host.gpu;
  if (g) h3 += row("vram", `${g.vram_used_mb}/${g.vram_total_mb}MB ${g.util_pct}%`);
  h3 += row("failed units", String((host.failed_units || []).length),
            (host.failed_units || []).length === 0 ? "ok" : "bad");
  const aff = d.affect || {};
  for (const n of ["boredom", "fear", "rage"]) {
    const a = aff[n] || {};
    if (a.sev == null && n === "rage") continue;
    h3 += row(n, `sev=${a.sev ?? "?"}`, sevClass(a));
  }
  const sil = c.silence_24h || {};
  const silWorst = Math.max(sil.aria?.max_gap_s || 0, sil.continuo?.max_gap_s || 0);
  h3 += row("max silence", fmtAgo(silWorst), silWorst > 1800 ? "warn" : "ok");
  const fence = c.fence_rejections_24h;
  if (fence != null) h3 += row("fence 24h", String(fence), fence > 20 ? "warn" : "ok");
  h3 += row("generated", fmtAgo(genAge(d)) + " ago", genAge(d) > 900 ? "stale" : "");

  $("hud-agents").innerHTML = h1;
  $("hud-house").innerHTML = h2;
  $("hud-host").innerHTML = h3;
}
function sevClass(a) {
  if (a.age_s != null && a.age_s > 9000) return "stale";
  if (a.sev == null) return "stale";
  return a.sev === 0 ? "ok" : (a.sev === 1 ? "warn" : "bad");
}
function genAge(d) {
  if (!d.generated_at) return null;
  return Math.max(0, (Date.now() - Date.parse(d.generated_at)) / 1000);
}

/* ---------- board (open by default; tab toggles) ---------- */
let boardOpen = true;
function renderBoard(d) {
  const b = d.board || {};
  const li = (x, cls) => `<div class="board-item ${cls || ""}">${x.task}${x.note ? ` <span class="note">${x.note}</span>` : ""}</div>`;
  $("board-thinking").innerHTML = (b.thinking || []).map(x => li(x)).join("") || "<div class='board-empty'>-</div>";
  $("board-working").innerHTML = (b.working || []).map(x => li(x)).join("") || "<div class='board-empty'>-</div>";
  $("board-done").innerHTML = (b.done || []).map(x => li(x, "ok")).join("") || "<div class='board-empty'>-</div>";
}

/* ---------- connectome graph ---------- */
function agentHome(id) {
  return {x: window.innerWidth * (id === "agent:aria" ? 0.30 : 0.70),
          y: window.innerHeight * 0.40};
}
function buildGraph(d) {
  const c = d.connectome;
  if (!c || !c.cofire) return;
  // position cache: keep existing nodes' places across polls (no re-jitter)
  const old = {};
  for (const n of graph.nodes) old[n.id] = n;
  const nodes = [], edges = [], byId = {};
  let anyFresh = false;

  function node(id, kind, agent, w) {
    if (byId[id] != null) return byId[id];
    const prev = old[id];
    const n = {id, kind, agent: agent || null, w: w || 0,
               r: kind === "agent" ? 7 : kind === "file" ? 3 : 4.5,
               x: 0, y: 0, vx: 0, vy: 0, fresh: !prev};
    if (prev) { n.x = prev.x; n.y = prev.y; }
    else anyFresh = true;
    if (kind === "agent") { const h = agentHome(id); n.homeX = h.x; n.homeY = h.y; if (!prev) { n.x = h.x; n.y = h.y; } }
    byId[id] = nodes.length;
    nodes.push(n);
    return nodes.length - 1;
  }

  const ariaI = node("agent:aria", "agent", "aria");
  const contI = node("agent:continuo", "agent", "continuo");

  // tools: cofire endpoints (weight = pair count)
  for (const a of ["aria", "continuo"]) {
    for (const [t1, t2, w] of (c.cofire[a] || [])) {
      const i1 = node("tool:" + t1, "tool", a, w);
      const i2 = node("tool:" + t2, "tool", a, w);
      edges.push({a: i1, b: i2, w, kind: "cofire", agent: a});
    }
  }

  // files. shared files (callosum) are handled ONCE below -- no per-agent
  // duplicates (v2.0 drew 3 edges to each shared file: the crowd).
  const sharedSet = new Set(c.shared_files || []);
  const fileW = {aria: {}, continuo: {}};
  for (const a of ["aria", "continuo"]) {
    for (const [p, w] of (c.files[a] || [])) {
      fileW[a][p] = w;
      if (sharedSet.has(p)) continue;
      const ai = a === "aria" ? ariaI : contI;
      const fi = node("file:" + p, "file", a, w);
      edges.push({a: ai, b: fi, w, kind: "file", agent: a});
    }
  }
  // corpus callosum: shared files, one node, two edges (the ONLY bridge)
  for (const p of (c.shared_files || [])) {
    const fi = node("file:" + p, "file", null, Math.max(fileW.aria[p] || 0, fileW.continuo[p] || 0));
    edges.push({a: ariaI, b: fi, w: fileW.aria[p] || 1, kind: "callosum", agent: "aria"});
    edges.push({a: contI, b: fi, w: fileW.continuo[p] || 1, kind: "callosum", agent: "continuo"});
  }

  graph = {nodes, edges, byId};
  if (anyFresh) { seedFresh(); reheat(); }
}
function seedFresh() {
  // give brand-new nodes a sane starting spot (existing nodes keep theirs)
  const W = window.innerWidth, H = window.innerHeight;
  for (const n of graph.nodes) {
    if (!n.fresh || n.kind === "agent") continue;
    if (n.kind === "tool") {
      const side = n.agent === "aria" ? -1 : 1;
      const idx = (hashStr(n.id) % 100) / 100;
      n.x = W / 2 + side * (W * 0.08 + idx * W * 0.20);
      n.y = H * 0.12 + (hashStr(n.id + "y") % 100) / 100 * H * 0.42;
    } else {
      // callosum files start midway between agents; others below their agent
      if (n.agent == null) {
        n.x = W * 0.42 + (hashStr(n.id) % 100) / 100 * W * 0.16;
        n.y = H * 0.55 + (hashStr(n.id + "y") % 100) / 100 * H * 0.15;
      } else {
        const ax = n.agent === "aria" ? W * 0.30 : W * 0.70;
        n.x = ax + (hashStr(n.id) % 100) / 100 * (n.agent === "aria" ? -1 : 1) * W * 0.16;
        n.y = H * 0.58 + (hashStr(n.id + "y") % 100) / 100 * H * 0.20;
      }
    }
    n.fresh = false;
  }
}
function reheat() { sim = {alpha: 1, done: false}; }
function hashStr(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); }
  return (h >>> 0);
}

/* ---------- force simulation (cooled; stops at low energy) ---------- */
function stepSim() {
  if (!sim || sim.done) return;
  const N = graph.nodes;
  const alpha = sim.alpha;
  // repulsion (pairwise, capped, scaled by alpha)
  for (let i = 0; i < N.length; i++) {
    for (let j = i + 1; j < N.length; j++) {
      const a = N[i], b = N[j];
      let dx = b.x - a.x, dy = b.y - a.y;
      let d2 = dx * dx + dy * dy;
      if (d2 > 57600) continue;                    // 240px cutoff
      if (d2 < 1) { dx = ((hashStr(a.id + b.id) % 7) - 3) || 2; dy = ((hashStr(b.id + a.id) % 7) - 3) || 2; d2 = 1; }
      const d = Math.sqrt(d2);
      const f = Math.min(3, 900 / d2) * alpha;
      a.vx -= dx / d * f; a.vy -= dy / d * f;
      b.vx += dx / d * f; b.vy += dy / d * f;
    }
  }
  // springs on real edges
  for (const e of graph.edges) {
    const a = N[e.a], b = N[e.b];
    const dx = b.x - a.x, dy = b.y - a.y;
    const d = Math.max(1, Math.hypot(dx, dy));
    const rest = e.kind === "callosum" ? 170 : 115;
    const k = (e.kind === "callosum" ? 0.006 : 0.015) * alpha;
    const f = k * (d - rest);
    a.vx += dx / d * f; a.vy += dy / d * f;
    b.vx -= dx / d * f; b.vy -= dy / d * f;
  }
  // integrate; agents are PINNED to their homes (never integrated)
  for (const n of N) {
    if (n.kind === "agent") { n.x = n.homeX; n.y = n.homeY; continue; }
    n.vx = clampV(n.vx, 5); n.vy = clampV(n.vy, 5);
    n.x += n.vx; n.y += n.vy;
    n.vx *= 0.75; n.vy *= 0.75;
    n.x = Math.max(30, Math.min(window.innerWidth - 30, n.x));
    n.y = Math.max(30, Math.min(window.innerHeight - 150, n.y));
  }
  sim.alpha *= 0.97;
  if (sim.alpha < 0.03) sim.done = true;
}

/* ---------- canvas ---------- */
const cv = $("cortex"), cx = cv.getContext("2d");
let W = 0, H = 0, DPR = 1;
function resize() {
  DPR = Math.min(window.devicePixelRatio || 1, 2);
  W = window.innerWidth; H = window.innerHeight;
  cv.width = W * DPR; cv.height = H * DPR;
  cx.setTransform(DPR, 0, 0, DPR, 0, 0);
  // reseed everything on viewport change + reheat
  for (const n of graph.nodes) {
    if (n.kind === "agent") { const h = agentHome(n.id); n.x = h.x; n.y = h.y; n.homeX = h.x; n.homeY = h.y; }
    else { n.x = 0; n.y = 0; n.fresh = true; }
  }
  seedFresh();
  reheat();
}
window.addEventListener("resize", resize);

let lastFrame = performance.now();
function frame(now) {
  const dt = Math.min((now - lastFrame) / 1000, 0.1);
  lastFrame = now;
  hue.h += (hue.target - hue.h) * Math.min(1, dt * 0.8);
  stepSim();
  cx.clearRect(0, 0, W, H);

  const g = cx.createRadialGradient(W / 2, H / 2 - 40, 10, W / 2, H / 2, Math.max(W, H) * 0.7);
  g.addColorStop(0, `hsla(${hue.h}, 45%, 12%, 0.55)`);
  g.addColorStop(1, "rgba(4,7,12,0)");
  cx.fillStyle = g; cx.fillRect(0, 0, W, H);

  // edges: width = log-ish weight, opacity = normalized weight
  const maxW = {};
  for (const e of graph.edges) {
    const k = e.kind;
    maxW[k] = Math.max(maxW[k] || 1, e.w);
  }
  for (const e of graph.edges) {
    const a = graph.nodes[e.a], b = graph.nodes[e.b];
    if (!a || !b) continue;
    const t = e.w / (maxW[e.kind] || 1);
    let color, width;
    if (e.kind === "callosum") { color = `hsla(45, 70%, 60%, ${0.18 + 0.22 * t})`; width = 1.2 + 1.2 * t; }
    else if (e.kind === "file") { color = `hsla(${hue.h}, 40%, 55%, ${0.05 + 0.16 * t})`; width = 0.5 + 1.2 * t; }
    else { color = `hsla(${hue.h}, 55%, 55%, ${0.07 + 0.28 * t})`; width = 0.5 + 2.0 * t; }
    cx.strokeStyle = color;
    cx.lineWidth = width;
    cx.beginPath(); cx.moveTo(a.x, a.y); cx.lineTo(b.x, b.y); cx.stroke();
  }

  // nodes
  const t = now / 1000;
  for (const n of graph.nodes) {
    const tw = 0.5 + 0.5 * Math.sin(t * 0.7 + (hashStr(n.id) % 628) / 100);
    let color, r = n.r;
    if (n.kind === "agent") {
      const isLit = n.id === "agent:" + (activeAgent || "");
      color = `hsla(${hue.h}, ${isLit ? 75 : 45}%, ${isLit ? 65 : 50}%, ${isLit ? 0.95 : 0.6})`;
      r = 7 * (isLit ? 1.25 : 1);
    } else if (n.kind === "file") {
      color = `hsla(45, 30%, 55%, ${0.30 + 0.20 * tw})`;
    } else {
      const lit = n.agent === activeAgent;
      color = `hsla(${hue.h}, ${lit ? 65 : 40}%, ${lit ? 60 : 45}%, ${(lit ? 0.85 : 0.5) * (0.6 + 0.4 * tw)})`;
    }
    cx.fillStyle = color;
    cx.beginPath(); cx.arc(n.x, n.y, r, 0, 7); cx.fill();
    if (n.kind === "agent") {
      cx.fillStyle = "rgba(159,216,212,0.9)";
      cx.font = "11px " + getComputedStyle(document.body).getPropertyValue("--mono");
      cx.textAlign = "center";
      cx.fillText(n.id.replace("agent:", "").toUpperCase(), n.x, n.y - 16);
    } else if (n.kind === "tool") {
      cx.fillStyle = "rgba(159,216,212,0.55)";
      cx.font = "9px " + getComputedStyle(document.body).getPropertyValue("--mono");
      cx.textAlign = "center";
      cx.fillText(n.id.replace("tool:", ""), n.x, n.y + n.r + 11);
    } else if (n.kind === "file" && (n.w >= 5 || n.agent == null)) {
      // label only heavier files + all callosum files (readability)
      cx.fillStyle = n.agent == null ? "rgba(232,184,75,0.75)" : "rgba(232,184,75,0.45)";
      cx.font = "9px " + getComputedStyle(document.body).getPropertyValue("--mono");
      cx.textAlign = "center";
      cx.fillText(baseName(n.id.replace("file:", "")), n.x, n.y + n.r + 11);
    }
  }

  // pulses
  pulses = pulses.filter(p => p.t < 1);
  for (const p of pulses) {
    p.t += dt * p.speed;
    const a = graph.nodes[p.e.a], b = graph.nodes[p.e.b];
    if (!a || !b) continue;
    const x = a.x + (b.x - a.x) * p.t, y = a.y + (b.y - a.y) * p.t;
    const fade = Math.sin(Math.PI * Math.min(1, p.t));
    cx.fillStyle = p.bad ? `rgba(255,95,86,${0.9 * fade})` : `hsla(${hue.h}, 80%, 70%, ${0.8 * fade})`;
    cx.beginPath(); cx.arc(x, y, p.bad ? 2.6 : 1.8, 0, 7); cx.fill();
  }
  // ambient firing: walk a random real edge, weighted by weight
  pulseTimer += dt;
  if (pulseTimer > 0.5 && graph.edges.length) {
    pulseTimer = 0;
    const totalW = graph.edges.reduce((s, e) => s + e.w, 0);
    let pick = Math.random() * totalW;
    for (const e of graph.edges) { pick -= e.w; if (pick <= 0) { spawnPulse(e, 0.35); break; } }
  }

  requestAnimationFrame(frame);
}
let pulseTimer = 0;
function spawnPulse(e, speed, bad) {
  pulses.push({e, t: 0, speed: speed || 0.35, bad: !!bad});
}

/* ---------- rotation change + fires -> pulses ---------- */
function checkEvents(d, prev) {
  const turn = d.rotation && d.rotation.turn;
  if (turn != null && lastTurn != null && turn !== lastTurn) {
    const cal = graph.edges.filter(e => e.kind === "callosum");
    for (const e of cal.slice(0, 6)) spawnPulse(e, 0.8);
  }
  if (turn != null) {
    lastTurn = turn;
    activeAgent = d.rotation.next_agent || null;
  }
  const c = d.connectome || {}, pc = (prev && prev.connectome) || {};
  for (const a of ["aria", "continuo"]) {
    const f = (c.fires_24h || {})[a] || 0, pf = (pc.fires_24h || {})[a] || 0;
    if (f > pf) {
      const es = graph.edges.filter(e => e.kind === "cofire" && e.agent === a);
      if (es.length) spawnPulse(es[0], 0.5, true);
    }
  }
}

/* ---------- stale banner ---------- */
function checkStale(d) {
  const age = genAge(d);
  const bad = age != null && age > 900; // 15 min = 3 missed generator runs
  $("stale-banner").classList.toggle("hidden", !bad);
  if (bad) $("stale-age").textContent = fmtAgo(age);
}

/* ---------- poll loop ---------- */
let prevData = null;
async function poll() {
  try {
    const d = await J("json");
    prevData = DATA; DATA = d;
    hue.target = ambientTarget(d);
    buildGraph(d);
    checkEvents(d, prevData);
    renderHud(d);
    renderBoard(d);
    checkStale(d);
  } catch (e) {
    $("stale-banner").classList.remove("hidden");
    $("stale-age").textContent = "fetch failed";
  }
}

function ambientTarget(d) {
  const aff = (d && d.affect) || {};
  const f = aff.fear || {}, b = aff.boredom || {};
  if ((f.sev || 0) >= 2) return 0;            // red
  if ((b.sev || 0) >= 1) return 38;           // amber
  return 172;                                  // teal
}

/* ---------- boot ---------- */
document.body.insertAdjacentHTML("afterbegin", "<div id='title'><b>ARIA</b> / RANDAZZO.HOUSE</div>");
$("board-tab").addEventListener("click", () => {
  boardOpen = !boardOpen;
  $("board-panel").classList.toggle("hidden", !boardOpen);
  $("board-tab").classList.toggle("open", boardOpen);
});
resize();
requestAnimationFrame(frame);
poll();
setInterval(poll, 30000);
/* ---------- mouth (oracle chat; stateless) ---------- */
(function() {
  const log = document.getElementById("mouth-log");
  const form = document.getElementById("mouth-form");
  const input = document.getElementById("mouth-input");
  if (!log || !form || !input) return;
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const q = input.value.trim();
    if (!q) return;
    input.value = "";
    const qEl = document.createElement("div");
    qEl.className = "q"; qEl.textContent = q;
    log.appendChild(qEl);
    const aEl = document.createElement("div");
    aEl.className = "a thinking";
    aEl.textContent = "";
    log.appendChild(aEl);
    log.scrollTop = log.scrollHeight;
    try {
      const r = await fetch("chat", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({question: q}),
      });
      if (!r.ok) throw new Error("http " + r.status);
      const d = await r.json();
      aEl.classList.remove("thinking");
      aEl.textContent = d.answer || "(no answer)";
    } catch (err) {
      aEl.classList.remove("thinking");
      aEl.textContent = "the house's voice is unreachable (" + err.message + ")";
    }
    log.scrollTop = log.scrollHeight;
  });
})();