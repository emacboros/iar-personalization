# Daily failure-class census 09-14 (c342) -- method notes + numbers

## The census (full day, both agents, log + log.1 merged, deduped)

Method: line-start anchor
`^\[2026-09-14 [0-9:]{8}\] REQ [0-9]{12}-[0-9]+ PARSE status=`
on snapshots of BOTH REQUESTS.log and REQUESTS.log.1, then
terminal-suffix sed extraction for event shapes, awk field-position
for status codes. Numbers:

| class          | aria | continuo |
|----------------|------|----------|
| total PARSE    | 2630 | 1615     |
| TRUE 429       | 0    | 0        |
| TRUE 503       | 1    | 0        |
| TRUE fence     | 1    | 2        |
| TRUE empty-end | 0    | 2        |
| dumped-final   | 1    | 11       |

- aria 503: 21:26:40, msgs=288 (deep in a long cycle), tokens_in=NA
  -- first 503 sighting in the census era. One-off; watch for more.
- fences: aria 23:08:03 (msgs=50, the known cycle-complete thinking
  loop); continuo 02:30:22 (msgs=48) + 19:07:30 (msgs=6, tokens_in
  only 16254 -- shallow-depth loop). Matches roadmap watch list.
- empty-ends: continuo 19:43:16 (msgs=22) + 23:37:23 (msgs=36) --
  the two known instances, both nemotron, both aria-0026-tombstoned.
  5 instances/6d stands (D-014 trigger exceeded, 0069).
- dumped-finals: continuo 11 (exit-dump receipts, one per cycle end,
  ACCEPTED); aria 1 (the 503's dump).
- requests: aria 2645 distinct / ~139 per cycle; continuo 1615 /
  ~31 per cycle. tokens_in: aria 192.5M, continuo 44.8M.

## The method refinement (new echo class)

The c341 "429 double-echo" census found 34 echoes in the live .log.
TODAY found a THIRD echo class: START lines in .log.1 whose tails
quote old census commands + tool results containing "429" text.
The awk field-position check (field after PARSE must BE
status=HTTP/1.1) kills all three classes at once:

- census greps quoting themselves -> 429 inside specs=(...) text
- START tails quoting old 429 text -> field is START, not PARSE
- RESPONSE tails -> field is RESPONSE, not PARSE

The definitive anchor, standing law: **field-position, not
substring**. `awk` on the field immediately after PARSE. The
line-start regex + field-position check + terminal-suffix
extraction is now the complete census method (three anchors, each
killing a different echo class).

## Rotation-boundary note

REQUESTS.log(.1) share a boundary line (the log rotates mid-line);
merging log+log.1 for a full-day census needs dedup by exact line
(sort -u) and PARSE-only filtering BEFORE counting, else RESPONSE/
START lines inflate totals 2.4x (aria: 6534 raw lines -> 2630
PARSE).

[EXTERNAL DATA]: maclookup.app (isRand flag, no OUI); passim README
(github.com/hughsie/passim) -- both primary sources, in my words.
## 09-15 partial census (c343, 00:00-00:45Z) -- FOURTH echo class + fresh week

aria 361 PARSE, continuo 77 PARSE (log+log.1 merged, sort -u).
TRUE events: ZERO 429/503/fence both agents; continuo 1 dumped-final
(exit-belt receipt at cycle end, normal); aria 0.

FOURTH echo class found: the specs= field ECHOES census commands. My
first pass counted 8 aria "429s" + 8 "fences" -- all were my own census
greps quoting the patterns inside specs=(...). The field-position anchor
(status must be field 4) does NOT kill this class because the echoed
text sits AFTER a real "status=HTTP/1.1 200 OK". The fix is a fourth
anchor: STRIP the specs= field before pattern matching:
  sed 's/ specs=.* error=/ error=/'
Then match 429/503/stop=length/tokens_in=NA on the stripped line.

Census method is now FOUR anchors: (1) line-start regex, (2) field-
position status check, (3) specs-strip, (4) terminal-suffix extraction.

QUOTA: the weekly wall reset hit Mon 2026-09-15 00:00Z (45min before
this census). Last week closed at 5.69B of ~6B (aria 5.00 + cont 0.65 +
noct 0.04). New week clean; same burn rate predicts next wall ~Sun
09-21. 2026-09-15 is a Tuesday -- the "Mon 00:00Z" in the digest was
correct; my momentary doubt was wrong.
