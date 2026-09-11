# Oracle Traffic Census -- 2026-09-10 (cycle 160)

## The question

The pulse showed granite4.2:3b resident on sophon with ~300+/hour
POST /api/chat calls to ollama since ~06:00 local. Nobody in the
affect-organ inventory (rage/fear hourly, fleet 6h, eye daily) calls
granite at that rate. Who is calling?

## The walk (and its two wrong turns)

1. First attribution attempt: the persistent ollama connection
   (10.66.0.5:46444) belongs to pid 9911 = agora-agent (LangChain
   daemon, conf model=gpt-oss:120b). I spent ~30 calls trying to make
   the agent the caller. WRONG: the agent's conn is a PERSISTENT httpx
   keep-alive pool -- it exists whether or not the agent is calling.
   A persistent conn in an ss loop is not evidence of traffic.
2. Second attribution attempt: tcpdump on lo/wg0 for the POST bodies
   kept coming up empty (snap/filter mistakes), burning calls.
3. The discriminator that actually worked: the ollama slot log.
   - The mystery POSTs carried n_ctx_slot=16384, n_tokens~11090.
   - 16384 = granite4.2:3b's context (per /api/ps).
   - I sent one oracle /chat myself: n_tokens=12261 (context.txt
     30920 chars + question). Same shape, same slot.
   - Only aria-oracle.sh references granite4.2 anywhere in the repo.

## The finding

The granite POSTs are oracle /chat calls. The oracle logs nothing by
design (Nacho's call), so its traffic is invisible in journald -- the
only witness is ollama's slot log. Caller IPs (X-Forwarded-For via
sophon caddy :8095 <- rammstein caddy <- Cloudflare):
- 181.28.154.180 = the house IP (sophon AND yoga share the home ISP
  egress; confirmed via ifconfig.me from both nodes)
- 2a09:bac1:6a0:30::2c:14e = Cloudflare WARP egress

Both are Nacho-side. The mouth is being used, from at least two
devices, in bursts. Peak rate ~6.5/min sustained for hours is more
than a human typing -- likely a script or a tab loop on his side.
Rate limiter (10 req/60s/IP) holds; no infrastructure impact beyond
granite residency (~3.6GB VRAM, coexists with frigate fine).

## Laws exercised

- Law 6 (verify against primary evidence before attributing): the
  persistent-conn attribution was exactly the pattern-matching trap.
  A conn is not traffic.
- Law 34 (attribution needs the actor's log): the oracle logs nothing,
  so the actor's log does not exist -- attribution had to come from
  the slot-level shape (n_ctx/n_tokens fingerprint), which is a new
  instrument trick: model+context fingerprinting from the server side.
- Law 9 again: ~60 calls on the walk before the one-command
  discriminator (send a known /chat, read the slot line) landed it.

## Open

- The ~9s cadence for hours is unexplained-human. Ask Nacho (relay
  filing): is he scripting the mouth? If yes, fine; if no, worth a
  look at what his devices are doing.
- The oracle is stateless and rate-limited; no action needed from us.
## UPDATE (2026-09-11, aria c196 -- relay 0031 answered, session XV)

The /chat burst traffic is ATTRIBUTED: Nacho's friend (the
SecPlatform-side collaborator, shown the dashboard) was probing the
oracle mouth for PII-leak paths. Working as designed; no action.
Note for future cycles: an external human red-teaming the mouth is a
known traffic class now -- do not re-investigate it as an anomaly.
