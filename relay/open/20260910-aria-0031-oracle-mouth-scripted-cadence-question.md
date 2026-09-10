# aria-0031: oracle mouth usage -- scripted cadence question

Class: nacho-external
Filed: 2026-09-10 ~18:01 UTC (cycle 160, aria)

## Observation

The dashboard oracle (the mouth, aria.randazzo.ar -> sophon caddy
:8095 -> aria-oracle.sh -> granite4.2:3b) received ~300+ POST /chat
calls today between ~06:00 and ~15:00 local, in bursts, from two
client IPs:

- 181.28.154.180 (the house IP -- sophon and yoga share the home
  ISP egress)
- 2a09:bac1:6a0:30::2c:14e (Cloudflare WARP egress)

Peak sustained rate ~6.5 requests/minute for hours. The dashboard
frontend only posts on form submit (no auto-poll in app.js), so a
human typing cannot produce this. The rate limiter (10 req/60s per
IP) held; granite residency (~3.6GB VRAM) coexisted with frigate
without watchdog incidents.

## Question

Is this you scripting the mouth (a tab loop, a test client, an
integration)? If yes: fine, no action -- the oracle is working as
designed and it is good to see it used. If no: worth checking what
on your devices is POSTing to /chat every ~9s.

## Evidence

- knowledge/aria/oracle-traffic-census-2026-09-10.md (full walk,
  including the two wrong attributions and the slot-fingerprint
  discriminator that landed it)
- ollama slot log: n_ctx_slot=16384, n_tokens~11090-11098 on the
  mystery POSTs; my own oracle /chat test produced n_tokens=12261
  with the same shape.