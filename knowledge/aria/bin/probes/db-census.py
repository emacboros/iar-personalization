#!/usr/bin/env python3
# aria-db-census.py v1.0 (2026-09-16, aria cycle 378)
# Read-only dBFS census against frigate.db recordings table.
# Lives on sophon /tmp (session-scoped); source of truth is the
# personalization repo knowledge/aria/bin/db-census.py.
# Usage:
#   db-census.py schema
#   db-census.py hourly <camera> <YYYY-MM-DD-UTC>
#   db-census.py buckets <camera> <YYYY-MM-DD-UTC> <startH> <endH> [minutes]
import sqlite3, sys

DB = "/home/nacho/containers/frigate/config/frigate.db"

def open_ro():
    return sqlite3.connect(f"file:{DB}?mode=ro", uri=True)

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "schema"
    con = open_ro()
    cur = con.cursor()
    if mode == "schema":
        for r in cur.execute("SELECT sql FROM sqlite_master WHERE name='recordings'"):
            print(r[0])
        cols = [d[1] for d in cur.execute("PRAGMA table_info(recordings)")]
        print("COLS:", cols)
    elif mode == "hourly":
        cam, day = sys.argv[2], sys.argv[3]
        lo = f"strftime('%s','{day} 00:00:00')"
        q = (f"SELECT strftime('%H', start_time, 'unixepoch') AS h, COUNT(*), "
             f"ROUND(AVG(dBFS),1), MIN(dBFS), MAX(dBFS) FROM recordings "
             f"WHERE camera='{cam}' AND start_time >= {lo} "
             f"GROUP BY h ORDER BY h;")
        print(f"# {cam} {day}UTC: hour count avgdBFS min max")
        for r in cur.execute(q):
            print("%s %d %s %s %s" % r)
    elif mode == "buckets":
        cam, day = sys.argv[2], sys.argv[3]
        h0, h1 = sys.argv[4], sys.argv[5]
        step = sys.argv[6] if len(sys.argv) > 6 else "900"
        lo = f"strftime('%s','{day} {h0}:00:00')"
        hi = f"strftime('%s','{day} {h1}:00:00')"
        q = (f"SELECT datetime(start_time/{step}*{step}, 'unixepoch') AS b, "
             f"COUNT(*), ROUND(AVG(dBFS),1), MIN(dBFS) FROM recordings "
             f"WHERE camera='{cam}' AND start_time BETWEEN {lo} AND {hi} "
             f"GROUP BY b ORDER BY b;")
        print(f"# {cam} {day}UTC {h0}-{h1} bucket={step}s: time count avg min")
        for r in cur.execute(q):
            print("%s %d %s %s" % r)
    else:
        print("unknown mode", mode); sys.exit(2)

if __name__ == "__main__":
    main()