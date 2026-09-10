#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# install.sh — OpenCode codedata installer v2.1.0
#
# Copies agents, skills (opencode + nvidia), plugins, commands,
# context, tools, dashboard, and opencode.jsonc into the correct
# locations for OpenCode to consume.
#
# Usage:
#   bash install.sh [OPTIONS]
#
# Options:
#   -h, --help              Show this help message
#   -i, --interactive       Force interactive menu (even with flags)
#   --dry-run               Print what would happen without modifying anything
#   --mode <mode>           Force mode: full | update | uninstall | preview
#   --uninstall             Remove installed files (with backup)
#   --components <a,b,c>    Component subset (agents,skills,commands,
#                           context,config,plugins,tools,dashboard,plugindeps)
#   --no-dashboard          Skip dashboard installation
#   --no-backup             Skip backup of existing configuration
#   --force                 Overwrite without prompting
#   --prefix <dir>          Install into custom prefix (default: ~/.config/opencode)
#                           Agents always go to ~/.agents regardless of prefix
# ──────────────────────────────────────────────────────────────
set -euo pipefail

VERSION="2.1.0"

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
INTERACTIVE=false
MODE=""                    # full | update | uninstall | preview | ""

# Component flags (true = install, false = skip)
COMP_AGENTS=true
COMP_SKILLS=true
COMP_COMMANDS=true
COMP_CONTEXT=true
COMP_CONFIG=true
COMP_PLUGINS=true
COMP_TOOLS=true
COMP_DASHBOARD=true
COMP_PLUGINDEPS=true

# Track whether user explicitly selected components
COMPONENTS_EXPLICIT=false

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
  -h, --help              Show this help message and exit
  -i, --interactive       Force interactive menu even with other flags
  --dry-run               Print what would happen without modifying anything
  --mode <mode>           Force a mode non-interactively:
                            full      — fresh install, overwrite existing
                            update    — merge missing components only
                            uninstall — back up then remove installed dirs
                            preview   — same as --dry-run
  --uninstall             Remove installed configuration (backs up first)
  --components <list>     Comma-separated component subset to install.
                          Valid: agents,skills,commands,context,config,
                                 plugins,tools,dashboard,plugindeps
  --no-dashboard          Skip dashboard installation
  --no-backup             Skip backup of existing configuration
  --force                 Overwrite existing files without prompting
  --prefix <dir>          Install opencode config into <dir> instead of
                          ~/.config/opencode. Agents always go to ~/.agents.

Interactive mode:
  When run in a terminal without any mode-determining flag, an interactive
  menu is shown. Use --interactive / -i to force the menu even when flags
  are present. Outside a TTY with no flags, defaults to full install.

Examples:
  bash install.sh                              # Interactive menu (if TTY)
  bash install.sh --dry-run                    # Preview what would happen
  bash install.sh --mode update                # Merge-only install
  bash install.sh --mode full --force          # Overwrite everything
  bash install.sh --components agents,skills   # Install only agents & skills
  bash install.sh --prefix /tmp/test           # Install to custom prefix
  bash install.sh --uninstall                  # Back up and remove
  bash install.sh -i --force                   # Menu, then force overwrite

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
      -i|--interactive)
        INTERACTIVE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --mode)
        if [ -z "${2:-}" ]; then
          err "--mode requires an argument: full, update, uninstall, or preview"
          exit 1
        fi
        case "$2" in
          full|update|uninstall|preview) MODE="$2" ;;
          *) err "Invalid mode: $2 (expected: full, update, uninstall, preview)"; exit 1 ;;
        esac
        shift 2
        ;;
      --uninstall)
        UNINSTALL=true
        shift
        ;;
      --components)
        if [ -z "${2:-}" ]; then
          err "--components requires a comma-separated list"
          exit 1
        fi
        set_components "$2"
        shift 2
        ;;
      --no-dashboard)
        SKIP_DASHBOARD=true
        COMP_DASHBOARD=false
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

# ── Set components from comma-separated list ──────────────────
set_components() {
  local list="$1"
  # Disable all first
  COMP_AGENTS=false
  COMP_SKILLS=false
  COMP_COMMANDS=false
  COMP_CONTEXT=false
  COMP_CONFIG=false
  COMP_PLUGINS=false
  COMP_TOOLS=false
  COMP_DASHBOARD=false
  COMP_PLUGINDEPS=false

  local IFS=','
  for comp in $list; do
    comp=$(echo "$comp" | tr -d ' ')
    case "$comp" in
      agents)     COMP_AGENTS=true ;;
      skills)     COMP_SKILLS=true ;;
      commands)   COMP_COMMANDS=true ;;
      context)    COMP_CONTEXT=true ;;
      config)     COMP_CONFIG=true ;;
      plugins)    COMP_PLUGINS=true ;;
      tools)      COMP_TOOLS=true ;;
      dashboard)  COMP_DASHBOARD=true ;;
      plugindeps) COMP_PLUGINDEPS=true ;;
      all)        set_all_components true ;;
      *)          warn "Unknown component: $comp (skipped)" ;;
    esac
  done
  COMPONENTS_EXPLICIT=true
}

# ── Enable/disable all components ─────────────────────────────
set_all_components() {
  local val="$1"
  COMP_AGENTS="$val"
  COMP_SKILLS="$val"
  COMP_COMMANDS="$val"
  COMP_CONTEXT="$val"
  COMP_CONFIG="$val"
  COMP_PLUGINS="$val"
  COMP_TOOLS="$val"
  COMP_DASHBOARD="$val"
  COMP_PLUGINDEPS="$val"
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

# ── No-clobber copy (for update mode) ────────────────────────
copy_merge() {
  local src="$1"
  local dst="$2"

  mkdir -p "$dst"
  # Try cp -n first (GNU & BSD both support it)
  if cp -r -n "$src/." "$dst/" 2>/dev/null; then
    return 0
  fi
  # Fallback to rsync if cp -n fails
  if command -v rsync &>/dev/null; then
    rsync -a --ignore-existing "$src/" "$dst/"
    return 0
  fi
  warn "No-clobber copy not supported on this platform. Falling back to overwrite."
  cp -a "$src/"* "$dst/" 2>/dev/null || true
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
  elif [ "$MODE" = "update" ]; then
    copy_merge "$src" "$dst"
    ok "$label ($count files, merge-only)" 2>/dev/null || ok "$label"
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
# INTERACTIVE MENU
# ══════════════════════════════════════════════════════════════
show_menu() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║   OpenCode codedata — Installer  v${VERSION}   ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${BOLD}What would you like to do?${RESET}"
  echo ""
  echo -e "    ${CYAN}[1]${RESET}  Full install    — fresh install of ALL components"
  echo -e "                         (existing config backed up first)"
  echo -e "    ${CYAN}[2]${RESET}  Update          — merge: add missing components,"
  echo -e "                         NEVER overwrite existing user files"
  echo -e "    ${CYAN}[3]${RESET}  Uninstall       — backup then remove installed dirs"
  echo -e "    ${CYAN}[4]${RESET}  Preview         — dry-run of a full install"
  echo -e "    ${CYAN}[5]${RESET}  Help            — show usage"
  echo -e "    ${CYAN}[0]${RESET}  Exit"
  echo ""
}

# ── Component selection checklist ─────────────────────────────
# Reads user choices for each component. Sets COMP_* variables.
# Default is Y (install). Typing n skips. "all" sets all to Y, "quit" aborts.
# Components are processed sequentially; "all" short-circuits the rest.
select_components() {
  local mode_label="$1"  # "install" or "update"
  echo ""
  echo -e "  ${BOLD}Select components to ${mode_label}:${RESET}"
  echo -e "  ${DIM}(Enter = keep default, y = include, n = skip, all = all, quit = abort)${RESET}"
  echo ""

  # Pick a component; handles all/quit shortcuts and y/n toggles.
  # $1 = label, $2 = variable name to toggle
  pick_comp() {
    local name="$1"
    local var="$2"
    echo -en "  ${name} [Y/n] "
    local choice
    read -r choice </dev/tty || choice=""
    case "$choice" in
      all)  set_all_components true
            echo "    → All components selected"
            COMPONENTS_EXPLICIT=true
            return 3 ;;
      quit) return 2 ;;
      n|N)  eval "$var=false" ;;
      y|Y)  eval "$var=true" ;;
    esac
    return 0
  }

  local rc
  pick_comp "agents"      COMP_AGENTS;      rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 2 ] && return 2
  pick_comp "skills"      COMP_SKILLS;      rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 2 ] && return 2
  pick_comp "commands"    COMP_COMMANDS;    rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 2 ] && return 2
  pick_comp "context"     COMP_CONTEXT;     rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 2 ] && return 2
  pick_comp "config"      COMP_CONFIG;      rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 2 ] && return 2
  pick_comp "plugins"     COMP_PLUGINS;     rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 2 ] && return 2
  pick_comp "tools"       COMP_TOOLS;       rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 2 ] && return 2
  pick_comp "dashboard"   COMP_DASHBOARD;   rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 2 ] && return 2
  pick_comp "plugin deps" COMP_PLUGINDEPS;  rc=$?; [ "$rc" -eq 3 ] && return 0; [ "$rc" -eq 2 ] && return 2

  COMPONENTS_EXPLICIT=true
  return 0
}

# ── Show selected components summary ──────────────────────────
show_components_summary() {
  echo ""
  echo -e "  ${BOLD}Selected components:${RESET}"
  $COMP_AGENTS    && ok "agents"      || dim "agents      — skipped"
  $COMP_SKILLS    && ok "skills"      || dim "skills      — skipped"
  $COMP_COMMANDS  && ok "commands"    || dim "commands    — skipped"
  $COMP_CONTEXT   && ok "context"     || dim "context     — skipped"
  $COMP_CONFIG    && ok "config"      || dim "config      — skipped"
  $COMP_PLUGINS   && ok "plugins"     || dim "plugins     — skipped"
  $COMP_TOOLS     && ok "tools"       || dim "tools       — skipped"
  $COMP_DASHBOARD && ok "dashboard"   || dim "dashboard   — skipped"
  $COMP_PLUGINDEPS && ok "plugin deps" || dim "plugin deps — skipped"
  echo ""
}

# ── Confirm before proceeding ─────────────────────────────────
confirm_proceed() {
  if $FORCE || $DRY_RUN; then
    return 0
  fi
  echo -en "  ${BOLD}Proceed? [Y/n]${RESET} "
  read -r answer </dev/tty || answer=""
  case "$answer" in
    n|N) info "Aborted by user."; exit 0 ;;
    *)   return 0 ;;
  esac
}

# ── Run interactive flow ──────────────────────────────────────
run_interactive() {
  show_menu

  local choice
  echo -en "  ${BOLD}Select [0-5]:${RESET} "
  read -r choice </dev/tty || choice="0"

  case "$choice" in
    1)
      # Full install — ask component selection
      set_all_components true
      local sel_rc=0
      select_components "install" || sel_rc=$?
      if [ "$sel_rc" -eq 2 ]; then
        info "Aborted by user."
        exit 0
      fi
      show_components_summary
      confirm_proceed
      do_install
      ;;
    2)
      # Update — ask component selection
      MODE="update"
      set_all_components true
      local sel_rc=0
      select_components "update" || sel_rc=$?
      if [ "$sel_rc" -eq 2 ]; then
        info "Aborted by user."
        exit 0
      fi
      show_components_summary
      confirm_proceed
      do_install
      ;;
    3)
      # Uninstall
      confirm_proceed
      do_uninstall
      exit 0
      ;;
    4)
      # Preview
      DRY_RUN=true
      set_all_components true
      do_install
      ;;
    5)
      usage
      exit 0
      ;;
    0|*)
      info "Exiting."
      exit 0
      ;;
  esac
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
  local mode_label="Install"
  if [ "$MODE" = "update" ]; then
    mode_label="Update (merge-only)"
  fi

  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║   OpenCode codedata — ${mode_label}  v${VERSION}   ║${RESET}"
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

  # Core config files (gated by COMP_CONFIG)
  if $COMP_CONFIG; then
    if $DRY_RUN; then
      dim "Would copy: opencode.jsonc, env.example, package.json"
    elif [ "$MODE" = "update" ]; then
      # Update mode: never overwrite existing config files
      for f in opencode.jsonc env.example package.json; do
        if [ -f "$SCRIPT_DIR/$f" ]; then
          if [ -f "$OPENCODE_DIR/$f" ]; then
            dim "Skipping $f (already exists)"
          else
            cp "$SCRIPT_DIR/$f" "$OPENCODE_DIR/$f"
            ok "$f (new)"
          fi
        fi
      done
    else
      # Full install
      if confirm_overwrite "$OPENCODE_DIR/opencode.jsonc"; then
        cp "$SCRIPT_DIR/opencode.jsonc"  "$OPENCODE_DIR/opencode.jsonc"
        cp "$SCRIPT_DIR/env.example"     "$OPENCODE_DIR/env.example"
        cp "$SCRIPT_DIR/package.json"    "$OPENCODE_DIR/package.json"
        ok "opencode.jsonc, env.example, package.json"
      else
        warn "Core config files skipped."
      fi
    fi
  else
    info "Config skipped (not selected)"
  fi

  # Subdirectories — gated by individual component flags
  for dir in agents commands config context plugins tools; do
    local comp_flag
    case "$dir" in
      agents)   comp_flag=$COMP_AGENTS ;;
      commands) comp_flag=$COMP_COMMANDS ;;
      config)   comp_flag=$COMP_CONFIG ;;
      context)  comp_flag=$COMP_CONTEXT ;;
      plugins)  comp_flag=$COMP_PLUGINS ;;
      tools)    comp_flag=$COMP_TOOLS ;;
    esac

    if $comp_flag && [ -d "$SCRIPT_DIR/$dir" ]; then
      local count
      count=$(file_count "$SCRIPT_DIR/$dir")
      if $DRY_RUN; then
        dim "Would copy: $dir/ ($count files)"
      else
        if [ "$MODE" = "update" ]; then
          copy_merge "$SCRIPT_DIR/$dir" "$OPENCODE_DIR/$dir"
        else
          cp -a "$SCRIPT_DIR/$dir/"* "$OPENCODE_DIR/$dir/" 2>/dev/null || true
        fi
        [ "$dir" = "plugins" ] && chmod +x "$OPENCODE_DIR/plugins/notify.ts" 2>/dev/null || true
        ok "$dir/ ($count files)"
      fi
    elif ! $comp_flag; then
      dim "$dir/ — skipped (not selected)"
    fi
  done

  # Dashboard (gated by COMP_DASHBOARD)
  if $COMP_DASHBOARD && [ -d "$SCRIPT_DIR/dashboard" ]; then
    echo ""
    install_dashboard
  elif ! $COMP_DASHBOARD; then
    dim "dashboard/ — skipped (not selected)"
  fi

  # ── [5/7] Install skills ──
  echo ""
  echo -e "${BOLD}[5/$total_steps] Installing skills...${RESET}"

  if $COMP_SKILLS; then
    install_skills
  else
    info "Skills skipped (not selected)"
  fi

  # ── [6/7] Plugin dependencies ──
  echo ""
  echo -e "${BOLD}[6/$total_steps] Installing plugin dependencies...${RESET}"

  if $COMP_PLUGINDEPS; then
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
  else
    info "Plugin deps skipped (not selected)"
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
    elif [ "$MODE" = "update" ]; then
      copy_merge "$SCRIPT_DIR/skills/opencode" "$OPENCODE_DIR/skills"
      ok "OpenCode skills ($count dirs, merge-only)"
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
    elif [ "$MODE" = "update" ]; then
      copy_merge "$SCRIPT_DIR/skills/nvidia" "$AGENTS_DIR/skills"
      ok "NVIDIA skills ($count dirs, merge-only)"
    else
      cp -a "$SCRIPT_DIR/skills/nvidia/"* "$AGENTS_DIR/skills/" 2>/dev/null || true
      ok "NVIDIA skills ($count dirs) → $AGENTS_DIR/skills/"
    fi
  fi

  # Skill lock file
  if [ -f "$SCRIPT_DIR/skill-lock.json" ]; then
    if $DRY_RUN; then
      dim "Would copy: skill-lock.json → $AGENTS_DIR/.skill-lock.json"
    elif [ "$MODE" = "update" ]; then
      if [ -f "$AGENTS_DIR/.skill-lock.json" ]; then
        dim "Skipping skill-lock.json (already exists)"
      else
        cp "$SCRIPT_DIR/skill-lock.json" "$AGENTS_DIR/.skill-lock.json"
        ok "skill-lock.json → $AGENTS_DIR/.skill-lock.json"
      fi
    else
      cp "$SCRIPT_DIR/skill-lock.json" "$AGENTS_DIR/.skill-lock.json"
      ok "skill-lock.json → $AGENTS_DIR/.skill-lock.json"
    fi
  fi
}

# ── Install dashboard ─────────────────────────────────────────
install_dashboard() {
  echo -e "${BOLD}Installing dashboard...${RESET}"
  if $SKIP_DASHBOARD || ! $COMP_DASHBOARD; then
    info "Dashboard skipped"
    return 0
  fi

  if $DRY_RUN; then
    dim "Would copy: dashboard/ → $OPENCODE_DIR/dashboard"
  elif [ "$MODE" = "update" ]; then
    if [ -d "$OPENCODE_DIR/dashboard" ]; then
      dim "Skipping dashboard/ (already exists)"
    else
      cp -a "$SCRIPT_DIR/dashboard" "$OPENCODE_DIR/dashboard"
      chmod +x "$OPENCODE_DIR/dashboard/server.js" 2>/dev/null || true
      ok "dashboard/ → $OPENCODE_DIR/dashboard (new)"
    fi
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
  elif [ "$COMP_DASHBOARD" = true ] && [ "$SKIP_DASHBOARD" = false ]; then
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

  # ── Determine if we should run interactively ──
  # Interactive when: stdin is TTY AND (--interactive OR no mode-determining flag)
  if [ -t 0 ] && { $INTERACTIVE || { [ -z "$MODE" ] && ! $UNINSTALL && ! $DRY_RUN && ! $COMPONENTS_EXPLICIT; }; }; then
    run_interactive
    # run_interactive calls do_install/do_uninstall directly
    # Print final summary only for install (not uninstall which has its own)
    if [ "$MODE" != "uninstall" ] && ! $UNINSTALL; then
      show_final_summary
    fi
    return 0
  fi

  # ── Non-interactive path ──
  # If not a TTY and no flags, default to full install with a note
  if [ ! -t 0 ] && [ -z "$MODE" ] && ! $UNINSTALL && ! $DRY_RUN && ! $COMPONENTS_EXPLICIT; then
    info "Non-interactive mode: defaulting to full install."
    info "Run with --interactive for a menu."
    echo ""
  fi

  # Resolve mode from legacy flags
  if $UNINSTALL && [ -z "$MODE" ]; then
    MODE="uninstall"
  elif $DRY_RUN && [ -z "$MODE" ]; then
    MODE="preview"
  elif [ -z "$MODE" ]; then
    MODE="full"
  fi

  # Map preview mode to dry-run
  if [ "$MODE" = "preview" ]; then
    DRY_RUN=true
  fi

  # Execute the mode
  case "$MODE" in
    uninstall)
      do_uninstall
      ;;
    full|update)
      do_install
      show_final_summary
      ;;
    preview)
      DRY_RUN=true
      do_install
      ;;
  esac
}

# ── Final summary box ─────────────────────────────────────────
show_final_summary() {
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
  if $COMP_DASHBOARD && [ -d "$OPENCODE_DIR/dashboard" ] && [ "$SKIP_DASHBOARD" = false ]; then
    echo -e "    4. Launch the dashboard (optional):"
    echo -e "       ${CYAN}node $OPENCODE_DIR/dashboard/server.js${RESET}"
    echo -e "       → http://127.0.0.1:8877"
  fi
  echo ""
}

main "$@"
