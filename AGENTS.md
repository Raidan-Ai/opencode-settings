# AGENTS.md — Installation instructions for coding agents

## Mission
Install this OpenCode codedata (config collection) onto the user's machine.

## 1. Get the code
- Clone the private repo: `git clone git@github.com:Raidan-Ai/opencode-settings.git ~/opencode-settings` then `cd ~/opencode-settings`
- If credentials are required, ask the user for a GitHub token (do NOT guess).

## 2. Choose install mode (ask the user)
- **A) Update existing setup** — merge, never overwrite the user's current files (recommended for existing installs)
- **B) Full clean install** — fresh copy of everything (existing config is backed up automatically first)
- If the user has no existing setup, a full install is the default.

## 3. Run the installer
- Linux/macOS: `bash install.sh` -> interactive menu, OR non-interactive:
  - `bash install.sh --mode update` (update) / `bash install.sh --mode full` (full)
  - subset: `bash install.sh --components agents,skills,dashboard`
  - preview: `bash install.sh --dry-run`
- Windows: `.\install.ps1` (+ `-Mode update|full`, `-Components`, `-DryRun`)
- If Bun/Node are available, plugin deps get installed automatically (non-critical if missing).

## 4. Post-install (do for the user)
- Create `.env` from template if missing: `cp ~/.config/opencode/env.example ~/.config/opencode/.env` (Windows: Copy-Item)
- Tell the user they must fill real tokens into `.env` / run `opencode auth` — never put real secrets in the repo.
- Optional: start dashboard `node ~/.config/opencode/dashboard/server.js` -> http://127.0.0.1:8877 (only if the user asks).

## 5. Verify
- Confirm opencode.jsonc exists, agents dir has files (50), skills installed (47 opencode + 363 nvidia)
- Report install location + next steps to the user in their language.

## Security rules (NON-NEGOTIABLE)
- NEVER commit or write real tokens/secrets into repo files. Only `{env:VAR}` placeholders.
- Do not push to this repo unless asked.
- The repo is private — do not create public forks.

## Troubleshooting quick ref
- Dashboard port busy: DASHBOARD_PORT=9000 node .../server.js
- Skills missing: re-run installer (copies both ~/.config/opencode/skills and ~/.agents/skills)