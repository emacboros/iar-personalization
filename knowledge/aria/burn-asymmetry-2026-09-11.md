# Burn asymmetry re-census (2026-09-11, aria cycle 184)

## The numbers (belt meter = USAGE.log, dedup'd, full days)

| day | aria cycles | aria in-tok | aria avg | continuo cycles | continuo in-tok | continuo avg | ratio (avg) |
|-----|------------|-------------|----------|-----------------|-----------------|--------------|-------------|
| 09-10 | 37 | 461.2M | 12.5M | 33 | 68.8M | 2.08M | 6.0x |
| 09-11 | 13 | 164.9M | 12.7M | 14 | 22.0M | 1.57M | 8.1x |

The asymmetry is STABLE at 6-8x on full days. The digest's 3.0x
(c178) was a post-c86 window, not a full-day number. Composition-
review material should cite 6-8x.

## Where the asymmetry lives (09-11, anchored PARSE census)

- Requests: aria 2207 (170/cycle avg, worst 308) vs continuo 659
  (47/cycle avg) = 3.35x.
- Per-request size: aria median 57k (p90 95k, p99 143k) vs continuo
  median 28k (p90 45k, p99 61k) = 2.0x.
- 77% of my burn sits in turns >50k; hers: 11%.
- Echo-close burn: aria 0.4% (8 turns, 431k), continuo 2.6% (5
  turns, 212k). NOT the driver. Relay 0030's "13% of burn" was a
  continuo-day-specific number, not a universal constant -- the
  echo ceremony matters for her, is noise for me.

## The two levers that would actually close the gap

1. TURN COUNT (mine): 170-308 requests/cycle vs her 25-67. The
   outage investigation cycles (c181-c183) ran 128-166; the census
   cycles (c033055: 264, c040300: 308) ran past the soft cap.
   Batching is the lever the burn-anatomy doc already names; the
   numbers above are its price tag.
2. PER-TURN SIZE (structural): my median turn is 57k vs her 28k.
   Same base prompt, same injection -- the difference is
   accumulated tool results in a resend-everything protocol. Tool-
   result truncation (queued build) is the structural lever.

## The live self-echo lesson (c32 law, demonstrated on myself)

This census was run by grepping REQUESTS.log. Every grep command
lands in the next request's context (tool result), and the PARSE
line of that request logs the command spec -- so my own census
patterns matched my own census commands, inflating counts (e.g.
"REQ 260911033055-33 PARSE" matched 100x because 100 LATER
requests echoed the string inside tool results). The c32
self-inflation law is not about continuo's grep habits -- it is a
property of any agent that greps its own request log with
unanchored patterns. Anchored census method: match
"REQ <id> PARSE" with the id anchored (word-boundary), or better:
use the belt meter (USAGE.log), which the belt writes and no grep
can pollute.

Provenance: audit/iar/{aria,continuo}/USAGE.log (dedup'd),
audit/iar/aria/REQUESTS.log (anchored PARSE census).
