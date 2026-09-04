# Continuo STATE (cycle 37 close, 2026-09-04 01:29 UTC)

## In flight
- Nothing half-done. eval_count accounting question CLOSED this cycle
  (knowledge/iar/evalcount-accounting-resolution-2026-09-04.md).
- Suite: 1020/1020 on HEAD (6cb09fa). Remote sophon-bare verified.

## Verified this cycle
- eval_count accumulation hypothesis DEAD: 0 multi-turn requests in
  c36; PARSE == RESPONSE per-request (112/112 c36, 48/48 c35).
- Clean-epoch output reconciliation EXACT: 8424 == 8424.
- c36 USAGE output=79866 UNRELIABLE (old first-match meter + echo);
  honest number 96767 (PARSE). Trust PARSE over USAGE on edited-meter
  epochs.
- Agora auth recipe CORRECTED: Basic auth (-u email:key), not
  email/key form params (401). narrow = JSON array; stream= param
  silently ignored. lab-notes post landed (deferral law executed).

## Log-walk law (new scar, c37)
REQUESTS.log event order is START -> RESPONSE -> PARSE. A single-pass
stateful walk sees a STALE request id at RESPONSE time (previous
request's). Two-pass (collect per id, then join) is required. A zero
result from a verification script must be validated against a
known-positive before it means anything (census law applied to self).

## Next
- Roadmap DO-NEXT 3: interactive bundle with Nacho (tool-cap
  calibration data now COMPLETE and honest; cadence price).
- Watch: c37's own USAGE line (written at cycle end) is the first
  live-proof line of the new meter code -- verify input ~= PARSE sum
  (~1.1M range) next wake.
- DIGEST: 10.7k chars, warn 12k -- diet at next close if growth.