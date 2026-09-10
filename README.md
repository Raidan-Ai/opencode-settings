# OpenCode AI Engineering Configuration (codedata)

> A portable, **secret-free** collection of OpenCode agent definitions, skills, commands, context, plugins, tools, and MCP configuration — ready to install on any machine.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)
![Agents](https://img.shields.io/badge/Agents-50-blue)
![Skills](https://img.shields.io/badge/Skills-410-purple)
![Dashboard](https://img.shields.io/badge/Dashboard-Zero--Dependency-green)

> **Security guarantee:** All credentials in this repo are placeholders (`{env:VAR}` or `your_..._here`). Real tokens live ONLY in your local environment / `.env` files, which are git-ignored.

---

## Table of contents

1. [Features](#features)
2. [Installation](#installation)
3. [Dashboard](#dashboard-browsing--editing-your-setup)
4. [Directory structure](#directory-structure)
5. [Env variables](#env-variables)
6. [MCP servers](#mcp-servers)
7. [Providers](#providers)
8. [Security notes](#security-notes)
9. [Uninstallation](#uninstallation)
10. [Updating from source](#updating-from-source)
11. [Troubleshooting / FAQ](#troubleshooting--faq)
12. [Contributing](#contributing)
13. [License / Authorship](#license--authorship)

---

## Features

- **50 agent definitions** across 6 categories — core, content, meta, subagents, and data specialists with role-specific system prompts.
- **410 skills (47 opencode + 363 NVIDIA)** — Cloudflare, frontend, security, cuOpt, DOCA, Jetson, TAO, DeepStream, NeMo, and more, each with its own `SKILL.md`.
- **12 custom slash commands** for common workflows.
- **175 context files** — the context system (core, development, project-intelligence, ui).
- **12 MCP servers configured** — context7, GitHub, Cloudflare suite, Notion, Composio, codebase-memory enabled out of the box; 9 more pre-wired (disabled until you add credentials).
- **Zero-dependency browser dashboard** — browse and edit agents, skills, config, and MCP servers from `http://127.0.0.1:8877` (Node standard library only, no `npm install`).
- **Cross-platform installers** — `install.sh` (Linux/macOS) and `install.ps1` (Windows) with dry-run, uninstall, backup, and verification.
- **Secret-free by design** — every token is a `{env:VAR}` placeholder; keys never ship in the repo.

---

## Installation

### Prerequisites

- [Bun](https://bun.sh) or [Node.js](https://nodejs.org) (for plugin dependencies)
- [OpenCode](https://opencode.ai) CLI
- Git

### Linux / macOS — automated installer

```bash
# 1. Clone (private repo — use your own remote)
git clone git@github.com:Raidan-Ai/opencode-settings.git ~/opencode-settings
cd ~/opencode-settings

# 2. Install plugin dependencies
bun install          # or: npm install

# 3. Run the installer
bash install.sh
```

The installer backs up any existing config, copies everything into place, and runs a verification step.

**Installer flags (`install.sh`):**

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Show usage text |
| `--dry-run` | Print what *would* happen — copies nothing |
| `--uninstall` | Remove installed dirs (after backing them up to `*.uninstall-backup.<ts>`) |
| `--no-dashboard` | Skip the dashboard copy |
| `--no-backup` | Skip the backup step |
| `--force` | Overwrite without prompting (default: prompt if target exists) |
| `--prefix <dir>` | Install into a custom prefix instead of `~/.config/opencode` |

### Windows — automated installer

```powershell
# 1. Clone
git clone git@github.com:Raidan-Ai/opencode-settings.git $HOME\opencode-settings
cd $HOME\opencode-settings

# 2. Install plugin dependencies
bun install          # or: npm install

# 3. Run the installer (PowerShell — no admin required)
.\install.ps1
```

**Installer flags (`install.ps1`):**

| Flag | Description |
|------|-------------|
| `-Help` | Show usage text |
| `-DryRun` | Print what *would* happen — copies nothing |
| `-Uninstall` | Remove installed dirs (after backing them up first) |
| `-NoDashboard` | Skip the dashboard copy |
| `-NoBackup` | Skip the backup step |
| `-Force` | Overwrite without prompting |
| `-Prefix <dir>` | Install into a custom prefix instead of `%USERPROFILE%\.config\opencode` |

### Manual copy (all platforms)

<details>
<summary>Linux / macOS</summary>

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

</details>

<details>
<summary>Windows (PowerShell)</summary>

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

</details>

> OpenCode resolves `~/.config/opencode` identically on Linux, macOS, and Windows — no platform-specific config path is needed.

---

## Dashboard (browsing & editing your setup)

The repo ships a **zero-dependency** web dashboard (Node standard library only —
no `npm install`). Both installers copy it to `~/.config/opencode/dashboard/`.

```bash
# Start (Linux / macOS)
node ~/.config/opencode/dashboard/server.js

# Windows
node "$HOME\.config\opencode\dashboard\server.js"
```

Open <http://127.0.0.1:8877> — inspect agents, skills, models, MCP servers, and
`opencode.jsonc`; edit agents/config directly from the browser (every write
creates a `.bak-dash-*` backup first). Env overrides: `DASHBOARD_PORT`,
`DASHBOARD_HOST`, `OPENCODE_AGENT_DIR`, `OPENCODE_SKILLS_DIR`,
`OPENCODE_CONFIG_FILE`. Full API + config docs in `dashboard/README.md`.

---

## Directory structure

```
codedata/
├── opencode.jsonc        # Main OpenCode config (permissions, MCP, providers — sanitized)
├── env.example           # Environment variable template (tokens, API keys)
├── package.json          # Plugin dependencies (@opencode-ai/plugin)
├── skill-lock.json       # Skill registry lock (cloudflare + nvidia skill sources)
├── install.sh            # Installer (Linux / macOS)
├── install.ps1           # Installer (Windows)
├── README.md             # This documentation (English)
├── README-ar.md          # Documentation (Arabic, RTL)
├── agents/               # 50 custom agent definitions (core, content, meta, subagents, data)
├── commands/             # 12 custom slash commands
├── config/               # Supplemental config (agent-metadata.json)
├── context/              # Context system — 175 files (core, development, project-intelligence, ui)
├── plugins/              # OpenCode plugins (notify.ts)
├── skills/
│   ├── opencode/         # 47 installed OpenCode skills (cloudflare, frontend, security, …)
│   └── nvidia/           # 363 NVIDIA skills (cuOpt, DOCA, Jetson, TAO, DeepStream, …)
├── tools/                # Custom tools (env loader, gemini)
└── dashboard/            # Zero-dependency web dashboard (agents/skills/config UI)
```

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

## Uninstallation

Both installers support a clean uninstall that **backs up first** — nothing is
deleted without a timestamped copy (`*.uninstall-backup.<ts>`).

```bash
# Linux / macOS — dry-run first, then uninstall
bash install.sh --uninstall --dry-run
bash install.sh --uninstall
```

```powershell
# Windows — dry-run first, then uninstall
.\install.ps1 -Uninstall -DryRun
.\install.ps1 -Uninstall
```

> The uninstall removes `~/.config/opencode` and `~/.agents` (after backing them
> up). To finish, also delete the local clone: `rm -rf ~/opencode-settings`.

---

## Updating from source

```bash
# Re-sync config after local changes (Linux/macOS):
rsync -av --exclude node_modules ~/.config/opencode/ ./ --include opencode.jsonc
# Sanitize before committing: replace any new tokens with {env:VAR} placeholders.
```

---

## Troubleshooting / FAQ

**OpenCode doesn't see my agents.**
Make sure the agents are in `~/.config/opencode/agents` (or the legacy `agent/`), then restart OpenCode. Run `bash install.sh --dry-run` to confirm the installer sees the files.

**The dashboard port is already in use.**
Another instance may be running. Set a different port: `DASHBOARD_PORT=9000 node ~/.config/opencode/dashboard/server.js`, or stop the old process first.

**Skills aren't showing up.**
Skills live in `~/.config/opencode/skills/` (opencode) and `~/.agents/skills/` (NVIDIA). Re-run the installer — it copies both locations and verifies the counts.

**How do I verify the install?**
Re-run the installer — it ends with a verification step that checks `opencode.jsonc`, counts agent files, and confirms the dashboard. Expect the printed counts to match: 50 agents, 47 opencode skills, 363 NVIDIA skills.

---

## Contributing

1. Fork the repo and create a feature branch.
2. Keep every secret out — use `{env:VAR}` placeholders for anything machine- or user-specific.
3. Run the secret scan from [Security notes](#security-notes) before pushing.
4. Open a pull request describing the change (agent, skill, or config) and what it adds.

---

## License / Authorship

Configuration authored for the AI Agent Engineering OS setup. Agents and skills retain their original upstream licenses (Cloudflare, NVIDIA, Superpowers, etc.).