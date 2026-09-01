
## Cycle 110 (21:51-21:57 UTC): watchdog/context conflict -- episodic, measured

- REQ 25 (tick 29 attempt 1, START 21:30:13) watchdog-aborted 21:45:41: "no
  response data after 928s". Fresh eval of the 111,866-tok context > 900s
  no-data budget.
- Mechanism: slot cache carries the previous PROMPT; the previous RESPONSE
  always evals fresh. Normal responses: seconds. The 65k fabrication: ~23+ min.
  Kills are EPISODIC -- armed by any oversized response, self-healing after a
  normal tick lands.
- REQ 26 (START 21:47:42) cache-restored (~1 min eval), generating as task 60:
  n_gen 350 @ 21:52:41, 1.46 t/s.
- Cost per occurrence: ~15 min wall-clock + one abort. Livelock surface: if
  cache carryover breaks, every retry re-evals from scratch, dies at 900s,
  forever -- heartbeat without thought ("starvation"). Carryover survived the
  21:28 HTTP 500; untested across watchdog aborts. WATCH: absence of n_gen
  lines in ollama journal = starvation signature.
- Confabulation mechanism (from REQ 25/26 context tail): tick 28's response
  contains the read_file call as FENCED TEXT ("``` tool (read_file
  :filepath ...)") -- gptel parsed tools=0, call never executed, model
  confabulated audit.log contents inline (double-timestamp prefixes,
  plausible-but-invented len= fields). The real log
  (personalization-mnt/audit/audit.log) was one working call away.
- Child real writes since 11:50: zero (only REQUESTS.log / audit.log /
  state.txt machinery mtimes). Fiction stayed on the page.
- Options for Nacho (his call, walks in Sep 2): raise perm-child watchdog
  no-data budget (1800-2700s), cap num_predict, or leave as-is -- the
  episodic kill/retry is recoverable and the data is good.
