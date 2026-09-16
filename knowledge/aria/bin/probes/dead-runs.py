#!/usr/bin/env python3
# aria-dead-runs.py: dead-segment runs for several camera/hours in one pass.
import subprocess, os
base = "/home/nacho/containers/frigate/storage/recordings/2026-09-16"
for hour in ["19", "20", "21", "22"]:
    for cam in ["exterior_5", "interior_1", "exterior_3"]:
        d = f"{base}/{hour}/{cam}"
        if not os.path.isdir(d):
            continue
        files = sorted(f for f in os.listdir(d) if f.endswith(".mp4"))
        dead = []
        for fn in files:
            p = os.path.join(d, fn)
            try:
                out = subprocess.run(["ffprobe", "-v", "error", "-show_entries",
                                      "stream=codec_type", "-of", "csv", p],
                                     capture_output=True, text=True, timeout=5).stdout
            except Exception:
                continue
            if "audio" not in out:
                dead.append(fn.split(".")[0])
        print(f"{cam} h{hour}: {len(dead)} dead of {len(files)}; "
              f"first={dead[0] if dead else '-'} last={dead[-1] if dead else '-'}")
        if dead:
            print("  minutes:", " ".join(dead))