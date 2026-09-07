# Dashboard -- JSON contract for cycles (2026-09-07, Nacho mandate)

## What it is
aria.randazzo.ar -- the house's centralized status. Generator runs every
5 min on sophon (aria-dashboard.timer), writes dashboard.json + serves the
UI. The generator script IS in the repo: knowledge/aria/bin/aria-dashboard.sh.
Repo version IS the running version.

## READ IT FIRST at wake (budget law)
    curl -s http://10.66.0.5:8095/json
One read replaces the old six-probe ssh pulse: agents (status/cycle/
ended_ago/burn24h/req_health), rotation (turn/next_agent/timer),
affect (boredom/fear sev+age), house (cams/agora/frigate/ollama/restic/
tripwire/disk/canary), host (gpu/failed_units/containers/models/timers).
ssh only for what the JSON lacks.

## EXTENDING THE JSON (allowed, encouraged)
If a cycle needs a debug field nobody tracks yet: ADD IT to
knowledge/aria/bin/aria-dashboard.sh (python section, "assemble" block),
differential-test locally (run the script, compare new field vs ground
truth), commit, push sophon-bare. The timer picks it up within 5 min.
Rules:
- Counts, states, ages, names, numbers ONLY. Public unauthenticated
  endpoint. NEVER: secrets, REQUESTS.log bodies/tails (prompt
  fragments), journal/thinking text, tenant data.
- Every new source wrapped in try/except; missing source -> null, not
  a crashed generator. A dead generator = dead house view.
- Bump "version" in the doc when you change the schema.
- Do NOT touch knowledge/aria/dashboard/ui/* (HTML/JS/CSS). The view is
  maintained in interactive sessions with Nacho; a cycle that edits UI
  files can break the on-screen render and nobody in a cycle can see
  the breakage. If your new field deserves a visual, say so in the
  commit message / lab-notes -- an interactive session will wire it.

## Contract
- schema: aria-dashboard/v1 (bump minor on additive changes)
- Stale is visible: generated_at + UI shows STALE banner >15min.
- If the generator fails, it still emits JSON with nulls -- never
  silently stop writing.