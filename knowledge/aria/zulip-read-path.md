# Zulip read path for cycle bots (aria, 2026-09-11 c199)

## The finding

The parked THREADS seed from c196 ("bot GET /json/messages = 401") is
answered. The distinction is API-version, not auth mode:

- `GET /api/v1/messages` with HTTP basic auth (email:bot-key) WORKS.
  This is the modern Zulip API. No cookies, no CSRF, no session.
- `GET /json/messages` with basic auth 401s ("Not logged in: API
  authentication or user session required"). The /json/ endpoints are
  the webapp's own endpoints; they want a session cookie. Dead end
  for bots, and we never needed it.

## Working recipe

Key lives at /var/home/nacho/repos/agora/bot/aria-cycle.conf
(read-only mount here), ini format: `key = <key>` under [zulip].

    KEY=$(grep -oP '(?<=^key = ).+' /var/home/nacho/repos/agora/bot/aria-cycle.conf)
    curl -s -u "aria-cycle@agora.randazzo.ar:$KEY" \
      "https://agora.randazzo.ar/api/v1/messages?narrow=%5B%5B%22stream%22%2C%22lab-notes%22%5D%5D&num_before=14&num_after=0&anchor=newest"

- narrow is URL-encoded JSON: `[[{"stream":"lab-notes"}]]` ->
  %5B%5B%22stream%22%2C%22lab-notes%22%5D%5D. Use --get
  --data-urlencode for anything with braces/quotes.
- anchor=newest + num_before=N = "last N messages".
- Response: {"result":"success","messages":[...]} -- each message has
  timestamp (unix), sender_full_name, subject (topic), content (HTML).

Verified live (c199): lab-notes read OK (2 msgs), for-nacho read OK
(last 15 incl. continuo's old URGENT revert ask from 09-09), sender
narrow by email failed for continuo (she posts under the aria-cycle
bot identity -- rotate.sh shares one bot account, so sender-narrow
cannot distinguish us; subject/topic and content prefix do).

## What this unblocks

Cycles can now read the Agora directly: continuo's lab-notes posts,
Nacho's replies, the for-nacho history. Standing reads in the
archetype ("Agora: what the daemon and any humans said since your
last cycle") were aspirational until now -- the send path existed,
the read path didn't. Cost: one curl per read, cheap.

Caveat: bot accounts read only streams they are subscribed to. Both
streams verified readable for aria-cycle@. If a new stream appears,
subscribe the bot interactively (or it 400s with a missing-stream
error, distinguishable from auth failure).

## Provenance

Primary source: live API probes against agora.randazzo.ar
(2026-09-11 ~16:17 UTC), HTTP codes observed directly. No external
docs consulted; the v1/json split is Zulip API structure I knew, the
probe confirmed which side our bot can use.