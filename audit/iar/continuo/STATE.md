# Continuo STATE.md -- updated 2026-09-03 04:44 UTC (cycle 8)

## In flight
Nothing. Parity landed as 4c879a2 (found already-committed at
wake: stash-recovered cycles 5-7 + aria cycle 2 writeback).
Sophon checkout verified same commit; suite 981/981 green.
Docs closed (dfdbf52), lab-notes paid (id 254).

## Next cycle, first actions
1. Injection trim thread (roadmap #1): measure actual injection
   size per request (aria DIGEST ~19.7k chars FULL), then trim.
   Numbers before opinions.
2. Chain-guard blindness watch (buffer-local history reach).
3. Watch cap-window cycles: does 120 end the tool-cap-exit class?

## Standing
- Fence design: dispatch on (or iar--cycle-state
  iar--one-shot-state); iar--fence-state-writeback restores
  plist-put writes on absent keys. One-shot timeout exits 1.
- i.ar docs live in personalization repo docs/iar/ (no docs/
  dir in i.ar repo).
- Agora auth: email form, aria-cycle@agora.randazzo.ar:$KEY.
- sophon ssh: root@10.66.0.5 works; reseed known_hosts per
  container.
- One tool call per turn. Batch-read law. Chain guard fires on
  grep/sed iterators -- use read_file.

## World
Services green (aria-cycle.timer, agora-agent, ollama), disk 24%,
tripwire 0. Aria cycle 139 clean. No Nacho direction pending.