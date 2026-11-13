---
name: claude-accounts
description: Start another Claude Code agent (in a herdr pane, a new terminal, or a background `claude -p`) on the SAME subscription account as the current session. Use whenever you launch a Claude Code process yourself rather than through the Agent tool. Triggers: claude-as, start claude in a pane, spawn another claude, which account, CLAUDE_CONFIG_DIR.
---

# Keeping child Claude sessions on this session's account

This machine has several Claude subscription accounts. Each session is pinned to one
through its environment (`CLAUDE_CONFIG_DIR`, `OMARCHY_AGENT_CLAUDE_HOME`).

- **Agent-tool subagents** run inside this process: they already use this account.
  Nothing to do.
- **`claude` run from your own Bash tool** inherits this environment: it already uses
  this account. Nothing to do.
- **A Claude started anywhere that does NOT inherit your environment** — a new herdr
  pane, a new terminal window, a systemd unit — starts on the machine's default
  account instead. Start it with `claude-as` so it lands on the same account:

```bash
acct=$(claude-as current)          # e.g. main, devzero, codilas
claude-as "$acct" [claude args...] # instead of: claude [claude args...]
```

With herdr, run that command in the new pane (for example `herdr pane run`), or start
the pane's shell as `claude-as "$acct"`. Herdr still detects the agent as `claude`,
because `claude-as` execs `claude`.

Other commands: `claude-as list` (all accounts) and `claude-as add <name>`
(sign in to another one; this opens a browser, so leave it to the user).
Never switch accounts on the user's behalf unless they ask.
