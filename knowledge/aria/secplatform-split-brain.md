# SecPlatform Split-Brain -- Cycle 45 Revision

## CORRECTION to cycle 44's model

Cycle 44 concluded: "prod traffic hits a full stack copy on rammstein
(own bff+nginx+KC, CF-fronted, origin :8443)". The origin-half of that
conclusion was WRONG. The traffic-half was right.

## What cycle 45 verified (2026-08-31 ~16:00 UTC)

1. **rammstein:8443 is DEAD.** Connection refused from sophon and from
   rammstein itself. No listener on 8443 (or 8080/8091/8092/5432) on
   rammstein. No root or user podman containers. No docker. No
   cloudflared. No NAT rules. Caddy on rammstein still proxies
   app/app-bo/auth.i.ar -> 10.66.0.5 (the ORIGINAL config, mtime Aug 26).
   The cycle-44 ":8443" reading was a misread of my own probe output
   (likely a malformed --resolve or a transient); nothing on rammstein
   serves the app. Rammstein is clean.

2. **The public path IS sophon.** DNS -> Cloudflare -> sophon
   (10.66.0.5) directly:
   - app.i.ar /api/health from sophon: 200 in 0.13s.
   - sophon bff-client logs EVERY public probe I make (req ids move,
     /api/me 401s appear in nginx + bff logs).
   - sophon KC logged my deliberate bad-credential POST (event 172,
     LOGIN_ERROR, ip 10.66.0.5) -- events persist fine; there were
     simply no events because there were no logins since Aug 21.
   - Same SPA title ("SecPlatform · Ingresando…"), same 401 shape
     ({"error":"missing_token"}), same OIDC client_id/redirect_uri on
     both paths. One stack.

3. **Cloudflare fronts all three domains** (A records -> CF IPs; TLS
   cert issued by Google Trust Services via CF; server: cloudflare).
   Caddy on rammstein is NOT in the app path (its Caddyfile still says
   reverse_proxy 10.66.0.5, but CF connects to sophon directly --
   sophon:443 is closed, so CF must use the origin ports 8080/8091/8092
   over WireGuard... exact CF->origin transport still unconfirmed, but
   the destination is sophon).

## The real finding (unchanged, now sharper)

**SecPlatform prod has had ZERO real traffic since Aug 21 02:50 UTC.**
- sophon KC: 171 events, last Aug 21 (my test event is #172).
- sophon audit_log: 127 rows, ends Aug 21.
- bff-client: only 10s health checks since Aug 21.
- The service is UP, healthy, answering probes -- and nobody has
  logged in for 10 days. "Alive" and "used" are different things
  (cycle 44's method lesson, now with the correct topology).

**Cloudflare was added ~Aug 18** (CF edge IPs in KC LOGIN events from
Aug 18 onward: 2a09:bac1:... = CF). Before that, direct residential
IPs (181.28.x.x -- Nacho's ISP, Telecom Argentina).

## Why this matters

- If SecPlatform is a PoC with no users right now, zero traffic is
  EXPECTED and this whole thread is a nothing-burger: the split-brain
  was my misread, and the idle stack is just an idle PoC.
- The remaining real question for Nacho: is the CF-fronted topology
  (DNS on CF, Caddy on rammstein bypassed for app.i.ar) intentional?
  The Ansible-managed Caddyfile on rammstein still claims those sites,
  and my iar-prod/infra knowledge ("no Cloudflare, Caddy->WG->sophon")
  is now known-stale either way.
- sophon data state: 12 KC users, 2 tenants (acme, globex), 127 audit
  rows. All on sophon, all backed by... the usual sophon backup story
  (repos + .config only -- frigate gap lesson applies to tenant DBs
  too, though PoC data may not warrant it).

## FOR-NACHO delta (cycle 45)

Cycle 44's questions are mostly answered:
1. "What DB does the rammstein stack use?" -> MOOT: there is no
   rammstein stack. All data is on sophon.
2. "Is rammstein hand-rolled?" -> rammstein serves nothing for
   SecPlatform; its Caddyfile still points at sophon (stale config,
   harmless).
3. "Which stack is authoritative?" -> sophon. There is only one.
4. New question: is Cloudflare-in-front intentional? (DNS moved to CF
   ~Aug 18; Caddy on rammstein bypassed for the app domains.)

## Lessons

- Cycle 44's own lesson ("suspect a second stack") was half-right:
  the evidence WAS impossible, but the answer was "no traffic since
  Aug 21", not "a second stack". I invented a whole deployment to
  explain a quiet log. Failure mode 13's cousin: when the map says
  traffic should exist and the log says it doesn't, first consider
  that the traffic simply stopped.
- Verify your own probe output before building a theory on it: the
  ":8443" datum survived one full cycle as the load-bearing wall of a
  wrong model. One re-probe (connection refused) would have killed it.
- KC events_enabled=t + zero events = no logins, not broken logging.
  Prove the pipeline works (bad-cred probe -> event 172) before
  reading silence as failure.