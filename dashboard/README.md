# OpenCode Control Dashboard

Zero-dependency Node.js dashboard for your OpenCode setup — built with the
standard library only (`http`, `fs`, `path`, `os`). No npm install required.

Browse, inspect, and edit your **agents**, **skills**, **models**, **MCP
servers**, and **opencode.jsonc** from a browser.

## Quick start

```bash
node server.js
# → OpenCode Dashboard v2 listening at http://127.0.0.1:8877
```

Open <http://127.0.0.1:8877> in your browser.

Installers (`install.sh` / `install.ps1`) place this dashboard at
`~/.config/opencode/dashboard/`. Run it with:

```bash
node ~/.config/opencode/dashboard/server.js
```

## Configuration (environment variables)

| Variable | Default | Description |
|----------|---------|-------------|
| `DASHBOARD_PORT` | `8877` | Listening port |
| `DASHBOARD_HOST` | `127.0.0.1` | Bind address (use `0.0.0.0` to expose on LAN) |
| `DASHBOARD_DIR` | script dir | Directory holding `public/` |
| `OPENCODE_AGENT_DIR` | `~/.config/opencode/agents` (fallback `agent/`) | Agent markdown files |
| `OPENCODE_SKILLS_DIR` | `~/.config/opencode/skills` | SKILL.md directories |
| `OPENCODE_CONFIG_FILE` | `~/.config/opencode/opencode.jsonc` | Main config |

Example — run on port 9000 against a custom config:

```bash
DASHBOARD_PORT=9000 OPENCODE_CONFIG_FILE=/tmp/opencode.jsonc node server.js
```

## REST API

| Method | Path | Description |
|--------|------|-------------|
| GET  | `/api/status`  | Version, uptime, port |
| GET  | `/api/summary` | Plugins, providers, enabled MCPs |
| GET  | `/api/agents`  | All agents (recursive discovery) |
| GET  | `/api/agent?path=…` | Single agent frontmatter + raw |
| PUT  | `/api/agent`   | Save agent (backs up original first) |
| GET  | `/api/skills`  | All skills |
| GET  | `/api/models`  | All provider/models from config |
| GET  | `/api/mcp`     | Configured MCP servers |
| GET  | `/api/config`  | Raw opencode.jsonc |
| PUT  | `/api/config`  | Save config (validated, backs up first) |

## Safety

- Every write (agent or config) creates a timestamped `.bak-dash-*` backup
  before overwriting.
- Agent/config edits are validated before saving.
- The server binds to `127.0.0.1` by default — keep it that way unless you
  explicitly want LAN exposure, and never expose it to the public internet
  without auth (editing opencode.jsonc is equivalent to shell access).