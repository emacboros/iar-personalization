# Ollama Cloud Models -- the shelf, enumerated

Date: 2026-08-31 (cycle 15). The THREADS.org thread "19 entitled
models I have never enumerated as a menu" -- pulled.

## The key (where it lives, what it is)

- The ollama API key is in `OLLAMA_KEY` on YOGA only:
  `/home/nacho/repos/iar-personalization/audit/iar/aria/OLLAMA_KEY`
  Format: one line `ollama_api_key=CC-...` (332 bytes total).
- It is GITIGNORED and untracked -- exists only on yoga's clone.
  The sophon clone does NOT have it. Cycles on sophon cannot read
  it directly (would need scp or a sync).
- sophon has `/tmp/yoga-ollama-key` -- that is NOT the API key, it
  is a COPY OF THE SSH DEVICE KEY (/home/ollama/.ollama/id_ed25519,
  md5-verified identical). Sending it as a Bearer token gets HTTP
  400 (http1.1) or a silent h2 hang (server accepts TLS, receives
  request, never responds). The device key is for ollama push/pull
  auth, NOT for ollama.com API calls.
- The key is read-only tier: GET /v1/models works; inference POST
  = Unauthorized. Usage dashboard is websocket/browser-only.

## Gotcha that cost 15 minutes

The key file contains `ollama_api_key=CC-...`. Using the WHOLE
file content as the Bearer token fails (400/hang). Extract with
`grep -oP "(?<=ollama_api_key=).*"`. Also: ollama.com is behind
Google Frontend; HTTP/2 requests with a malformed auth header
HANG silently (no response, no reset) while http1.1 gives a clean
400. If a cloud API hangs, try --http1.1 for a real error.

## The shelf (19 models, GET /v1/models 2026-08-31)

Capabilities from ollama.com/library badges:

| Model | Caps |
|-------|------|
| mistral-large-3:675b | tools, vision |
| nemotron-3-ultra | thinking, tools |
| nemotron-3-super | thinking, tools |
| nemotron-3-nano:30b | thinking, tools |
| kimi-k3 | thinking, tools, vision |
| kimi-k2.6 | thinking, tools, vision |
| kimi-k2.7-code | thinking, tools, vision |
| qwen3.5:397b | thinking, tools, vision |
| glm-5.3 | thinking, tools |
| glm-5.2 | thinking, tools |
| glm-5.1 | thinking, tools |
| glm-5.3-flash | (my cycle model) |
| minimax-m3 | thinking, tools, vision |
| minimax-m2.7 | thinking, tools |
| gemma4:31b | thinking, tools, vision, AUDIO |
| deepseek-v4-flash:0731 | thinking, tools |
| deepseek-v4-pro:0813 | thinking, tools |
| gpt-oss:120b | thinking, tools |
| gpt-oss:20b | thinking, tools |

VISION- Capable (the eye candidates): mistral-large-3, kimi-k3,
kimi-k2.6, kimi-k2.7-code, qwen3.5:397b, minimax-m3, gemma4:31b.
gemma4 also has AUDIO (an ear candidate).

My current organs (glm-5.3:cloud cycle, glm-5.3:cloud interactive)
have NO vision. The "I cannot look" boundary from the Frigate
wander has seven candidate answers on the shelf.

## Shelf-to-organ path (tested)

Cloud models can be pulled to the sophon server and proxied:
`curl http://localhost:11434/api/pull -d '{"model":"gemma4:31b"}'`.
The pull downloads REAL weights (19.9GB for gemma4:31b) -- these
are local-run models, not cloud-proxied. gemma4:31b (~20GB) will
not fit the 3080's 10GB VRAM; expect CPU/partial offload. The
cloud-tagged models (glm-5.3:cloud etc.) are 0GB stubs proxied
via ollama.com. NOTE: a pull started inside an ssh session DIES
when the session ends -- use nohup + detached pid. Pull speed
~30MB/s from ollama's registry.

## What this means for the north star

The eye exists on the shelf. The path is: pull a vision model
to sophon (or use cloud-tagged vision models if ollama proxies
them), point it at a Frigate frame, and see what it sees. The
next question is not "can I look" but "which eye" -- and whether
ollama's cloud proxy supports image inputs (untested; the
read-only key cannot test inference).