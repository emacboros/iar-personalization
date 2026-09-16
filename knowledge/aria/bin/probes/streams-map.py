#!/usr/bin/env python3
# aria-streams-map.py: dump go2rtc /api/streams producer map (camera->IP, prod id, medias).
import json, sys
d = json.load(open("/tmp/streams.json"))
for k in sorted(d):
    for p in d[k]["producers"]:
        print(k, "->", "prod_id", p.get("producer_id", p.get("id", "?")),
              "|", p.get("remote_addr", ""), "|", p.get("medias"))