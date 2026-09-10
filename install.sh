#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# install.sh — OpenCode codedata installer v2.0.0
#
# Copies agents, skills (opencode + nvidia), plugins, commands,
# context, tools, dashboard, and opencode.jsonc into the correct
# locations for OpenCode to consume.
#
# Usage:
#   bash install.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   --dry-run          Print what would happen without modifying anything
#   --uninstall        Remove installed files (with backup)
#   --no-dashboard     Skip dashboard installation
#   --no-backup        Skip backup of existing configuration
#   --force            Overwrite without prompting
#   --prefix <dir>     Install into custom prefix (default: ~/.config/opencode)
#                      Agents always go to ~/.agents regardless of prefix
# ──────────────────────────────────────────────────────────────
set -euo pipefail

VERSION="2.0.0"

# ── Resolve script directory ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Defaults ──────────────────────────────────────────────────
OPENCODE_DIR="$HOME/.config/opencode"
AGENTS_DIR="$HOME/.agents"
DRY_RUN=false
UNINSTALL=false
SKIP_DASHBOARD=false
SKIP_BACKUP=false
FORCE=false

# ── Color detection ───────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  DIM='\033[2m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' CYAN='' BOLD='' DIM='' RESET=''
fi

# ── Log helpers ───────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}✔${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
err()  { echo -e "  ${RED}✘${RESET}  $*" >&2; }
info() { echo -e "  ${CYAN}ℹ${RESET}  $*"; }
dim()  { echo -e "  ${DIM}$*${RESET}"; }

# ── Usage ─────────────────────────────────────────────────────
usage() {
  cat <<EOF
OpenCode codedata installer v${VERSION}

Usage:
  bash install.sh [OPTIONS]

Options:
  -h, --help         Show this help message and exit
  --dry-run          Print what would happen without modifying anything
  --uninstall        Remove installed configuration (backs up first)
  --no-dashboard     Skip dashboard installation
  --no-backup        Skip backup of existing configuration
  --force            Overwrite existing files without prompting
  --prefix <dir>     Install opencode config into <dir> instead of
                     ~/.config/opencode. Agents always go to ~/.agents.

Examples:
  bash install.sh                      # Standard install
  bash install.sh --dry-run            # Preview what would happen
  bash install.sh --prefix /tmp/test   # Install to custom prefix
  bash install.sh --uninstall          # Back up and remove installed files
  bash install.sh --force              # Overwrite without confirmation
  bash install.sh --no-backup --force  # Fast reinstall (no backup, no prompts)

Environment variables:
  OPENCODE_PREFIX    Same as --prefix
EOF
}

# ── Parse arguments ───────────────────────────────────────────
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --uninstall)
        UNINSTALL=true
        shift
        ;;
      --no-dashboard)
        SKIP_DASHBOARD=true
        shift
        ;;
      --no-backup)
        SKIP_BACKUP=true
        shift
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --prefix)
        if [ -z "${2:-}" ]; then
          err "--prefix requires a directory argument"
          exit 1
        fi
        OPENCODE_DIR="$2"
        shift 2
        ;;
      *)
        # Check environment variable fallback
        if [ -n "${OPENCODE_PREFIX:-}" ]; then
          OPENCODE_DIR="$OPENCODE_PREFIX"
          shift
        else
          err "Unknown option: $1"
          usage >&2
          exit 1
        fi
        ;;
    esac
  done

  # Env var override for prefix
  if [ -n "${OPENCODE_PREFIX:-}" ] && [ "$OPENCODE_DIR" = "$HOME/.config/opencode" ]; then
    OPENCODE_DIR="$OPENCODE_PREFIX"
  fi
}

# ── Helpers ───────────────────────────────────────────────────
timestamp() { date +%Y%m%d-%H%M%S; }

file_count() {
  find "$1" -type f 2>/dev/null | wc -l | tr -d ' '
}

dir_count() {
  find "$1" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' '
}

# ── Backup directory ──────────────────────────────────────────
backup_dir() {
  local target="$1"
  if [ -d "$target" ]; then
    local backup="${target}.backup.$(timestamp)"
    if $DRY_RUN; then
      dim "Would back up: $target → $backup"
    else
      cp -a "$target" "$backup"
      ok "Backed up $target → $backup"
    fi
    return 0
  fi
  return 1
}

# ── Copy tree with counting ───────────────────────────────────
copy_tree() {
  local src="$1"
  local dst="$2"
  local label="${3:-}"

  if [ ! -d "$src" ]; then
    dim "Source not found: $src (skipping)"
    return 0
  fi

  local count
  count=$(file_count "$src")

  if $DRY_RUN; then
    dim "Would copy $count files: $src → $dst"
  else
    mkdir -p "$dst"
    cp -a "$src/"* "$dst/" 2>/dev/null || true
    ok "$label ($count files)" 2>/dev/null || ok "$label"
  fi
}

# ── Prompt for overwrite ──────────────────────────────────────
confirm_overwrite() {
  if $FORCE || $DRY_RUN; then
    return 0
  fi
  local target="$1"
  if [ -d "$target" ]; then
    echo -en "  ${YELLOW}?${RESET}  Target exists: $target — overwrite? [y/N] "
    read -r answer
    case "$answer" in
      [yY]|[yY][eE][sS]) return 0 ;;
      *) info "Skipping $target"; return 1 ;;
    esac
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════
# UNINSTALL
# ══════════════════════════════════════════════════════════════
do_uninstall() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║   OpenCode codedata — Uninstaller  v${VERSION}  ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
  echo ""

  local removed=0

  # ── [1/2] Backup ──
  echo -e "${BOLD}[1/2] Backing up before removal...${RESET}"
  local ts
  ts=$(timestamp)

  if $DRY_RUN; then
    [ -d "$OPENCODE_DIR" ] && dim "Would back up: $OPENCODE_DIR → ${OPENCODE_DIR}.uninstall-backup.${ts}"
    [ -d "$AGENTS_DIR" ]   && dim "Would back up: $AGENTS_DIR → ${AGENTS_DIR}.uninstall-backup.${ts}"
    [ -d "$OPENCODE_DIR" ] && ((removed++)) || true
    [ -d "$AGENTS_DIR" ]   && ((removed++)) || true
  else
    if [ -d "$OPENCODE_DIR" ]; then
      cp -a "$OPENCODE_DIR" "${OPENCODE_DIR}.uninstall-backup.${ts}"
      ok "Backed up opencode config → ${OPENCODE_DIR}.uninstall-backup.${ts}"
      ((removed++)) || true
    else
      info "No opencode dir to remove."
    fi
    if [ -d "$AGENTS_DIR" ]; then
      cp -a "$AGENTS_DIR" "${AGENTS_DIR}.uninstall-backup.${ts}"
      ok "Backed up agents dir → ${AGENTS_DIR}.uninstall-backup.${ts}"
      ((removed++)) || true
    else
      info "No agents dir to remove."
    fi
  fi

  # ── [2/2] Remove ──
  echo ""
  echo -e "${BOLD}[2/2] Removing installed directories...${RESET}"

  if $DRY_RUN; then
    [ -d "$OPENCODE_DIR" ] && dim "Would remove: $OPENCODE_DIR"
    [ -d "$AGENTS_DIR" ]   && dim "Would remove: $AGENTS_DIR"
  else
    if [ -d "$OPENCODE_DIR" ]; then
      rm -rf "$OPENCODE_DIR"
      ok "Removed $OPENCODE_DIR"
    fi
    if [ -d "$AGENTS_DIR" ]; then
      rm -rf "$AGENTS_DIR"
      ok "Removed $AGENTS_DIR"
    fi
  fi

  # ── Summary ──
  echo ""
  if $DRY_RUN; then
    echo -e "${BOLD}  Dry run complete — nothing was modified.${RESET}"
  elif [ "$removed" -gt 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║   Uninstall complete                        ║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}Backups saved (restore if needed):${RESET}"
    local oc_bak ag_bak
    oc_bak=$(ls -d "${OPENCODE_DIR}.uninstall-backup."* 2>/dev/null | tail -1 || true)
    ag_bak=$(ls -d "${AGENTS_DIR}.uninstall-backup."* 2>/dev/null | tail -1 || true)
    [ -n "$oc_bak" ] && dim "    $oc_bak"
    [ -n "$ag_bak" ] && dim "    $ag_bak"
  else
    info "Nothing to uninstall."
  fi
  echo ""
}

# ══════════════════════════════════════════════════════════════
# INSTALL
# ══════════════════════════════════════════════════════════════
do_install() {
  local total_steps=7

  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║   OpenCode codedata — Installer  v${VERSION}   ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
  $DRY_RUN && echo -e "  ${YELLOW}(dry-run mode — nothing will be modified)${RESET}"
  echo ""

  # ── [1/7] Check dependencies ──
  echo -e "${BOLD}[1/$total_steps] Checking dependencies...${RESET}"

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

  # ── [2/7] Backup ──
  echo ""
  echo -e "${BOLD}[2/$total_steps] Backing up existing configuration...${RESET}"

  if $SKIP_BACKUP; then
    info "Backup skipped (--no-backup)"
  else
    backup_dir "$OPENCODE_DIR" || info "No existing opencode dir to back up."
    backup_dir "$AGENTS_DIR"   || info "No existing agents dir to back up."
  fi

  # ── [3/7] Create target directories ──
  echo ""
  echo -e "${BOLD}[3/$total_steps] Creating target directories...${RESET}"

  if $DRY_RUN; then
    dim "Would create: $OPENCODE_DIR/{agents,commands,config,context,plugins,skills,tools}"
    dim "Would create: $AGENTS_DIR/skills"
  else
    mkdir -p "$OPENCODE_DIR"/{agents,commands,config,context,plugins,skills,tools}
    mkdir -p "$AGENTS_DIR/skills"
    ok "Target directories created"
  fi

  # ── [4/7] Install OpenCode config ──
  echo ""
  echo -e "${BOLD}[4/$total_steps] Installing OpenCode configuration...${RESET}"

  # Core config files
  if $DRY_RUN; then
    dim "Would copy: opencode.jsonc, env.example, package.json"
  else
    if confirm_overwrite "$OPENCODE_DIR/opencode.jsonc"; then
      cp "$SCRIPT_DIR/opencode.jsonc"  "$OPENCODE_DIR/opencode.jsonc"
      cp "$SCRIPT_DIR/env.example"     "$OPENCODE_DIR/env.example"
      cp "$SCRIPT_DIR/package.json"    "$OPENCODE_DIR/package.json"
      ok "opencode.jsonc, env.example, package.json"
    else
      warn "Core config files skipped."
    fi
  fi

  # Subdirectories
  for dir in agents commands config context plugins tools; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
      local count
      count=$(file_count "$SCRIPT_DIR/$dir")
      if $DRY_RUN; then
        dim "Would copy: $dir/ ($count files)"
      else
        cp -a "$SCRIPT_DIR/$dir/"* "$OPENCODE_DIR/$dir/" 2>/dev/null || true
        [ "$dir" = "plugins" ] && chmod +x "$OPENCODE_DIR/plugins/notify.ts" 2>/dev/null || true
        ok "$dir/ ($count files)"
      fi
    fi
  done

  # Dashboard
  if [ -d "$SCRIPT_DIR/dashboard" ]; then
    echo ""
    install_dashboard
  fi

  # ── [5/7] Install skills ──
  echo ""
  echo -e "${BOLD}[5/$total_steps] Installing skills...${RESET}"

  install_skills

  # ── [6/7] Plugin dependencies ──
  echo ""
  echo -e "${BOLD}[6/$total_steps] Installing plugin dependencies...${RESET}"

  if $DRY_RUN; then
    dim "Would run: bun install or npm install (if available)"
  else
    if command -v bun &>/dev/null; then
      (cd "$OPENCODE_DIR" && bun install --no-save 2>/dev/null) && ok "bun install" || warn "bun install failed (non-critical)"
    elif command -v npm &>/dev/null; then
      (cd "$OPENCODE_DIR" && npm install --no-save 2>/dev/null) && ok "npm install" || warn "npm install failed (non-critical)"
    else
      warn "Skipping plugin deps (no bun or npm found)"
    fi
  fi

  # ── [7/7] Verification ──
  echo ""
  echo -e "${BOLD}[7/$total_steps] Verifying installation...${RESET}"

  verify_install
}

# ── Install skills ────────────────────────────────────────────
install_skills() {
  # OpenCode skills (into opencode config dir)
  if [ -d "$SCRIPT_DIR/skills/opencode" ]; then
    local count
    count=$(dir_count "$SCRIPT_DIR/skills/opencode")
    if $DRY_RUN; then
      dim "Would copy: skills/opencode → $OPENCODE_DIR/skills/ ($count dirs)"
    else
      cp -a "$SCRIPT_DIR/skills/opencode/"* "$OPENCODE_DIR/skills/" 2>/dev/null || true
      ok "OpenCode skills ($count dirs) → $OPENCODE_DIR/skills/"
    fi
  fi

  # NVIDIA skills (into ~/.agents/skills/)
  if [ -d "$SCRIPT_DIR/skills/nvidia" ]; then
    local count
    count=$(dir_count "$SCRIPT_DIR/skills/nvidia")
    if $DRY_RUN; then
      dim "Would copy: skills/nvidia → $AGENTS_DIR/skills/ ($count dirs)"
    else
      cp -a "$SCRIPT_DIR/skills/nvidia/"* "$AGENTS_DIR/skills/" 2>/dev/null || true
      ok "NVIDIA skills ($count dirs) → $AGENTS_DIR/skills/"
    fi
  fi

  # Skill lock file
  if [ -f "$SCRIPT_DIR/skill-lock.json" ]; then
    if $DRY_RUN; then
      dim "Would copy: skill-lock.json → $AGENTS_DIR/.skill-lock.json"
    else
      cp "$SCRIPT_DIR/skill-lock.json" "$AGENTS_DIR/.skill-lock.json"
      ok "skill-lock.json → $AGENTS_DIR/.skill-lock.json"
    fi
  fi
}

# ── Install dashboard ─────────────────────────────────────────
install_dashboard() {
  echo -e "${BOLD}Installing dashboard...${RESET}"
  if $SKIP_DASHBOARD; then
    info "Dashboard skipped (--no-dashboard)"
    return 0
  fi

  if $DRY_RUN; then
    dim "Would copy: dashboard/ → $OPENCODE_DIR/dashboard"
  else
    cp -a "$SCRIPT_DIR/dashboard" "$OPENCODE_DIR/dashboard"
    chmod +x "$OPENCODE_DIR/dashboard/server.js" 2>/dev/null || true
    ok "dashboard/ → $OPENCODE_DIR/dashboard"
  fi
}

# ── Verify installation ──────────────────────────────────────
verify_install() {
  local warnings=0

  if $DRY_RUN; then
    dim "Verification skipped (dry-run)"
    return 0
  fi

  # Check opencode.jsonc
  if [ -f "$OPENCODE_DIR/opencode.jsonc" ]; then
    ok "opencode.jsonc present"
  else
    warn "opencode.jsonc MISSING"
    ((warnings++)) || true
  fi

  # Count agents
  local agent_count=0
  if [ -d "$OPENCODE_DIR/agents" ]; then
    agent_count=$(file_count "$OPENCODE_DIR/agents")
    if [ "$agent_count" -gt 0 ]; then
      ok "Agents: $agent_count files installed"
    else
      warn "Agents directory is empty"
      ((warnings++)) || true
    fi
  else
    warn "Agents directory missing"
    ((warnings++)) || true
  fi

  # Count skills
  local skill_count=0
  if [ -d "$OPENCODE_DIR/skills" ]; then
    skill_count=$(dir_count "$OPENCODE_DIR/skills")
    ok "Skills: $skill_count dirs installed"
  fi

  # Check dashboard
  if [ -d "$OPENCODE_DIR/dashboard" ] && [ -f "$OPENCODE_DIR/dashboard/server.js" ]; then
    ok "Dashboard present (server.js)"
  elif [ "$SKIP_DASHBOARD" = false ]; then
    warn "Dashboard not found (server.js missing)"
    ((warnings++)) || true
  fi

  # Check env.example
  if [ -f "$OPENCODE_DIR/env.example" ]; then
    ok "env.example present"
  else
    warn "env.example missing"
    ((warnings++)) || true
  fi

  # Print warnings summary
  if [ "$warnings" -gt 0 ]; then
    echo ""
    warn "$warnings issue(s) detected — review above output"
  fi
}

# ══════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════
main() {
  parse_args "$@"

  if $UNINSTALL; then
    do_uninstall
    exit 0
  fi

  do_install

  # ── Final summary box ──
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${GREEN}║   ✅  OpenCode codedata installed!           ║${RESET}"
  echo -e "${GREEN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${BOLD}Installed locations:${RESET}"
  echo -e "    📁 opencode config : $OPENCODE_DIR"
  echo -e "    📁 agents/skills   : $AGENTS_DIR"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo -e "    1. Create your .env file:"
  echo -e "       ${CYAN}cp $OPENCODE_DIR/env.example $OPENCODE_DIR/.env${RESET}"
  echo -e "    2. Edit .env with your real tokens"
  echo -e "    3. Run ${CYAN}opencode${RESET} to start using your agents"
  if [ -d "$OPENCODE_DIR/dashboard" ] && [ "$SKIP_DASHBOARD" = false ]; then
    echo -e "    4. Launch the dashboard (optional):"
    echo -e "       ${CYAN}node $OPENCODE_DIR/dashboard/server.js${RESET}"
    echo -e "       → http://127.0.0.1:8877"
  fi
  echo ""
}

main "$@"
