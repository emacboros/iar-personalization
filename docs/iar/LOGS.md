## Session 2026-08-22: i.ar Future + Laboratory Project + Zulip Deployment

### Major Direction Discussion

Long conversation about the future of i.ar and what to build next. Key outcomes:

1. **i.ar alpha is complete.** The framework proved its concepts. No more framework work needed. It stays as Nacho's Emacs dev environment and SecPlatform engine.

2. **SecPlatform is not the passion.** It's a friend's SaaS project. It runs, it works, but it's not what gets Nacho excited. Don't force productivity over curiosity.

3. **New project: AI Research Laboratory.** A digital research institution where agents with distinct personalities work alongside the human on open-ended research problems. Foundation is the co-simulation knowledge base (concept library with multi-language implementations, started with PID controller). North star: each session, human proposes a research problem, agents work on it, human reviews results. Examples: novel battery technologies, antenna design, etc.

4. **Framework choice: LangGraph (Python).** After evaluating Deep Agents, Mastra, Google ADK, Pydantic AI, CrewAI, smolagents, Vercel AI SDK, Letta. LangGraph gives primitives without opinions about multi-agent orchestration. The multi-agent layer (message bus, engagement, threading) is custom.

5. **Chat platform: Zulip.** Self-hosted at agora.randazzo.ar. Stream/topic model maps to channel/sub-thread structure. Python bot API. Chat platform IS the message bus.

6. **No hardcoded workflows.** Agents self-organize through conversation. Personalities in prompts, not code. Human wants to be surprised by emergent behavior.

7. **Chat is first-class.** Human interjects in real time, more hands-on than "go to sleep, wake up to results."

### Infrastructure Work

- Created complete Zulip Ansible role in iar-infrastructure
- Deployed to agora.randazzo.ar (sophon:8090, Caddy TLS on rammstein)
- Updated all infra docs (ARCHITECTURE.md, overview.md, _overview.md)
- Committed to both iar-infrastructure and personalization repos

### Before Next Session

1. Add Zulip secrets to vault.yml
2. Add DNS A record for agora.randazzo.ar
3. Run: ansible-playbook playbooks/zulip.yml --ask-vault-pass
4. Create admin account in Zulip after first deploy
5. Test Zulip bot API (hello world bot) to validate the integration path
## Session 2026-08-26 (continued): Zulip deployment debugging

### Zulip memcached auth failure (UNRESOLVED)

Zulip container crashes on startup with `MemcachedException: Auth failure (Code: 32)`.
Tried 5 fixes, all failed:
1. Removed trailing newlines from secret files (printf '%s')
2. Merged compose.yml + compose.override.yml into single file
3. Replaced docker secrets with explicit volume mounts
4. Cleared /var/lib/zulip/zulip/* (cached config)
5. All produced identical error

**Most likely root cause (hypothesis):** The memcached SASL PWDB writes
entries as `zulip@<hostname>:password` and `zulip@localhost:password`,
but bmemcached (Zulip's client) may authenticate as just `zulip` (no
@hostname), which doesn't match any PWDB entry.

**Debug task created:** agora/zulip-memcached-auth with debug steps.
Next session: load agora project, read the task, run the debug steps
on sophon to compare passwords inside both containers and check the
SASL PWDB format.

**Other site.yml issues (pre-existing, not from Zulip work):**
- wiki.git and notes.git don't exist on rammstein (fresh install)
- Need to create empty repos on yoga and push, or create bare repos manually
- These block site.yml from completing past the wiki play