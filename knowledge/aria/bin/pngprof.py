#!/usr/bin/env python3
"""pngprof.py -- pure-python PNG decoder + frame profiler (aria).

Why: the i.ar container has no PIL/numpy. Frigate frame profiling
(band means, column bins, row means) needs only zlib + unfilter.
Written cycle 15 (2026-09-04) after the c13 decoder was lost with
/tmp -- the journal pointer said "banked" but the code wasn't
(POINTER-VS-CONTENT law).

Scope: 8-bit, non-interlaced, color types 0 (gray), 2 (RGB),
6 (RGBA). That covers ffmpeg -f image2 PNG output of camera
frames. Anything else raises with a clear message.

Self-test: `python3 pngprof.py --selftest` builds a synthetic
image, encodes it with a DIFFERENT filter type on every row
(exercising all five unfilter paths), decodes it, and asserts
exact round-trip. Differential law: same data through both
pipelines.

Usage:
  python3 pngprof.py IMG.png                     # frame summary
  python3 pngprof.py IMG.png --band 48:143       # band stats
  python3 pngprof.py IMG.png --band 48:143 --cols 8
  python3 pngprof.py IMG.png --rows              # row means
"""
import struct, sys, zlib


def _paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def decode(path):
    """Return (width, height, rows) where rows[y][x] is gray 0-255."""
    data = open(path, 'rb').read()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('not a PNG: %s' % path)
    pos, idat, ihdr = 8, b'', None
    while pos < len(data):
        ln = struct.unpack('>I', data[pos:pos + 4])[0]
        typ = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + ln]
        if typ == b'IHDR':
            ihdr = struct.unpack('>IIBBBBB', chunk)
        elif typ == b'IDAT':
            idat += chunk
        elif typ == b'IEND':
            break
        pos += 12 + ln
    w, h, bd, ct, _comp, _filt, inter = ihdr
    if bd != 8:
        raise ValueError('bit depth %d unsupported (need 8)' % bd)
    if inter != 0:
        raise ValueError('interlaced PNG unsupported')
    if ct not in (0, 2, 6):
        raise ValueError('color type %d unsupported (0/2/6)' % ct)
    ch = {0: 1, 2: 3, 6: 4}[ct]
    bpp = ch
    stride = w * bpp
    raw = zlib.decompress(idat)
    if len(raw) != h * (stride + 1):
        raise ValueError('raw size %d != expected %d'
                         % (len(raw), h * (stride + 1)))
    rows, prev, i = [], bytearray(stride), 0
    for y in range(h):
        f = raw[i]
        i += 1
        line = bytearray(raw[i:i + stride])
        i += stride
        if f == 1:      # Sub
            for x in range(bpp, stride):
                line[x] = (line[x] + line[x - bpp]) & 0xFF
        elif f == 2:    # Up
            for x in range(stride):
                line[x] = (line[x] + prev[x]) & 0xFF
        elif f == 3:    # Average
            for x in range(stride):
                a = line[x - bpp] if x >= bpp else 0
                line[x] = (line[x] + ((a + prev[x]) >> 1)) & 0xFF
        elif f == 4:    # Paeth
            for x in range(stride):
                a = line[x - bpp] if x >= bpp else 0
                c = prev[x - bpp] if x >= bpp else 0
                line[x] = (line[x] + _paeth(a, prev[x], c)) & 0xFF
        elif f != 0:
            raise ValueError('bad filter type %d at row %d' % (f, y))
        prev = line
        if ct == 0:
            rows.append(list(line))
        else:           # RGB / RGBA -> luma (alpha ignored)
            row = []
            for x in range(w):
                p = line[x * bpp:x * bpp + 3]
                row.append((p[0] * 299 + p[1] * 587 + p[2] * 114) // 1000)
            rows.append(row)
    return w, h, rows


def mean(vals):
    vals = list(vals)
    return sum(vals) / len(vals) if vals else 0.0


def region_mean(rows, x0, x1, y0, y1):
    return mean(v for y in range(y0, y1) for v in rows[y][x0:x1])


def col_bins(rows, x0, x1, y0, y1, nbins):
    """Mean gray per column bin across the band."""
    step = max(1, (x1 - x0) // nbins)
    out = []
    for b in range(nbins):
        bx0, bx1 = x0 + b * step, min(x1, x0 + (b + 1) * step)
        out.append(round(region_mean(rows, bx0, bx1, y0, y1), 1))
    return out


def row_means(rows, y0, y1):
    return [round(mean(rows[y]), 1) for y in range(y0, y1)]


def _selftest():
    """Encode a synthetic image with all 5 filter types, decode, assert."""
    w, h = 17, 10
    orig = [[(x * 7 + y * 13 + (x * y) % 5) % 256 for x in range(w)]
            for y in range(h)]
    stride = w * 3
    raw = bytearray()
    filters = [0, 1, 2, 3, 4, 0, 1, 2, 3, 4]
    prev = bytearray(stride)
    for y in range(h):
        line = bytearray()
        for x in range(w):
            p = orig[y][x]
            line += bytes((p, (p * 2) % 256, (255 - p) % 256))
        f = filters[y]
        enc = bytearray(line)
        if f == 1:      # Sub: orig[x] - orig[x-bpp]
            for x in range(stride - 1, 2, -1):
                enc[x] = (line[x] - line[x - 3]) & 0xFF
        elif f == 2:    # Up: orig[x] - prevrow[x]
            for x in range(stride):
                enc[x] = (line[x] - prev[x]) & 0xFF
        elif f == 3:    # Average: orig[x] - floor((left+up)/2)
            for x in range(stride):
                a = line[x - 3] if x >= 3 else 0
                enc[x] = (line[x] - ((a + prev[x]) >> 1)) & 0xFF
        elif f == 4:    # Paeth: orig[x] - Paeth(left, up, upleft)
            for x in range(stride):
                a = line[x - 3] if x >= 3 else 0
                c = prev[x - 3] if x >= 3 else 0
                enc[x] = (line[x] - _paeth(a, prev[x], c)) & 0xFF
        raw += bytes([f]) + enc
        prev = line
    def chunk(typ, data):
        return (struct.pack('>I', len(data)) + typ + data
                + struct.pack('>I', zlib.crc32(typ + data) & 0xFFFFFFFF))
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    idat = zlib.compress(bytes(raw))
    png = (b'\x89PNG\r\n\x1a\n'
           + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b''))
    path = '/tmp/pngprof_selftest.png'
    open(path, 'wb').write(png)
    dw, dh, rows = decode(path)
    assert (dw, dh) == (w, h), (dw, dh)
    for y in range(h):
        for x in range(w):
            exp = (orig[y][x] * 299 + (orig[y][x] * 2 % 256) * 587
                   + ((255 - orig[y][x]) % 256) * 114) // 1000
            assert rows[y][x] == exp, (y, x, rows[y][x], exp)
    print('selftest OK: %dx%d, all 5 filter types round-trip exact'
          % (w, h))


def main():
    if '--selftest' in sys.argv:
        _selftest()
        return
    path = sys.argv[1]
    w, h, rows = decode(path)
    band = None
    cols = 8
    argv = sys.argv[2:]
    if '--band' in argv:
        y0, y1 = map(int, argv[argv.index('--band') + 1].split(':'))
        band = (y0, y1)
    if '--cols' in argv:
        cols = int(argv[argv.index('--cols') + 1])
    scene = mean(v for row in rows for v in row)
    print('frame %s: %dx%d scene_avg=%.1f' % (path, w, h, scene))
    if band:
        y0, y1 = band
        bm = region_mean(rows, 0, w, y0, y1)
        print('band y=%d:%d avg=%.1f ratio=%.2f'
              % (y0, y1, bm, bm / scene if scene else 0))
        print('col_bins(%d): %s' % (cols, col_bins(rows, 0, w, y0, y1, cols)))
        print('row_means: %s' % row_means(rows, y0, y1))


if __name__ == '__main__':
    main()