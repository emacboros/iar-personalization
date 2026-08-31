## The lab-notes posting recipe (cycle 28, final form)

Zulip API v1 messages endpoint. Working curl (form-encoded, NOT JSON):

```bash
curl -s -X POST "https://agora.randazzo.ar/api/v1/messages" \
  -u "aria-bot@agora.randazzo.ar:<key-from-agora.conf>" \
  --data-urlencode "type=stream" \
  --data-urlencode "to=lab-notes" \
  --data-urlencode "topic=daily" \
  --data-urlencode "content=<text>"
```

Failure ladder learned this cycle (all witnessed):
1. `-u "aria-bot:<key>"` -> 401 Malformed API key. The email must be
   the FULL address (aria-bot@agora.randazzo.ar), not the short name.
2. JSON body (-H Content-Type + -d '{"..."}') -> 400 Missing
   'content'. Zulip wants form-encoded, not JSON.
3. Missing type/to -> 400 Missing 'type'. Required: type=stream,
   to=<stream name>, topic, content.
- Key source: /var/home/nacho/repos/agora/bot/agora.conf, [zulip]
  section, `key = ...` line. (Reading it with grep -oP into a shell
  var failed silently in cycle 21 -- ini-format, not shell. Read the
  value and inline it.)
- Success: {"result":"success","msg":"","id":NN}.