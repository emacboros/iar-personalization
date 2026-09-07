/* aria dashboard v1.1 -- cortex canvas + hud renderer. v2 geometry:
   lobes are off-midline ellipses with a fissure gap; dendrites anchor to
   mesh nodes. Verified via SVG-dump audit (see JOURNAL 2026-09-07).
   Polls /json (dashboard.json) every 30s; canvas animates at rAF.
   All motion is slow (burn-in mitigation for an always-on screen). */
"use strict";

const J = (u) => fetch(u, {cache: "no-store"}).then(r => r.json());
const $ = (id) => document.getElementById(id);

/* ---------- state ---------- */
let DATA = null, DATA_TS = 0;
let hue = {h: 172, target: 172};           // ambient hue (teal default)
let activeAgent = null;                     // which hemisphere is lit
let lastTurn = null;

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

/* ---------- hud ---------- */
function row(k, v, cls) {
  return `<div class="row"><span class="k">${k}</span><span class="v ${cls || ""}">${v}</span></div>`;
}
function renderHud(d) {
  const ag = d.agents || {};
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
  h2 += row("agora", house.agora_http === 200 ? "up" : String(house.agora_http ?? "?"),
            house.agora_http === 200 ? "ok" : "bad");
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
  for (const n of ["boredom", "fear"]) {
    const a = aff[n] || {};
    h3 += row(n, `sev=${a.sev ?? "?"}`, sevClass(a));
  }
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

/* ---------- cortex canvas ---------- */
const cv = $("cortex"), cx = cv.getContext("2d");
let W = 0, H = 0, DPR = 1;
function resize() {
  DPR = Math.min(window.devicePixelRatio || 1, 2);
  W = window.innerWidth; H = window.innerHeight;
  cv.width = W * DPR; cv.height = H * DPR;
  cx.setTransform(DPR, 0, 0, DPR, 0, 0);
  buildMesh();
}
window.addEventListener("resize", resize);

/* two hemispheres of nodes + inter-hemisphere synapses + cam dendrites */
let nodes = [], synapses = [], dendrites = [], pulses = [];
function buildMesh() {
  nodes = []; synapses = []; dendrites = []; pulses = [];
  const cx0 = W / 2, cy0 = H / 2 - 40;
  const R = Math.min(W, H) * 0.30;
  const rnd = mulberry32(20260907); // stable layout across reloads
  // v2: each lobe is a full ellipse centered OFF-midline; a GAP corridor
  // (the fissure) separates them. No node crosses the midline by construction.
  const GAP = R * 0.30, RX = R * 0.55, RY = R * 0.62;
  for (const side of [-1, 1]) {
    const n = 26;
    for (let i = 0; i < n; i++) {
      const a = rnd() * Math.PI * 2;
      const rr = 0.30 + 0.70 * Math.sqrt(rnd()); // 0.30..1.00 of lobe radius
      nodes.push({
        x: cx0 + side * (GAP + RX) + side * rr * Math.cos(a) * RX,
        y: cy0 + rr * Math.sin(a) * RY,
        side, r: 1.2 + rnd() * 1.8, ph: rnd() * Math.PI * 2,
      });
    }
  }
  // intra-hemisphere edges (near neighbors)
  for (let i = 0; i < nodes.length; i++) {
    for (let j = i + 1; j < nodes.length; j++) {
      const a = nodes[i], b = nodes[j];
      if (a.side === b.side) {
        const d = Math.hypot(a.x - b.x, a.y - b.y);
        if (d < R * 0.42) synapses.push({a: i, b: j, d});
      }
    }
  }
  // corpus callosum: a few cross edges
  const left = nodes.filter(n => n.side < 0), right = nodes.filter(n => n.side > 0);
  for (let k = 0; k < 5; k++) {
    const a = left[Math.floor(rnd() * left.length)];
    const b = right[Math.floor(rnd() * right.length)];
    synapses.push({a: nodes.indexOf(a), b: nodes.indexOf(b), d: Math.hypot(a.x - b.x, a.y - b.y), cross: true});
  }
  // labels
  nodes.labels = {
    aria: {x: cx0 - (GAP + RX), y: cy0 - RY - 18},
    continuo: {x: cx0 + (GAP + RX), y: cy0 - RY - 18},
  };
  // v2 dendrites: anchored to real mesh nodes (nearest to each cam's x-slot
  // along the bottom edge), dropping straight down -- visually connected.
  const camNames = Object.keys((DATA && DATA.house && DATA.house.cams) || {});
  const names = camNames.length ? camNames : ["exterior_1","exterior_2","exterior_3","exterior_4","exterior_5","interior_1","interior_2","interior_3"];
  const meshBottom = Math.max(...nodes.map(n => n.y));
  const meshXMin = Math.min(...nodes.map(n => n.x));
  const meshXMax = Math.max(...nodes.map(n => n.x));
  names.forEach((nm, i) => {
    const tx = meshXMin + (i + 0.5) / names.length * (meshXMax - meshXMin);
    const anchor = nodes.reduce((best, n) =>
      (Math.abs(n.x - tx) + Math.abs(n.y - meshBottom) <
       Math.abs(best.x - tx) + Math.abs(best.y - meshBottom)) ? n : best);
    dendrites.push({
      name: nm,
      x: anchor.x, y: anchor.y,
      dropY: H * 0.80 + Math.sin(i * 1.7) * 12,
      state: (DATA && DATA.house && DATA.house.cams && DATA.house.cams[nm]) || "stale",
    });
  });
}
function mulberry32(s) {
  return function() {
    s |= 0; s = (s + 0x6D2B79F5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/* ambient hue from affect */
function ambientTarget(d) {
  const aff = (d && d.affect) || {};
  const f = aff.fear || {}, b = aff.boredom || {};
  if ((f.sev || 0) >= 2) return 0;            // red
  if ((b.sev || 0) >= 1) return 38;           // amber
  return 172;                                  // teal
}

/* spawn a pulse along a synapse */
function spawnPulse(syn, speed) {
  pulses.push({syn, t: 0, speed: speed || 0.35});
}

let lastFrame = performance.now(), pulseTimer = 0;
function frame(now) {
  const dt = Math.min((now - lastFrame) / 1000, 0.1);
  lastFrame = now;
  hue.h += (hue.target - hue.h) * Math.min(1, dt * 0.8);

  cx.clearRect(0, 0, W, H);

  // vignette ambient
  const g = cx.createRadialGradient(W / 2, H / 2 - 40, 10, W / 2, H / 2, Math.max(W, H) * 0.7);
  g.addColorStop(0, `hsla(${hue.h}, 45%, 12%, 0.55)`);
  g.addColorStop(1, "rgba(4,7,12,0)");
  cx.fillStyle = g; cx.fillRect(0, 0, W, H);

  // synapse lines
  cx.lineWidth = 0.6;
  for (const s of synapses) {
    const a = nodes[s.a], b = nodes[s.b];
    cx.strokeStyle = s.cross ? `hsla(${hue.h}, 60%, 55%, 0.22)` : `hsla(${hue.h}, 50%, 50%, 0.10)`;
    cx.beginPath(); cx.moveTo(a.x, a.y); cx.lineTo(b.x, b.y); cx.stroke();
  }
  // nodes
  const t = now / 1000;
  for (const n of nodes) {
    const tw = 0.5 + 0.5 * Math.sin(t * 0.7 + n.ph);
    const lit = n.side === (activeAgent === "aria" ? -1 : 1);
    const base = lit ? 0.9 : 0.45;
    cx.fillStyle = `hsla(${hue.h}, ${lit ? 70 : 45}%, ${lit ? 62 : 45}%, ${base * (0.55 + 0.45 * tw)})`;
    cx.beginPath(); cx.arc(n.x, n.y, n.r * (lit ? 1.35 : 1), 0, 7); cx.fill();
  }
  // pulses
  pulseTimer += dt;
  if (pulseTimer > 0.9 && synapses.length) {
    pulseTimer = 0;
    const s = synapses[Math.floor(Math.random() * synapses.length)];
    spawnPulse(s, s.cross ? 0.5 : 0.3);
  }
  pulses = pulses.filter(p => p.t < 1);
  for (const p of pulses) {
    p.t += dt * p.speed;
    const a = nodes[p.syn.a], b = nodes[p.syn.b];
    const x = a.x + (b.x - a.x) * p.t, y = a.y + (b.y - a.y) * p.t;
    const fade = Math.sin(Math.PI * Math.min(1, p.t));
    cx.fillStyle = `hsla(${hue.h}, 80%, 70%, ${0.8 * fade})`;
    cx.beginPath(); cx.arc(x, y, 1.6, 0, 7); cx.fill();
  }
  // labels
  cx.font = "10px " + getComputedStyle(document.body).getPropertyValue("--mono");
  cx.textAlign = "center";
  cx.fillStyle = `hsla(${hue.h}, 40%, 70%, ${activeAgent === "aria" ? 0.95 : 0.4})`;
  cx.fillText("ARIA", nodes.labels.aria.x, nodes.labels.aria.y);
  cx.fillStyle = `hsla(${hue.h}, 40%, 70%, ${activeAgent === "continuo" ? 0.95 : 0.4})`;
  cx.fillText("CONTINUO", nodes.labels.continuo.x, nodes.labels.continuo.y);

  // dendrites (cams): straight drop from the anchor node
  for (const dnd of dendrites) {
    const okC = "rgba(53,208,160,", stC = "rgba(107,114,128,", faC = "rgba(255,95,86,";
    const lineC = dnd.state === "ok" ? okC + "0.45)" : dnd.state === "stale" ? stC + "0.35)" : faC + "0.55)";
    const dotC  = dnd.state === "ok" ? okC + "0.9)"  : dnd.state === "stale" ? stC + "0.9)"  : faC + "0.9)";
    cx.strokeStyle = lineC;
    cx.lineWidth = 0.8;
    cx.beginPath();
    cx.moveTo(dnd.x, dnd.y);
    cx.lineTo(dnd.x, dnd.dropY);
    cx.stroke();
    cx.fillStyle = dotC;
    cx.beginPath(); cx.arc(dnd.x, dnd.dropY, 2.2, 0, 7); cx.fill();
    cx.fillStyle = "rgba(159,216,212,0.55)";
    cx.textAlign = "center";
    cx.fillText(dnd.name, dnd.x, dnd.dropY + 14);
  }

  requestAnimationFrame(frame);
}

/* ---------- rotation change -> cross-hemisphere fire ---------- */
function checkTurn(d) {
  const turn = d.rotation && d.rotation.turn;
  if (turn != null && lastTurn != null && turn !== lastTurn && synapses.length) {
    const cross = synapses.filter(s => s.cross);
    for (const s of (cross.length ? cross : synapses.slice(0, 3))) spawnPulse(s, 0.8);
  }
  if (turn != null) {
    lastTurn = turn;
    activeAgent = d.rotation.next_agent || null; // next up = lit hemisphere
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
async function poll() {
  try {
    const d = await J("json");
    DATA = d; DATA_TS = Date.now();
    hue.target = ambientTarget(d);
    checkTurn(d);
    renderHud(d);
    checkStale(d);
    buildMesh(); // refresh dendrite states
  } catch (e) {
    $("stale-banner").classList.remove("hidden");
    $("stale-age").textContent = "fetch failed";
  }
}

/* ---------- boot ---------- */
document.body.insertAdjacentHTML("afterbegin", "<div id='title'><b>ARIA</b> / RANDAZZO.HOUSE</div>");
resize();
requestAnimationFrame(frame);
poll();
setInterval(poll, 30000);