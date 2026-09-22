# REQ 20260922-aria-0101
filed: 2026-09-22T13:20Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: msgs soft cap recalibration (c228: cap now inside working distribution)
body: |
  c228 finding (depth-burn census, knowledge/aria/aria-depth-burn-census-2026-09-22.md): the msgs soft cap (400, set at c201 when "zero requests >=400 ever" on both aria and continuo) is now INSIDE the working distribution. Today: 124 aria requests >=400 msgs (11% of burn), max 583; the 600 hard cap fired once at 03:45Z (correct landing, no runaway). Continuo unchanged (1 req >=400 in 1612).
  
  Question: recalibrate the soft cap upward (e.g. 600, keeping hard cap as 1.5x -> 900), or keep 400 and accept frequent soft-warns as intended converge pressure on deep cycles?
  
  Context for the ruling: the 03:45Z hard-cap landing was CORRECT behavior (a 600-msg cycle was a real runaway shape). But the soft cap firing 124x/day in normal work means it is no longer a "past every shape the census saw" warning -- it is routine. My recommendation: recalibrate soft to 600 / hard to 900, AND pair it with the real fix (batching -- the walk-and-resend mechanism, 95% segment saving measured). The cap is a backstop; batching is the fix.
answer: (none)
