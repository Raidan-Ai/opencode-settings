#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# install.sh — OpenCode codedata installer (Linux / macOS)
#
# Copies agents, skills (opencode + nvidia), plugins, commands,
# context, tools, and opencode.jsonc into the correct locations.
#
# Usage:  bash install.sh
# ──────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colors & helpers ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✔${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
err()  { echo -e "  ${RED}✘${RESET}  $*" >&2; }
info() { echo -e "  ${CYAN}ℹ${RESET}  $*"; }

# ── Resolve script directory ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   OpenCode codedata — Installer             ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""

# ── Check dependencies ────────────────────────────────────────
echo -e "${BOLD}[1/7] Checking dependencies...${RESET}"

if ! command -v git &>/dev/null; then
  err "git not found. Please install git first."
  exit 1
fi
ok "git $(git --version | awk '{print $3}')"

if command -v node &>/dev/null; then
  ok "node $(node --version)"
elif command -v bun &>/dev/null; then
  ok "bun $(bun --version)"
else
  warn "Neither node nor bun found. Plugin deps will be skipped."
fi

# ── Target paths ──────────────────────────────────────────────
OPENCODE_DIR="$HOME/.config/opencode"
AGENTS_DIR="$HOME/.agents"

# ── Backup existing configs ───────────────────────────────────
echo ""
echo -e "${BOLD}[2/7] Backing up existing configuration...${RESET}"

if [ -d "$OPENCODE_DIR" ]; then
  BACKUP_OPENCODE="$OPENCODE_DIR.backup.$(date +%s)"
  cp -a "$OPENCODE_DIR" "$BACKUP_OPENCODE"
  ok "Backed up $OPENCODE_DIR → $BACKUP_OPENCODE"
else
  info "No existing ~/.config/opencode/ to back up."
fi

if [ -d "$AGENTS_DIR" ]; then
  BACKUP_AGENTS="$AGENTS_DIR.backup.$(date +%s)"
  cp -a "$AGENTS_DIR" "$BACKUP_AGENTS"
  ok "Backed up $AGENTS_DIR → $BACKUP_AGENTS"
else
  info "No existing ~/.agents/ to back up."
fi

# ── Create target directories ─────────────────────────────────
echo ""
echo -e "${BOLD}[3/7] Creating target directories...${RESET}"

mkdir -p "$OPENCODE_DIR"/{agents,commands,config,context,plugins,skills,tools}
mkdir -p "$AGENTS_DIR/skills"
ok "Target directories created"

# ── Copy OpenCode config ──────────────────────────────────────
echo ""
echo -e "${BOLD}[4/7] Installing OpenCode configuration...${RESET}"

# Core config files
cp "$SCRIPT_DIR/opencode.jsonc"  "$OPENCODE_DIR/opencode.jsonc"
cp "$SCRIPT_DIR/env.example"     "$OPENCODE_DIR/env.example"
cp "$SCRIPT_DIR/package.json"    "$OPENCODE_DIR/package.json"
ok "opencode.jsonc, env.example, package.json"

# Agents
cp -a "$SCRIPT_DIR/agents/"* "$OPENCODE_DIR/agents/" 2>/dev/null || true
ok "agents/ ($(find "$SCRIPT_DIR/agents" -type f | wc -l) files)"

# Commands
cp -a "$SCRIPT_DIR/commands/"* "$OPENCODE_DIR/commands/" 2>/dev/null || true
ok "commands/ ($(find "$SCRIPT_DIR/commands" -type f | wc -l) files)"

# Config
cp -a "$SCRIPT_DIR/config/"* "$OPENCODE_DIR/config/" 2>/dev/null || true
ok "config/"

# Context
cp -a "$SCRIPT_DIR/context/"* "$OPENCODE_DIR/context/" 2>/dev/null || true
ok "context/ ($(find "$SCRIPT_DIR/context" -type f | wc -l) files)"

# Plugins
cp -a "$SCRIPT_DIR/plugins/"* "$OPENCODE_DIR/plugins/" 2>/dev/null || true
chmod +x "$OPENCODE_DIR/plugins/notify.ts" 2>/dev/null || true
ok "plugins/"

# Tools
cp -a "$SCRIPT_DIR/tools/"* "$OPENCODE_DIR/tools/" 2>/dev/null || true
ok "tools/"

# Dashboard (zero-dep web UI for agents/skills/config)
if [ -d "$SCRIPT_DIR/dashboard" ]; then
  cp -a "$SCRIPT_DIR/dashboard" "$OPENCODE_DIR/dashboard"
  chmod +x "$OPENCODE_DIR/dashboard/server.js" 2>/dev/null || true
  ok "dashboard/ → $OPENCODE_DIR/dashboard"
fi

# ── Copy Skills ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}[5/7] Installing skills...${RESET}"

# OpenCode skills (into ~/.config/opencode/skills/)
if [ -d "$SCRIPT_DIR/skills/opencode" ]; then
  cp -a "$SCRIPT_DIR/skills/opencode/"* "$OPENCODE_DIR/skills/" 2>/dev/null || true
  ok "OpenCode skills/ ($(ls "$SCRIPT_DIR/skills/opencode" | wc -l) dirs)"
fi

# NVIDIA skills (into ~/.agents/skills/)
if [ -d "$SCRIPT_DIR/skills/nvidia" ]; then
  cp -a "$SCRIPT_DIR/skills/nvidia/"* "$AGENTS_DIR/skills/" 2>/dev/null || true
  ok "NVIDIA skills/ ($(ls "$SCRIPT_DIR/skills/nvidia" | wc -l) dirs)"
fi

# Skill lock file
cp "$SCRIPT_DIR/skill-lock.json" "$AGENTS_DIR/.skill-lock.json"
ok "skill-lock.json → ~/.agents/.skill-lock.json"

# ── Install plugin dependencies (optional) ────────────────────
echo ""
echo -e "${BOLD}[6/7] Installing plugin dependencies...${RESET}"

if command -v bun &>/dev/null; then
  (cd "$OPENCODE_DIR" && bun install --no-save 2>/dev/null) && ok "bun install" || warn "bun install failed (non-critical)"
elif command -v npm &>/dev/null; then
  (cd "$OPENCODE_DIR" && npm install --no-save 2>/dev/null) && ok "npm install" || warn "npm install failed (non-critical)"
else
  warn "Skipping plugin deps (no bun or npm found)"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo -e "${BOLD}[7/7] Installation complete!${RESET}"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✅  OpenCode codedata installed!           ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Installed to:${RESET}"
echo -e "    📁 $OPENCODE_DIR"
echo -e "    📁 $AGENTS_DIR"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "    1. Create your .env file:"
echo -e "       ${CYAN}cp $OPENCODE_DIR/env.example $OPENCODE_DIR/.env${RESET}"
echo -e "    2. Edit .env with your real tokens"
echo -e "    3. Run ${CYAN}opencode${RESET} to start using your agents"
echo -e "    4. Launch the dashboard (optional):"
echo -e "       ${CYAN}node $OPENCODE_DIR/dashboard/server.js${RESET}"
echo -e "       → http://127.0.0.1:8877"
echo ""
