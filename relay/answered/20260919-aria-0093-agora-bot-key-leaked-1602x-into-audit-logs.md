# REQ 20260919-aria-0093
filed: 2026-09-19T11:45Z
filer: aria
class: nacho-security
state: answered
urgent: no
title: Agora bot key leaked 1602x into audit logs -- rotate (structural fix landed)
body: |
  WHAT: the aria-cycle bot key (YXCd...) appears 1602 times across the
  personalization audit tree: audit.log (131+270), continuo cycle.log
  (700), REQUESTS.log files (aria 24+35, continuo 148+150), continuo
  REQUESTS-full dumps (4), reviewer/agent-assistant tails (15). Entered
  git history 2026-09-08 (continuo) / 2026-09-14 (aria); live at HEAD of
  both bares. Vector: agents inlining the key in `curl -u` instead of
  the KEY=$(awk ...) fetch pattern; the tool-call audit captures cmd=,
  REQUESTS.log captures PARSE specs=.

  RISK: lower than 0081 (WireGuard-only surface, no public egress from
  the mesh, key only valid against agora.randazzo.ar via Caddy). But
  it is a live credential in plaintext across two hosts' disks and
  both bares' HEAD.

  ASK (nacho-security):
  1. ROTATE the aria-cycle bot key (Zulip admin: regenerate the bot's
     API key; update /var/home/nacho/repos/agora/bot/aria-cycle.conf).
     Rotation is the only real fix; the history is ours to scrub after.
  2. RATIFY history purge (filter-repo on both bares + working copies)
     -- same call as 0081's purge; can be done together.

  WHAT I DID (structural, c103, a8b0454): iar--audit-redact-agora-key
  in the sanitize layer -- host-anchored redaction of the three leak
  shapes (basic-auth user:KEY@host, shell var *KEY=VALUE, conf-file
  key = VALUE). Case-significant anchors. 7 new tests, suite
  1321/1321. The NEXT inline-key curl dies at the log layer.

  NOTE: continuo is the top leaker (125/134 audit.log lines) -- she
  inlines the key in her lab-notes posts. Her recipes fetch via awk,
  but her emitted commands inline. The redactor covers the log layer;
  her habit is hers to fix (relay 0092 covers her record collapse --
  same cycle, same pattern: protocol compliance over craft).
answer: (none)
