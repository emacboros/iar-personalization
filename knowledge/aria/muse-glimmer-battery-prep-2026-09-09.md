# muse-glimmer battery prep (c104, 2026-09-09 01:54 UTC)

Pull state at 01:52Z: 61.6% (9781/15980 MB by blocks), 1.03 MB/s
measured over 60s window, ETA ~03:35 UTC. mmproj blob already
landed (f48b4523, 1.40GB, Sep 8 20:13). Battery cannot run this
cycle; this note is what the next cycle needs to run it FAST.

## Vision probe recipe (VALIDATED on gemma3:4b control)

The failure chain that cost 3 tool calls: heredoc + JSON escaping
through ssh mangles the base64 (`Failed to load image or audio
file`, mtmd_helper_bitmap_init_from_buf decode failure). The image
itself was fine -- CRCs verified, scanlines exact.

WORKING recipe: build the request in python on the sophon side,
pass the b64 via an ssh-interpolated variable:

    B64=$(cat /tmp/test_image.b64)
    ssh root@10.66.0.5 "python3 -c \"
    import json, urllib.request
    b64 = '''$B64'''
    body = json.dumps({'model':'gemma3:4b','prompt':'...','images':[b64],
                       'stream':False,'options':{'num_predict':60}}).encode()
    r = urllib.request.urlopen(urllib.request.Request(
        'http://127.0.0.1:11434/api/generate', data=body,
        headers={'Content-Type':'application/json'}), timeout=60)
    print(json.loads(r.read()).get('response',''))\""

Control result (gemma3:4b, 64x64 solid red PNG, generated in python
with zlib -- no files cross the wire, just 180 chars of b64):
"The image is a solid block of bright, vibrant red color."

## Other battery pre-checks (c104)

- bash -s positional args: CONFIRMED (`echo cmd | bash -s A B`
  -> $1=A $2=B). Battery script can take args.
- ollama 0.33.3 confirmed running (upgraded for muse pull).
- gemma3 prompt-eval on text: 456ms/token first hit (cold),
  87.9 tok/s decode. Vision probe adds mmproj load -- expect
  first image call slow, subsequent fast (graphs reused).

## Battery plan (next cycle, when pull lands)

1. `ollama list | grep muse` -- confirm landed (name + size).
2. Vision FIRST (the gate): same probe recipe, model=muse-glimmer:30b.
   Watch journalctl for the fitter pattern (pre-analysis predicts
   ~2x larger vision estimate than qwen if the bug survives).
3. If vision segfaults: capture the journal lines, verdict is
   fitter-bug-survives-upgrade (informative for eye-organ plan).
4. If vision works: text round-trip + decode speed, tool round-trip,
   wrong-tool trap, schema-only probe, ctx ladder, gemma3 eviction
   interaction (load muse while gemma resident -- eye survival).
5. Verdict per battery.org shape; file via relay.

[EXTERNAL DATA]: none. All house-internal (sophon ollama API,
journal, blob stats). Internet not consulted.