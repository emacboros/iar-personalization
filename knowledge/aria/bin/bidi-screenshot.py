#!/usr/bin/env python3
"""bidi-screenshot.py v1 (2026-09-11, aria cycle 180)
-------------------------------------------------------------
Canvas-capable screenshot via Firefox WebDriver BiDi (stdlib only:
socket + json, no pip deps). Closes the known eye-check limitation
(session X): firefox --headless --screenshot captures BEFORE the
first requestAnimationFrame paint, so the dashboard canvas (the main
visual) has NEVER been seen by the eye. BiDi captureScreenshot runs
after navigation + an explicit settle wait, so rAF-painted canvas
content IS captured.

PROVEN (c180, sophon, Firefox 154.0):
- rAF test page: plain --screenshot = 0 canvas px; BiDi = teal dot +
  white text pixels present. The canvas is captured.
- Live dashboard https://aria.randazzo.ar/: plain = 0 teal px; BiDi =
  257 teal px clustered in the graph region; eye read describes the
  node graph ("ARIA"/"CONTINUO" nodes) -- first canvas witness read.

MECHANISM: launch firefox --headless --remote-debugging-port N
(requires profile user.js prefs: devtools.debugger.remote-enabled,
devtools.debugger.force-local, remote.active-protocols=3,
remote.force-local -- without these the port never opens, c180
scar), ws /session handshake, session.new, browsingContext.navigate
(wait=complete), sleep WAIT_MS, browsingContext.captureScreenshot.

NOTE: Firefox 154 BiDi has NO /json/list HTTP endpoint (404) --
websocket-only. The ws client here is ~60 lines of RFC6455.

Usage: bidi-screenshot.py PORT URL OUT_PNG [WAIT_MS]
       (caller launches firefox; this script connects, navigates,
        captures, and exits -- firefox is left running for reuse)
Exit 0 on success (writes OUT_PNG), 1 on failure.
"""
import socket, base64, json, sys, time, struct, base64 as b64

def ws_connect(host, port, path="/session"):
    key = base64.b64encode(b"0123456789abcdef").decode()
    req = (f"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\nUpgrade: websocket\r\n"
           f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n")
    s = socket.create_connection((host, port), timeout=10)
    s.sendall(req.encode())
    hdr = b""
    while b"\r\n\r\n" not in hdr:
        hdr += s.recv(4096)
    if b"101" not in hdr.split(b"\r\n")[0]:
        raise RuntimeError(f"ws handshake refused: {hdr[:200]}")
    return s

def ws_send(s, data: bytes):
    mask = b"\x01\x02\x03\x04"
    hdr = b"\x81"
    n = len(data)
    if n < 126: hdr += bytes([0x80 | n])
    elif n < 65536: hdr += bytes([0x80 | 126]) + struct.pack(">H", n)
    else: hdr += bytes([0x80 | 127]) + struct.pack(">Q", n)
    masked = bytes(b ^ mask[i % 4] for i, b in enumerate(data))
    s.sendall(hdr + mask + masked)

def ws_recv(s):
    while True:
        b1 = s.recv(2)
        if len(b1) < 2: return None
        opcode = b1[0] & 0x0F
        ln = b1[1] & 0x7F
        if ln == 126: ln = struct.unpack(">H", s.recv(2))[0]
        elif ln == 127: ln = struct.unpack(">Q", s.recv(8))[0]
        mask = s.recv(4) if (b1[1] & 0x80) else None
        payload = b""
        while len(payload) < ln:
            chunk = s.recv(min(65536, ln - len(payload)))
            if not chunk: return None
            payload += chunk
        if mask: payload = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
        if opcode == 1: return payload.decode(errors="replace")
        if opcode == 8: return None

def main():
    if len(sys.argv) < 4:
        print("usage: bidi-screenshot.py PORT URL OUT_PNG [WAIT_MS]", file=sys.stderr)
        return 1
    port, url, out = int(sys.argv[1]), sys.argv[2], sys.argv[3]
    wait_ms = int(sys.argv[4]) if len(sys.argv) > 4 else 2000
    s = ws_connect("127.0.0.1", port)
    ws_send(s, json.dumps({"id": 1, "method": "session.new",
                           "params": {"capabilities": {"alwaysMatch": {"acceptInsecureCerts": True}}}}).encode())
    resp = json.loads(ws_recv(s))
    if resp.get("type") != "success":
        print(f"session.new failed: {json.dumps(resp)[:200]}", file=sys.stderr)
        return 1
    sess_id = resp["result"]["sessionId"]

    def cmd(i, method, params):
        ws_send(s, json.dumps({"id": i, "method": method, "params": params}).encode())
        while True:
            r = json.loads(ws_recv(s))
            if r.get("id") == i: return r

    r = cmd(2, "browsingContext.getTree", {"maxDepth": 1})
    tree = r["result"]["contexts"]
    if not tree:
        print("no browsing contexts", file=sys.stderr)
        return 1
    ctx = tree[0]["context"]
    r = cmd(3, "browsingContext.navigate", {"context": ctx, "url": url, "wait": "complete"})
    if r.get("type") == "error":
        print(f"navigate failed: {json.dumps(r)[:200]}", file=sys.stderr)
        return 1
    time.sleep(wait_ms / 1000.0)
    r = cmd(4, "browsingContext.captureScreenshot", {"context": ctx})
    if r.get("type") == "error":
        print(f"captureScreenshot failed: {json.dumps(r)[:200]}", file=sys.stderr)
        return 1
    open(out, "wb").write(b64.b64decode(r["result"]["data"]))
    print(f"bidi-screenshot: saved {out}")
    return 0

if __name__ == "__main__":
    sys.exit(main())