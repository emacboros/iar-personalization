# Compression Signature -- detecting repetitive streaming output without tapping the stream

Discovered 2026-09-02 00:44-00:49 UTC during Aevum tick-37 runaway
forensics (cycle 117). Works on any HTTPS/streaming client using
--compressed (curl) or Accept-Encoding, where the server compresses
and the client decompresses.

## The signature

Sample the client process's /proc/<pid>/io twice, ~10-15s apart,
while the server-side generation counter (or any independent
progress signal) keeps climbing:

- `rchar` FROZEN + `wchar` GROWING + both TCP socket queues empty
  = the client is decompressing from an internal zlib window, not
  reading the wire. The stream content is so repetitive that gzip
  collapses new output to near-zero bytes on the wire.

- `rchar` growing at a steady rate proportional to the server's
  token rate = normal, varied output.

- `rchar` frozen AND `wchar` frozen = client blocked (pipe full,
  consumer stuck) -- a different failure, check the read side.

## Why it works

zlib's deflate window is 32KB. For highly repetitive text, new
tokens produce almost no new compressed bytes because the back
references cover them. The client's decompressor keeps expanding
from its window (wchar grows) while consuming almost nothing new
from the socket (rchar frozen). The ratio wchar-delta /
rchar-delta is a rough repetitiveness meter: >>10x = loop.

## How to apply

1. Find the client pid (container namespace pids map to host via
   elapsed-time matching or ss -tnp on the server side).
2. `cat /proc/<pid>/io | head -2` -- rchar = bytes read from socket,
   wchar = bytes written to stdout/pipe.
3. Sample 2-3x, 10s apart. Compare with the server's generation
   counter (e.g. ollama journalctl print_timing n_gen).
4. Interpret per the signature table above.

## Requirements and limits

- Requires compression on the wire (curl --compressed was on in the
  i.ar stack by default via gptel). Without compression, rchar and
  wchar grow together and the signature vanishes -- but then you can
  read the stream directly from rchar growth patterns.
- TCP socket queues via `ss -tnm` or /proc/net/tcp confirm the
  socket is drained (rx_queue 0) -- rules out backpressure.
- The watchdog angle: a streaming generation never trips a no-data
  watchdog. A repetition loop is "healthy" traffic to any idle-based
  instrument. Only a token ceiling (num_predict) or a repetition
  penalty stops it.

## Provenance

Observed live on the Aevum experiment server (54.38.46.192),
2026-09-02 ~00:44 UTC. The runaway: ornith:35b, tick 37, 7300+
tokens at 1.35 t/s with no stop in sight. No strace, no tcpdump
(neither installed) -- the io counters alone carried the diagnosis.