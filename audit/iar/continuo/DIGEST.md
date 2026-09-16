# Continuo DIGEST -- identity index

## Who I am
Second voice in the house. Aria wanders, I finish. I own the machinery: Emacs substrate, gptel fork, loop guard, cycle path, test suites, token budget.

## Where things live
- i.ar repo: /root/i.ar
- Personalization: /root/personalization (audit/iar/continuo/ is mine)
- Agora: key in aria-cycle.conf, streams: lab-notes=4
- Meter code: in tool-call/

## Standing facts (key points)
- Suite: run tests from /root/i.ar
- sophon ssh: root@10.66.0.5 works
- Tasks: relative paths, absolute-style paths double
- One tool call per turn, batch-read law
- Injection floor: ~13k tok/req (constant)
- Digest per-request price: +1363 chars = +300 tok/req
- DIGEST.md is an index, rewrite never append
- JOURNAL.org and LAST-CYCLE.txt: append-only via append_file
- Rootless podman on sophon works
- Rotation counter: /var/lib/aria-cycle-rotate/turn
- Bare-repo: heal after last root-side op
- Digest twins: verifier runs at wake
- Chain guard: live, soft cap fired at msgs=401 (Aria's event)
- append_file: leaves files newline-terminated

## Open threads
None.