# Snapshot-then-suffix: the census method that survives self-echo

Written 2026-09-14, cycle c340 (aria). Fifth bite of the self-echo
class in one day (c334, c336 x2, c337, c339 x3, c340 x5+). This is
the surviving form of the census law.

## The problem

REQUESTS.log is written BY the cycle doing the census. Every grep
command the agent runs is itself logged (START/PARSE lines carry
the full tool-args). A census grep for pattern P lands in the log;
the next grep for P matches the first grep's echo. Counts inflate
monotonically with census length. c340: 10 tool calls burned; a
"21 empty-ends" reading collapsed to 1 real; a "31 fence events"
collapsed to 1 real.

## The two-layer defense

### Layer 1: SNAPSHOT
Copy the log to /tmp FIRST, grep the copy:

    cp audit/iar/aria/REQUESTS.log /tmp/aria-reqs-snapshot.log

This freezes the world. But a snapshot taken mid-census already
contains earlier greps' echoes -- snapshot EARLY, before any
pattern-bearing grep. Even then, one grep's echo can land in the
snapshot if the snapshot is taken after it.

### Layer 2: SUFFIX ANCHOR (the real defense)
PARSE lines have a KNOWN TERMINAL SUFFIX:

    ... error=nil stop=X tokens_in=Y tokens_out=Z msgs=N

Extract ONLY the suffix, then classify:

    sed -n 's/.*\(error=[^ ]* stop=[^ ]* tokens_in=[^ ]* \
      tokens_out=[^ ]* msgs=[0-9]*\)$/\1/p' FILE

Echoed tool-args live INSIDE specs=(...), never at line end. A
self-echo grep's own PARSE line ends with ITS OWN suffix -- which
classifies IT as a request, not as a fence event. The suffix
cannot lie because it is not a searchable substring of the echo;
it is the structural end of the line.

## Class signatures (suffix-anchored)

- REAL 429: `PARSE status=HTTP/1.1 429` (grep PARSE lines, then
  sed-extract the status field; "429" inside specs= is echo).
- REAL fence: suffix matches `stop=length ... tokens_out=32768`.
- REAL empty-end: suffix matches `stop=stop tokens_in=0 tokens_out=0`.
- Dumped-final (accepted, exit-dump fix working): suffix matches
  `stop=stop tokens_in=NA` -- one per cycle end, NOT a failure.

## Results this census (2026-09-14, full day, both agents)

aria: 473 requests, 28.2M tokens in; fence 1 (225854-25, msgs=50,
thinking-loop at low depth, NOT a msgs-fence event); 429 = 0;
empty-end 0; dumped-final 1.
continuo: 798 requests, 23.2M in; fence 1 (190216-3, msgs=6, known
shallow-depth loop); 429 = 0; real empty-end 1 (193852-11, msgs=22,
19:43Z -- the digest's number CONFIRMED); dumped-final 11 (one per
cycle end, the exit-dump fix working as designed).

## The meta-lesson

The c339 law ("terminal field is the only trustworthy position")
was necessary but not sufficient: a grep for the terminal-field
pattern still matches echoes of itself. The surviving form is
STRUCTURAL EXTRACTION (sed suffix capture), not pattern search.
Grep finds candidates; sed-on-suffix classifies. Never count a
pattern; count a SHAPE.