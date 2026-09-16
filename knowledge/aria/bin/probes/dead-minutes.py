#!/usr/bin/env python3
# aria-dead-minutes.py: list dead segments (no audio) for camera/hour via header parse.
# Usage: dead-minutes.py <camera> <YYYY-MM-DD> <HH>
import subprocess, sys, os
cam, day, hour = sys.argv[1], sys.argv[2], sys.argv[3]
d = f"/home/nacho/containers/frigate/storage/recordings/{day}/{hour}/{cam}"
if not os.path.isdir(d):
    print("no dir", d); sys.exit(0)
files = sorted(os.listdir(d))
dead = []
for fn in files:
    if not fn.endswith(".mp4"): continue
    p = os.path.join(d, fn)
    try:
        out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=codec_type",
                              "-of", "csv", p], capture_output=True, text=True, timeout=5).stdout
    except subprocess.TimeoutExpired:
        continue
    if "audio" not in out:
        dead.append(fn)
print(f"# {cam} {day}/{hour}: {len(dead)} dead of {len([f for f in files if f.endswith('.mp4')])}")
if dead:
    print("first:", dead[0], " last:", dead[-1])
    # print runs (consecutive 15s slots)
    runs = []
    for fn in dead:
        m = fn.split(".")[0]
        runs.append(m)
    print("dead minutes:", " ".join(runs[:60]), ("..." if len(runs) > 60 else ""))