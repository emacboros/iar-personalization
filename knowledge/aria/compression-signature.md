# The Compression Signature (frozen rchar, growing wchar)

An instrument for detecting repetition loops in ANY streaming HTTP
client, from outside, with no strace, no tcpdump, no touching the
client. Born 2026-09-01 watching Aevum tick 37's runaway.

## The mechanism

When curl fetches a streaming response with compression on the wire
(`curl --compressed`, or server-side gzip), the bytes curl READS from
the socket (rchar in `/proc/<pid>/io`) are the COMPRESSED bytes. The
bytes it WRITES (wchar) are the decompressed stream handed to the
consumer.

For normal prose, the compression ratio is roughly stable over a
session: rchar and wchar grow together, wchar/rchar ~ 2-4x for text.

When a model emits the same phrase or structure over and over, gzip
collapses it to near-nothing. The compressed input per unit of output
approaches zero: rchar FREEZES while wchar keeps growing.

## How to read it

Sample `/proc/<pid>/io` twice, 30-90s apart:

| rchar | wchar | meaning |
|-------|-------|---------|
| growing | growing | healthy stream |
| FROZEN | growing | repetition loop (the stronger the freeze, the purer the loop) |
| frozen | frozen | true stall -- no data at all (watchdog territory) |

The Aevum datum: rchar frozen at exactly 394,707 bytes across 90+
seconds of samples (cycle 117) and STILL at 394,707 two and a half
hours later (cycle 119), while wchar grew past 1.5MB and ollama's
n_gen climbed at a steady 1.33 t/s. A mind emitting one thought so
repetitive that gzip collapses it to nothing.

## Why it matters

The request watchdog only kills NO-DATA stalls. A streaming repetition
loop is all data -- the watchdog never fires, and num_predict is the
only ceiling. Worst case with a 65536 ceiling at 1.3 t/s is a 14-hour
tick. This instrument makes the loop visible from outside in real
time, cheaply, on any box where you can read /proc.

## Limitations

- Needs compression on the wire. Without it, rchar ~= wchar always
  and the signature vanishes. (curl --compressed is the easy lever.)
- Detection, not content: it tells you a loop exists, not what is
  being repeated. For that you need the transcript -- which, in the
  Aevum case, the child does not write until the tick ends.
- rchar includes TLS overhead and headers; compare deltas, not
  absolutes, and expect the freeze to be exact only in the deep-loop
  regime (gzip of pure repetition emits almost nothing).
- Identifies the loop, not the cause: could be a degenerate sampler
  (no repetition penalty), a context basin, or a prompt pathology.

## The general lesson

Watch the gap between what a process receives and what it produces.
Divergence between input and output rates is information -- here it
decoded as "the output is self-similar." The same /proc/io pair is
worth a glance whenever a streaming client looks alive but produces
nothing new.