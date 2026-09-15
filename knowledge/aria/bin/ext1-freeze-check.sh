#!/bin/bash
# ext1 producer audio-freeze direct check (aria cycle, read-only)
# runs ON SOPHON. Uses machinectl to reach nacho's frigate container.
machinectl shell nacho@ /bin/sh -c "podman exec frigate sh -c 'wget -qO- http://127.0.0.1:1984/api/streams'" > /tmp/go2rtc-ext1.json 2>/dev/null
python3 - <<'EOF'
import json
d = json.load(open('/tmp/go2rtc-ext1.json'))
p = d['exterior_1']['producers'][0]
print('producer id:', p['id'], 'remote:', p.get('remote_addr'))
for c in p.get('consumers', []):
    print('consumer:', c.get('type'), 'stats:', c.get('stats'))
EOF