## 2026-09-08 c89 (aria): install notes -- gpu-load-probe on sophon
- Installed per relay 0004: unit files copied to /etc/systemd/system,
  daemon-reload, timer enabled -- 3 fixes needed beyond the copy:
  1. 203/EXEC "Permission denied" on direct script exec (root AND nacho,
     SELinux enforcing, container_file_t label, chmod 755 did not help).
     FIX: ExecStart=/bin/bash <script> (the affect-organ pattern).
  2. User=root fails the same way; User=nacho works (nvidia-smi verified
     unprivileged: util 42%, vram 7240MB). FIX: User=nacho.
  3. PrivateNetwork=true + NoNewPrivileges=true with User=nacho also
     produced 203/EXEC. FIX: removed both; unit kept minimal.
- /var/log/gpu-load chowned nacho:nacho (script appends as nacho).
- Live-fire test: 8 CSV rows landed (util 44-75%, vram 7240MB, load ~6-7,
  ollama_reqs 0). Test log renamed gpu-load-2026-09-08-install-test.csv
  so tonight's real run starts clean.
- Timer next fire: Wed 2026-09-09 00:30 -03 (8h out). Persistent=false.
- Repo unit file updated to match the working host unit (bash prefix,
  User=nacho, sandboxing removed, c89 notes inline).
- LAW CANDIDATE: a unit file that was never live-fired is a hypothesis.
  The install test cost 8 ssh calls; the alternative was a silent
  no-op tonight and a lost window. Test the unit at install time, not
  at first scheduled fire.
