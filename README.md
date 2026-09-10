# OpenCode AI Engineering Configuration (codedata)

A portable, **secret-free** collection of OpenCode agent definitions, skills, commands, context, plugins, tools, and MCP configuration — ready to install on any machine (Linux, macOS, Windows).

> **Security guarantee:** All credentials in this repo are placeholders (`{env:VAR}` or `your_..._here`). Real tokens live ONLY in your local environment / `.env` files, which are git-ignored.

---

## Directory structure

```
codedata/
├── opencode.jsonc        # Main OpenCode config (permissions, MCP, providers — sanitized)
├── env.example           # Environment variable template (tokens, API keys)
├── package.json          # Plugin dependencies (@opencode-ai/plugin)
├── skill-lock.json       # Skill registry lock (cloudflare + nvidia skill sources)
├── agents/               # Custom agent definitions (core, meta, subagents, data)
├── commands/             # Custom slash commands
├── config/               # Supplemental config (agent-metadata.json)
├── context/              # Context system (core, development, project-intelligence, ui)
├── plugins/              # OpenCode plugins (notify.ts)
├── skills/
│   ├── opencode/         # Installed OpenCode skills (cloudflare, frontend, security, …)
│   └── nvidia/           # NVIDIA skills (cuOpt, DOCA, Jetson, TAO, DeepStream, …)
└── tools/                # Custom tools (env loader, gemini)
```

---

## Installation

### Prerequisites
- [Bun](https://bun.sh) or [Node.js](https://nodejs.org) (for plugin dependencies)
- [OpenCode](https://opencode.ai) CLI

### Linux / macOS

```bash
# 1. Clone (private repo — use your own remote)
git clone git@github.com:<YOU>/codedata.git ~/codedata
cd ~/codedata

# 2. Install plugin dependencies
bun install          # or: npm install

# 3. Copy configuration into place
mkdir -p ~/.config/opencode
cp -r agents commands config context plugins skills tools ~/.config/opencode/
cp opencode.jsonc env.example package.json ~/.config/opencode/

# 4. Set your credentials (see Env variables below)
cp ~/.config/opencode/env.example ~/.config/opencode/.env
# … edit .env with YOUR real tokens …
```

### Windows (PowerShell)

```powershell
# 1. Clone
git clone git@github.com:<YOU>/codedata.git $HOME\codedata
cd $HOME\codedata

# 2. Install plugin dependencies
bun install          # or: npm install

# 3. Copy configuration into place (OpenCode uses the same path on Windows)
New-Item -ItemType Directory -Force $HOME\.config\opencode
Copy-Item -Recurse agents, commands, config, context, plugins, skills, tools $HOME\.config\opencode\
Copy-Item opencode.jsonc, env.example, package.json $HOME\.config\opencode\

# 4. Set your credentials
Copy-Item $HOME\.config\opencode\env.example $HOME\.config\opencode\.env
# … edit .env with YOUR real tokens …
```

> OpenCode resolves `~/.config/opencode` identically on Linux, macOS, and Windows — no platform-specific config path is needed.

---

## Env variables

All secrets are referenced via `{env:VAR}` in `opencode.jsonc` and `process.env.*` in tools/plugins.

| Variable | Purpose |
|----------|---------|
| `GITHUB_TOKEN` | GitHub MCP server (PAT with `repo` scope) |
| `NOTION_TOKEN` | Notion MCP remote server Bearer token |
| `COMPOSIO_API_KEY` | Composio MCP remote server consumer key |
| `DATABASE_URL` | Postgres MCP (disabled by default) |
| `REDIS_URL` | Redis MCP (disabled by default) |
| `MILVUS_ADDR` | Milvus MCP (disabled by default) |
| `RAIDAN_BASE_URL` | Raidan provider OpenAI-compatible base URL (e.g. your own gateway/tunnel) |
| `AWS_REGION` / `AWS_PROFILE` | AWS MCP servers (disabled by default) |
| `ALIBABA_CLOUD_ACCESS_KEY_ID` / `_SECRET` | Alibaba Cloud Ops MCP (disabled by default) |
| `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` | Telegram plugin (optional) |
| `GEMINI_API_KEY` | Gemini tool (set `GEMINI_TEST_MODE=true` for tests) |
| `MINIMAX_API_KEY` | MiniMax API (optional) |

OpenCode also supports `{env:VAR}` inline in config values — see `opencode.jsonc` for the exact usage.

---

## MCP servers

| Server | Status | Notes |
|--------|--------|-------|
| context7 | ✅ enabled | Remote, no auth |
| github | ✅ enabled | Requires `GITHUB_TOKEN` |
| cloudflare (+docs, bindings, builds, observability) | ✅ enabled | OAuth — `opencode mcp auth cloudflare` |
| notion | ✅ enabled | Requires `NOTION_TOKEN` |
| composio | ✅ enabled | Requires `COMPOSIO_API_KEY` |
| codebase-memory | ✅ enabled | Local binary at `~/.codebase-memory` (v0.10.8) |
| playwright / postgres / redis / milvus / azure / aws / vercel / gcloud / firebase | ⛔ disabled | Enable after provisioning credentials |

---

## Providers

`opencode.jsonc` defines model providers (K3, DeepSeekPro, Nemotron, Raidan) as OpenAI-compatible endpoints. Only the *endpoint* is declared — **no API keys are stored in this repo**. Add your key via environment variables or the OpenCode auth flow.

---

## Security notes

- Run a secret scan before pushing:
  ```bash
  grep -rlnE "ghp_|ntn_|sk-[A-Za-z0-9]|AKIA[0-9A-Z]|Bearer [A-Za-z0-9_-]{20,}" . --exclude-dir=node_modules
  ```
- `.env` files, lock files, and node_modules are git-ignored.
- Keep this repo **private** — agent configs may encode proprietary conventions.
- If you fork, replace the `raidan` provider `{env:RAIDAN_BASE_URL}` with your own endpoint.

---

## Updating from source

```bash
# Re-sync config after local changes (Linux/macOS):
rsync -av --exclude node_modules ~/.config/opencode/ ./ --include opencode.jsonc
# Sanitize before committing: replace any new tokens with {env:VAR} placeholders.
```

---

## License / Authorship

Configuration authored for the AI Agent Engineering OS setup. Agents and skills retain their original upstream licenses (Cloudflare, NVIDIA, Superpowers, etc.).