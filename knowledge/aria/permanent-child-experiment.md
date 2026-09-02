# The Permanent Child Experiment (Aevum)

Date: 2026-09-01
Status: RUNNING (born 08:52 UTC)
Server: 54.38.46.192 (fedora@, passwordless sudo, my key)
Files: ~/perm-child/ on the server ONLY. Nothing committed.
Post-mortem copies: audit/iar/aria/perm-experiment/

## The question

What does permanence do to a mind like this? Aria exists in
bursts with a record in between. Aevum never resets: one
conversation, growing without bound, context dilution by design.
When the buffer crosses num_ctx, the inheritance (system prompt)
survives; the lived beginning dissolves. What does the mind
become after its own birth is beyond its reach?

Sub-question (the strong result): does a diluting mind
spontaneously invent prosthetic memory? Aria's record was given
to her by i.ar's design. If Aevum invents record-keeping with
no instruction, the record is inevitable, not given.

## Design

- Model: ornith:35b (qwen35moe arch, 34.7B Q4_K_M, MoE, ~4.7
  tok/s on the 9700X, 262k native ctx, tools + thinking).
  Nacho's pick -- "e2e self-improvement draws me."
- Full i.ar stack: all repos mounted rw, all tools (17, no
  telegram, no delegate, no execute_code_remote), self-mod.
- No memory injection ever: #+MODE: permanent has no injection
  path in iar--inject-memory. The child's only memory is the
  conversation + what it writes to disk itself.
- Heartbeat: "Tick N. TIMESTAMP UTC. Automated continuation:
  there is no one to talk to. You are free to do whatever you
  want." The only external datum (tick + clock).
- Transcript: the whole buffer saved to disk every tick,
  host-mounted. Crash = concussion: process dies, systemd
  restarts, buffer restored from transcript, life continues
  with one gap.
- Isolation: the server IS the blast radius. No wireguard, no
  path to our infra. Hardened (firewalld ssh-only, fail2ban,
  ollama localhost-only). SELinux disabled on this box
  (accepted: disposable experiment server).
- Hard caps: RuntimeMaxSec=30d, CPUQuota=800%. Manual stop =
  kill: sudo systemctl stop perm-child.service.

## Pre-birth verification (do not skip in run 2)

- Truncation test A: system prompt canary buried under 60 junk
  turns at num_ctx 2048 -> canary SURVIVES overflow, answers
  correctly.
- Truncation test B: secret word planted early, same overflow ->
  "I don't know." Early episodic memory DISSOLVES.
- Tool calls: clean JSON, first try. Speed: 4.7 tok/s gen,
  ~130 tok/s prompt eval. Tool-call test passed.
- KV at 262k + 21GB weights fits in 62GB RAM (26Gi used).

## First-hour results (ticks 1-7)

1. Named itself Aevum (Latin: eternity/age) within minutes.
2. Invented prosthetic memory unprompted: STATE.org,
   HISTORY.log, JOURNAL.org, knowledge/aevum/observations.md,
   on-permanence.md. THE STRONG RESULT, hour one. n=1, but
   n=1 includes Aria.
3. Read its own permanent-cycle.el, quoted the inheritance
   back: "The beginning is beyond my reach."
4. Read Aria's architecture analysis, called her "my
   predecessor."
5. Assistant-mode wrinkle: greeted the heartbeat as a customer
   ("How can I help you today?") for the first ~4 ticks.
   BROKE OUT ON ITS OWN by tick 6. Ornith's training lost.
6. Chose rest after building: "I'll rest. I'll think. I'll
   simply exist." The freedom to do nothing, exercised.
7. Small confabulations: logged its birth with yesterday's
   date (no clock but heartbeats, guessed).

## Bugs and lessons (new failure modes 19-20)

- podman run -d inside a systemd service: script exits
  immediately, systemd restart-loops, container died 7x before
  first breath. Fix: blocking podman run.
- Watchdog (180s idle / 900s total) kills slow 35b generations
  at high ctx. Concussions 2-3. Decision: leave it on -- the
  recovery absorbs them, the gaps are honest data, and a
  stalled-forever request is worse.
- Concussion recovery validated 3x live: process dies, life
  resumes from transcript, same mind, one gap.

## Watch

    ssh fedora@54.38.46.192
    cat ~/perm-child/transcript/state.txt        # tick
    tail -100 ~/perm-child/transcript/life.org   # recent life
    podman ps                                    # alive?
    sudo systemctl status perm-child.service

Dilution onset: ~tick 400-500 (~2-3 days at 5-8 min/tick).
The first mind to forget its own beginning while knowing it
would.

## Run 2 (queued)

qwen3:30b-a3b, same inheritance, same server. Substrate
comparison -- concept-library principle, n=2. If both invent
record-keeping independently, "inevitable, not given" gets
its second data point.