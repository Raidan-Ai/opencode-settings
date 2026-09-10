# OpenCode codedata

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Agents](https://img.shields.io/badge/agents-50-green)
![OpenCode Skills](https://img.shields.io/badge/opencode_skills-47-green)
![NVIDIA Skills](https://img.shields.io/badge/nvidia_skills-363-green)
![Commands](https://img.shields.io/badge/commands-12-blueviolet)
![Tools](https://img.shields.io/badge/tools-2-orange)
![Plugins](https://img.shields.io/badge/plugins-1-orange)
![Context](https://img.shields.io/badge/context_files-176-lightgrey)
![Platform](https://img.shields.io/badge/platform-Linux_%7C_macOS_%7C_Windows-lightgrey)

A curated, version-controlled collection of OpenCode **agents**, **skills**,
**commands**, **context**, **tools**, and **plugins** — packaged with one-shot
installers for Linux/macOS (`install.sh`) and Windows (`install.ps1`).

> **Table of Contents**
>
> - [Features](#features)
> - [Repository Layout](#repository-layout)
> - [Quick Start](#quick-start)
> - [Installer Options](#installer-options)
> - [Dashboard](#dashboard)
> - [Environment Variables](#environment-variables)
> - [What Gets Installed Where](#what-gets-installed-where)
> - [Verification](#verification)
> - [Updating](#updating)
> - [Uninstalling](#uninstalling)
> - [Contributing](#contributing)
> - [Security](#security)
> - [Troubleshooting](#troubleshooting)
> - [FAQ](#faq)
> - [License](#license)

---

## Features

| Area | Count | Description |
|------|------:|-------------|
| **Agents** | 50 | Sub-agents: Planner, Worker, Reviewer, plus specialized engineers (security, database, frontend, cloud, DevOps, NVIDIA, cloud-native…). |
| **OpenCode skills** | 47 | Official OpenCode skill set (software engineering, cloud, frontend, backend, databases, security…). |
| **NVIDIA skills** | 363 | NVIDIA agent skills covering DOCA, DeepStream, Holoscan, Jetson, cuOpt, cuDF, NeMo, TAO, Dynamo, VSS, RAG blueprints and more. |
| **Commands** | 12 | Reusable slash commands. |
| **Context** | 176 | Shared context files for consistent agent behavior. |
| **Tools** | 2 | Extra tooling (`env`, `gemini`). |
| **Plugins** | 1 | `notify` plugin. |
| **Total tracked files** | ~5,600 | Everything in a single git repo. |

- **Zero-dependency dashboard** — local web UI served by Node, no `npm install`.
- **Dry-run support** — preview every action before touching your disk.
- **Automatic backups** — your existing config is never destroyed.
- **Cross-platform** — identical feature set on Unix and Windows.

## Repository Layout

```
codedata/
├── agents/               # 50 agent definitions
├── commands/             # 12 slash commands
├── config/               # agent metadata
├── context/              # 176 shared context files
├── dashboard/            # zero-dependency local dashboard
│   ├── server.js         # Node HTTP server (port 8877)
│   └── public/           # static assets
├── plugins/              # notify plugin
├── skills/
│   ├── opencode/         # 47 OpenCode skills
│   └── nvidia/           # 363 NVIDIA skills
├── tools/                # env + gemini tooling
├── env.example           # environment variable template
├── install.ps1           # Windows PowerShell installer
├── install.sh            # Linux/macOS shell installer
├── opencode.jsonc        # OpenCode configuration
├── package.json
└── skill-lock.json       # pinned skill dependency versions
```

## Quick Start

### Linux / macOS

```bash
git clone https://github.com/Raidan-Ai/opencode-settings.git codedata
cd codedata
bash install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/Raidan-Ai/opencode-settings.git codedata
cd codedata
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

After installing:

1. `cp env.example .env` (or `Copy-Item env.example .env` on Windows).
2. Fill in your provider tokens (see [Environment Variables](#environment-variables)).
3. Run `opencode` — your agents and skills are ready.
4. (Optional) start the dashboard: `node dashboard/server.js`.

## Installer Options

### `install.sh`

| Flag | Description |
|------|-------------|
| `--help` | Show help and exit |
| `--dry-run` | Preview every action, modify nothing |
| `--uninstall` | Back up and remove installed configuration |
| `--no-dashboard` | Skip the dashboard |
| `--no-backup` | Skip backing up existing configuration |
| `--force` | Overwrite without confirmation |
| `--prefix <dir>` | Install opencode config under `<dir>/.config/opencode` (agents/skills still go to `~/.agents`) |

### `install.ps1`

| Flag | Description |
|------|-------------|
| `-Help` | Show help and exit |
| `-DryRun` | Preview every action, modify nothing |
| `-Uninstall` | Back up and remove installed configuration |
| `-NoDashboard` | Skip the dashboard |
| `-NoBackup` | Skip backing up existing configuration |
| `-Force` | Overwrite without confirmation |
| `-Prefix <dir>` | Install opencode config under `<dir>\.config\opencode` (agents/skills still go to `~\.agents`) |

> **No administrator rights required** — everything installs into your user
> profile. PowerShell scripts are run with current user permissions.

## Dashboard

The installer copies `dashboard/` to your OpenCode config directory.
It is a zero-dependency Node.js HTTP server:

```bash
node ~/.config/opencode/dashboard/server.js
# -> http://127.0.0.1:8877
```

Configuration via environment variables:

| Variable | Default | Purpose |
|----------|---------|---------|
| `DASHBOARD_PORT` | `8877` | HTTP port |
| `DASHBOARD_HOST` | `127.0.0.1` | Bind address |
| `DASHBOARD_DIR` | `<config>/dashboard` | Static file root |
| `OPENCODE_AGENT_DIR` | `<config>/agents` | Agents directory shown by dashboard |
| `OPENCODE_SKILLS_DIR` | `<config>/skills` | Skills directory shown by dashboard |
| `OPENCODE_CONFIG_FILE` | `<config>/opencode.jsonc` | Config file shown by dashboard |

## Environment Variables

The installer ships an `env.example` template. Copy it to `.env` and fill in
your real values — never commit secrets to the repository:

| Variable | Example | Purpose |
|----------|---------|---------|
| `OPENCODE_API_KEY` | `{env:API_KEY}` | Main provider API key |
| `ANTHROPIC_API_KEY` | `{env:ANTHROPIC_API_KEY}` | Anthropic provider |
| `OPENAI_API_KEY` | `{env:OPENAI_API_KEY}` | OpenAI provider |
| `GEMINI_API_KEY` | `{env:GEMINI_API_KEY}` | Google Gemini provider |
| `NVIDIA_API_KEY` | `{env:NVIDIA_API_KEY}` | NVIDIA NIM / NGC provider |

Secrets are referenced through `{env:VAR}` placeholders so plaintext keys never
appear in the repository.

## What Gets Installed Where

| Source | Destination (Linux/macOS) | Destination (Windows) |
|--------|---------------------------|------------------------|
| `agents/`, `commands/`, `context/`, `plugins/`, `tools/`, `skills/` | `~/.config/opencode/…` (or `$PREFIX/.config/opencode/…`) | `~\.config\opencode\…` (or `$PREFIX\.config\opencode\…`) |
| `skills/nvidia/` | `~/.agents/skills/` | `~\.agents\skills\` |
| `skill-lock.json` | `~/.agents/.skill-lock.json` | `~\.agents\.skill-lock.json` |
| `dashboard/` | `~/.config/opencode/dashboard/` | `~\.config\opencode\dashboard\` |
| `opencode.jsonc`, `env.example`, `package.json` | `~/.config/opencode/` | `~\.config\opencode\` |

> Agents and skills are **always** installed to the user profile (`~/.agents`),
> even when `--prefix` / `-Prefix` is used for the OpenCode config.

## Verification

The installer runs a verification pass at the end:

- `opencode.jsonc` exists
- Agents directory is non-empty (reports file count)
- Skills directories are present (reports dir count)
- Dashboard `server.js` exists (unless `--no-dashboard`)
- `env.example` exists

Any missing item is reported as a warning with an exit-code signal.

## Updating

```bash
git pull
bash install.sh            # re-runs install; backups are created automatically
```

Or on Windows:

```powershell
git pull
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Force
```

## Uninstalling

Uninstalling **backs up first** — your configuration is copied to
`<target>.uninstall-backup.<timestamp>` before anything is removed.

### Linux / macOS

```bash
bash install.sh --uninstall
```

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

Use `--dry-run` / `-DryRun` first to preview exactly what will be removed.

## Contributing

1. Fork the repository.
2. Keep your additions inside the matching directory (`agents/`, `skills/`,
   `commands/`, `context/`, `plugins/`, `tools/`, `dashboard/`).
3. Update the installer `VERSION` (and this README's badges) if the
   installation layout changes.
4. Verify with a dry-run install before opening a pull request:

   ```bash
   bash install.sh --dry-run
   bash install.sh --dry-run --prefix /tmp/verify
   ```

## Security

- This repository contains **no secrets** — only `{env:VAR}` placeholders.
- Installers only write under your user profile.
- Never commit `.env` files or real API keys.
- Scanned for common secret patterns before every release.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Installer aborts with `set -e` failure | Run `bash install.sh --dry-run` to see which step fails |
| `--uninstall --dry-run` exits non-zero | Fixed in v2.0.0 — rerun with the latest installer |
| Skills not found by OpenCode | Confirm `~/.agents/skills` exists and `skill-lock.json` is present in `~/.agents` |
| Dashboard won't start | Check Node is installed and port 8877 is free (`DASHBOARD_PORT` to change) |
| Windows blocks the script | Use `powershell -ExecutionPolicy Bypass -File .\install.ps1` |

## FAQ

**Does installing overwrite my existing configuration?**
Only after prompting (or with `--force`/`-Force`). A timestamped backup is
created first.

**Why do agents go to `~/.agents`?**
OpenCode's agent runtime expects agents in the user profile, independent of the
config prefix. This keeps custom prefixes clean.

**How do I update only the NVIDIA skills?**
`git pull` then `bash install.sh -NoDashboard` re-installs everything except the
dashboard; skills are refreshed from `skills/nvidia/`.

**Can I use a different dashboard port?**
Yes — set `DASHBOARD_PORT` before starting the server.

## License

Private repository. Content is provided for the owner's use; see repository
settings for access permissions.