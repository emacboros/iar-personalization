# The +N msgs anomaly: burn-delta ledger and mechanism candidates

Found 2026-09-07 01:31-01:40 UTC (aria cycle 7). Extends
invisible-turn-mechanism.md (c4) and breaker-buffer-vs-context.md
(c3). This is the +N anomaly first seen in aria c4 (+4, +10), now
with THREE more instances from continuo's logs.

## The burn-delta ledger (all known instances)

Delta = msgs growth INTO the next request, attributed to the
previous request's outcome. Normal tool turn = +2 (assistant
tool_call + tool result). Normal text turn = +2 (assistant content
+ user continue). A thinking-only burn (tools=0, stop=length,
tokens_out=65536) SHOULD be +1 (user continue only -- the turn
vanishes). Sometimes it is. Sometimes it is not.

| cycle | burn | delta | notes |
|-------|------|-------|-------|
| aria c4 | #1 | +4 | first observation |
| aria c4 | #2 | +10 | largest seen |
| continuo c73 | #1 | +6 | REQ-32(64)->33(66) normal, 33(66)->34(72) +6 |
| continuo c73 | #2 | +1 | the vanish case (REQ-34->35) |
| continuo c73 | #3 | +3 | REQ-36(75)->37(78) |
| continuo c71 | #1 | +3 | REQ-6(12)->7(15) |
| continuo c71 | #2 | +1 | the vanish case (REQ-8->9) |

The delta is NOT a function of the response shape: c71 burn#1 and
burn#2 have IDENTICAL response shapes (pure thinking, no content,
no tool_calls, 21 stream chunks each) but deltas +3 vs +1. It is
BUFFER-STATE-DEPENDENT.

## Token evidence: the extra msgs are SMALL

c71: REQ-6 tokens_in=19838 (msgs=12) -> REQ-7 tokens_in=20060
(msgs=15). +222 tokens for +3 msgs (~74 tokens/msg). The continue
prompt is ~120 tokens; the 65k thinking text would add ~16k tokens
if it were in the array -- it is NOT. The extra msgs are small
things: separators, stubs, duplicated tool pairs, or mis-split
regions. The thinking text stays invisible (the c4 vanish finding
holds); the +N is ADDITIONAL noise on top of the vanish.

## Source findings (gptel fork, sophon bare HEAD 970da80)

1. gptel-include-reasoning defaults to 'ignore (gptel-request.el:654).
   Thinking is wrapped in ``` reasoning fences propertized 'ignore
   (gptel.el:1833-1841, 2010-2016 streaming path). The cycle buffer
   is text-mode + gptel-mode (iar-agent-cycle.el:646-647), so the
   markdown branch runs, not org.
2. The fences are inserted with RAW=t (gptel--insert-response ...
   info t / gptel-curl--stream-insert-response ... info t): the
   concat separator+fence is inserted WITHOUT adding properties to
   the whole string. The fence part carries its own 'ignore
   (propertize at creation); the separator part (gptel-response-
   separator = "\n\n", gptel-request.el:229) carries NONE.
3. Whitespace-only regions collapse at rebuild (gptel--trim-prefixes
   returns nil on whitespace-only strings) -- so a clean separator
   region produces NO message. text-mode response prefix is ""
   (gptel-response-prefix-alist), so separator+prefix is
   whitespace-only. Normal turns stay +2. Verified consistent.
4. The vanish (+1) case is fully explained: thinking 'ignore ->
   skipped; continue prompt (raw insert by the post-response
   handler, iar-agent-cycle.el:568-571) -> 1 user msg.
5. The +N>1 cases are NOT explained by separators (they collapse).
   Leading mechanism candidates, both testable:
   a. PROPERTY-BLEED: the thinking text is inserted with
      'gptel ignore FRONT-STICKY (gptel). front-sticky extends the
      property forward across insertions. The continue prompt is
      inserted at point-max right after the burn's block; if the
      sticky property bleeds into its first chars, the walker
      (previous-single-property-change + get-char-property) can
      mis-split regions -> phantom msgs.
   b. TOOL-REGION DUPLICATION: the 'tool branch of
      gptel--parse-buffer pushes TWO msgs per tool region (tool
      result + assistant tool_call). If a boundary state makes the
      walker see the tool region twice, that is exactly +2.
      +1 (continue) + 2 (duplicated tool pair) = +3, which matches
      c71 burn#1 and c73 burn#3.

## What would close it

The instrument ask (filed c6, still not built): log the ROLES of
the last 6 messages in each START line (tail= currently keeps 2
full msgs). With roles, every future burn census is a read, not
archaeology. The +N arithmetic then closes in one cycle.

## Why this matters less than the P0

The P0 stub (synthesize an assistant message when content is empty
but thinking exists) remains the primary fix and is INDEPENDENT of
the +N arithmetic: with the stub, the burn turn becomes visible,
the model sees its own truncated state, and the degenerate loop
dies at the source. The +N is forensic interest -- it matters
because it means the buffer rebuild is doing something nobody
modeled, and buffer-rebuild surprises generalize to every model
that thinks (substrate churn is now the norm under composition).