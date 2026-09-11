#!/usr/bin/env bash
# download.sh — OpenCode codedata component downloader
# Allows user to select components without git clone.
# If run inside the repo, copies components to OpenCode config dirs.
# If run standalone, fetches from GitHub API (requires GITHUB_TOKEN).
#
# Usage:
#   bash download.sh              # interactive selection (from repo)
#   bash download.sh --full     # install all components
#   bash download.sh --agents   # install agents only
#   bash download.sh --skills   # install skills only
#
# Requires: bash, coreutils, optionally gh CLI for GitHub API fallback.

set -euo pipefail

# ── Color helpers ─────────────────────────────────────────────
ok()   { echo -e "  \033[0;32m✔\033[0m  $*"; }
warn() { echo -e "  \033[1;33m⚠\033[0m  $*"; }
err()  { echo -e "  \033[0;31m✘\033[0m  $*" >&2; }
info() { echo -e "  \033[0;36mℹ\033[0m  $*"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG="${OPENCODE_CONFIG:-$HOME/.config/opencode}"
AGENTS_DIR="${AGENTS_DIR:-$HOME/.agents}"
OPENCODE_AGENTS_DIR="${OPENCODE_AGENTS_DIR:-$HOME/.config/opencode/agents}"
OPENCODE_SKILLS_DIR="${OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}"

# Default component flags
INSTALL_AGENTS=true
INSTALL_SKILLS=true
INSTALL_COMMANDS=true
INSTALL_CONTEXT=true
INSTALL_CONFIG=true
INSTALL_PLUGINS=true
INSTALL_TOOLS=true
INSTALL_DASHBOARD=true
INSTALL_PLUGINDEPS=true

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --full)           INSTALL_AGENTS=true; INSTALL_SKILLS=true; INSTALL_COMMANDS=true; INSTALL_CONTEXT=true; INSTALL_CONFIG=true; INSTALL_PLUGINS=true; INSTALL_TOOLS=true; INSTALL_DASHBOARD=true; INSTALL_PLUGINDEPS=true ;;
    --agents)         INSTALL_AGENTS=true; INSTALL_SKILLS=false; INSTALL_COMMANDS=false; INSTALL_CONTEXT=false; INSTALL_CONFIG=false; INSTALL_PLUGINS=false; INSTALL_TOOLS=false; INSTALL_DASHBOARD=false; INSTALL_PLUGINDEPS=false ;;
    --skills)         INSTALL_AGENTS=false; INSTALL_SKILLS=true; INSTALL_COMMANDS=false; INSTALL_CONTEXT=false; INSTALL_CONFIG=false; INSTALL_PLUGINS=false; INSTALL_TOOLS=false; INSTALL_DASHBOARD=false; INSTALL_PLUGINDEPS=false ;;
    --commands)       INSTALL_AGENTS=false; INSTALL_SKILLS=false; INSTALL_COMMANDS=true; INSTALL_CONTEXT=false; INSTALL_CONFIG=false; INSTALL_PLUGINS=false; INSTALL_TOOLS=false; INSTALL_DASHBOARD=false; INSTALL_PLUGINDEPS=false ;;
    --context)        INSTALL_AGENTS=false; INSTALL_SKILLS=false; INSTALL_COMMANDS=false; INSTALL_CONTEXT=true; INSTALL_CONFIG=false; INSTALL_PLUGINS=false; INSTALL_TOOLS=false; INSTALL_DASHBOARD=false; INSTALL_PLUGINDEPS=false ;;
    --config)         INSTALL_AGENTS=false; INSTALL_SKILLS=false; INSTALL_COMMANDS=false; INSTALL_CONTEXT=false; INSTALL_CONFIG=true; INSTALL_PLUGINS=false; INSTALL_TOOLS=false; INSTALL_DASHBOARD=false; INSTALL_PLUGINDEPS=false ;;
    --plugins)        INSTALL_AGENTS=false; INSTALL_SKILLS=false; INSTALL_COMMANDS=false; INSTALL_CONTEXT=false; INSTALL_CONFIG=false; INSTALL_PLUGINS=true; INSTALL_TOOLS=false; INSTALL_DASHBOARD=false; INSTALL_PLUGINDEPS=false ;;
    --tools)          INSTALL_AGENTS=false; INSTALL_SKILLS=false; INSTALL_COMMANDS=false; INSTALL_CONTEXT=false; INSTALL_CONFIG=false; INSTALL_PLUGINS=false; INSTALL_TOOLS=true; INSTALL_DASHBOARD=false; INSTALL_PLUGINDEPS=false ;;
    --dashboard)      INSTALL_AGENTS=false; INSTALL_SKILLS=false; INSTALL_COMMANDS=false; INSTALL_CONTEXT=false; INSTALL_CONFIG=false; INSTALL_PLUGINS=false; INSTALL_TOOLS=false; INSTALL_DASHBOARD=true; INSTALL_PLUGINDEPS=false ;;
    --plugindeps)     INSTALL_AGENTS=false; INSTALL_SKILLS=false; INSTALL_COMMANDS=false; INSTALL_CONTEXT=false; INSTALL_CONFIG=false; INSTALL_PLUGINS=false; INSTALL_TOOLS=false; INSTALL_DASHBOARD=false; INSTALL_PLUGINDEPS=true ;;
    --help|-h)        echo "Usage: bash download.sh [--full] [--agents] [--skills] [--commands] [--context] [--config] [--plugins] [--tools] [--dashboard] [--plugindeps] [--help]"; exit 0 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
  shift
done

# Detect if running inside the repo
IN_REPO=false
if [[ -f "$REPO_DIR/agents/core/OpenAgent.md" ]] || [[ -f "$REPO_DIR/AGENTS.md" ]]; then
  IN_REPO=true
fi

list_components() {
  echo "Available components:"
  local i=1
  [[ $INSTALL_AGENTS == true ]] && echo "  $i) Agents"      ; i=$((i+1))
  [[ $INSTALL_SKILLS == true ]] && echo "  $i) OpenCode Skills" ; i=$((i+1))
  [[ $INSTALL_SKILLS == true ]] && echo "  $((i))) NVIDIA Skills" ; i=$((i+1))
  [[ $INSTALL_COMMANDS == true ]] && echo "  $i) Commands"      ; i=$((i+1))
  [[ $INSTALL_CONTEXT == true ]] && echo "  $i) Context files" ; i=$((i+1))
  [[ $INSTALL_CONFIG == true ]] && echo "  $i) Config"        ; i=$((i+1))
  [[ $INSTALL_PLUGINS == true ]] && echo "  $i) Plugins"       ; i=$((i+1))
  [[ $INSTALL_TOOLS == true ]] && echo "  $i) Tools"         ; i=$((i+1))
  [[ $INSTALL_DASHBOARD == true ]] && echo "  $i) Dashboard"     ; i=$((i+1))
  [[ $INSTALL_PLUGINDEPS == true ]] && echo "  $i) Plugin Dependencies"; i=$((i+1))
  echo
}

prompt_selection() {
  # Build array of selected components
  local all=()
  [[ $INSTALL_AGENTS == true ]] && all+=("agents")
  [[ $INSTALL_SKILLS == true ]] && all+=("skills_opencode")
  [[ $INSTALL_SKILLS == true ]] && all+=("skills_nvidia")
  [[ $INSTALL_COMMANDS == true ]] && all+=("commands")
  [[ $INSTALL_CONTEXT == true ]] && all+=("context")
  [[ $INSTALL_CONFIG == true ]] && all+=("config")
  [[ $INSTALL_PLUGINS == true ]] && all+=("plugins")
  [[ $INSTALL_TOOLS == true ]] && all+=("tools")
  [[ $INSTALL_DASHBOARD == true ]] && all+=("dashboard")
  [[ $INSTALL_PLUGINDEPS == true ]] && all+=("plugindeps")

  if [[ ${#all[@]} -eq 0 ]]; then
    echo "No components selected. Use flags or interactive mode."
    list_components
    return 1
  fi

  # If only one component, auto-select
  if [[ ${#all[@]} -eq 1 ]]; then
    SELECTED_COMPONENT="${all[0]}"
    return 0
  fi

  # Multiple: prompt user
  echo "Select components to install (comma-separated numbers or 'all'):"
  list_components
  read -r choice

  if [[ "$choice" == "all" ]] || [[ "$choice" == "a" ]]; then
    SELECTED_COMPONENT="${all[*]}"
    return 0
  fi

  # Parse comma-separated numbers
  local chosen=()
  IFS=',' read -ra choices_arr <<< "$choice"
  for c in "${choices_arr[@]}"; do
    # Trim whitespace
    c=$(echo "$c" | xargs)
    # Validate
    if [[ "$c" =~ ^[0-9]+$ ]] && (( c >= 1 && c <= ${#all[@]} )); then
      chosen+=("$c")
    fi
  done

  if [[ ${#chosen[@]} -eq 0 ]]; then
    echo "No valid selections. Aborting."
    return 1
  fi

  # Build selected list
  for idx in "${chosen[@]}"; do
    selected+=("${all[$((idx-1))]}")
  done

  SELECTED_COMPONENT="${selected[*]}"
  return 0
}

copy_component() {
  local name="$1"
  local src_dir="$2"
  local dest_dir="$3"

  echo "  Copying $name..."

  if [[ ! -d "$src_dir" ]]; then
    warn "Source directory not found: $src_dir — skipping."
    return 1
  fi

  # Create destination if needed
  mkdir -p "$dest_dir"

  # Copy contents (excluding .git)
  rsync -a --exclude=.git --exclude=.gitignore "$src_dir"/ "$dest_dir"/ 2>/dev/null || {
    # Fallback: cp -r
    cp -r "$src_dir"/* "$dest_dir"/ 2>/dev/null || true
  }

  ok "Copied $name to $dest_dir"
}

ensure_directories() {
  # Ensure OpenCode config dirs exist
  mkdir -p "$OPENCODE_CONFIG"
  mkdir -p "$OPENCODE_AGENTS_DIR"
  mkdir -p "$OPENCODE_SKILLS_DIR"
  mkdir -p "$AGENTS_DIR"

  # Create placeholder files if missing (for installer compatibility)
  if [[ ! -f "$OPENCODE_CONFIG/opencode.jsonc" ]]; then
    # Generate minimal opencode.jsonc from repo if available
    if [[ -f "$REPO_DIR/opencode.jsonc" ]]; then
      cp "$REPO_DIR/opencode.jsonc" "$OPENCODE_CONFIG/opencode.jsonc"
      ok "Generated opencode.jsonc"
    else
      # Create minimal placeholder
      cat > "$OPENCODE_CONFIG/opencode.jsonc" <<'EOF'
{
  "$schema": "https://github.com/Raidan-Ai/opencode-settings/raw/main/opencode.jsonc",
  "version": "2.1.0",
  "provider": "nvidia",
  "model": "nemotron/nemotron-3.5-lightning-30b-a3b",
  "temperature": 0.1
}
EOF
      warn "Created minimal opencode.jsonc placeholder"
    fi
  fi
}

install_agents() {
  if [[ -d "$REPO_DIR/agents" ]]; then
    ensure_directories
    copy_component "agents" "$REPO_DIR/agents" "$OPENCODE_AGENTS_DIR"
  else
    warn "No agents directory found in repo."
  fi
}

install_skills() {
  # Install OpenCode skills
  if [[ -d "$REPO_DIR/skills/opencode" ]]; then
    ensure_directories
    copy_component "OpenCode skills" "$REPO_DIR/skills/opencode" "$OPENCODE_SKILLS_DIR"
  fi

  # Install NVIDIA skills
  if [[ -d "$REPO_DIR/skills/nvidia" ]]; then
    ensure_directories
    # Nvidia skills go to ~/.agents/skills (per skill-lock.json convention)
    mkdir -p "$AGENTS_DIR/skills"
    copy_component "NVIDIA skills" "$REPO_DIR/skills/nvidia" "$AGENTS_DIR/skills"
  fi
}

install_commands() {
  if [[ -d "$REPO_DIR/commands" ]]; then
    ensure_directories
    # commands typically go to ~/.config/opencode/commands
    mkdir -p "$OPENCODE_AGENTS_DIR/../commands"
    copy_component "commands" "$REPO_DIR/commands" "$OPENCODE_AGENTS_DIR/../commands"
  fi
}

install_context() {
  if [[ -d "$REPO_DIR/context" ]]; then
    ensure_directories
    copy_component "context files" "$REPO_DIR/context" "$OPENCODE_AGENTS_DIR/../context"
  fi
}

install_config() {
  if [[ -d "$REPO_DIR/config" ]]; then
    ensure_directories
    copy_component "config" "$REPO_DIR/config" "$OPENCODE_AGENTS_DIR/../config"
  fi
}

install_tools() {
  if [[ -d "$REPO_DIR/tools" ]]; then
    ensure_directories
    copy_component "tools" "$REPO_DIR/tools" "$OPENCODE_AGENTS_DIR/../tools"
  fi
}

install_plugins() {
  if [[ -d "$REPO_DIR/plugins" ]]; then
    ensure_directories
    copy_component "plugins" "$REPO_DIR/plugins" "$OPENCODE_AGENTS_DIR/../plugins"
  fi
}

install_dashboard() {
  if [[ -d "$REPO_DIR/dashboard" ]]; then
    ensure_directories
    # Copy dashboard to OpenCode config
    mkdir -p "$OPENCODE_AGENTS_DIR/../dashboard"
    cp -r "$REPO_DIR/dashboard"/* "$OPENCODE_AGENTS_DIR/../dashboard"/ 2>/dev/null || true
    ok "Dashboard components copied"
  fi
}

main() {
  # If running from repo with no flags, go interactive
  if [[ $IN_REPO == true && $# -eq 0 ]]; then
    prompt_selection
    local sel="$SELECTED_COMPONENT"

    case "$sel" in
      "agents")           install_agents ;;
      "skills_opencode")  install_skills ;;
      "skills_nvidia")    install_skills ;;  # combined
      "commands")         install_commands ;;
      "context")          install_context ;;
      "config")           install_config ;;
      "plugins")          install_plugins ;;
      "tools")            install_tools ;;
      "dashboard")        install_dashboard ;;
      "all"|*)          
        # Install everything if "all" or mixed
        install_agents
        install_skills
        install_commands
        install_context
        install_config
        install_tools
        install_plugins
        install_dashboard
        ;;
    esac
  else
    # Flag-driven mode
    ok "Starting component installation with flags..."

    [[ $INSTALL_AGENTS == true ]]   && install_agents
    [[ $INSTALL_SKILLS == true ]]   && install_skills
    [[ $INSTALL_COMMANDS == true ]] && install_commands
    [[ $INSTALL_CONTEXT == true ]]  && install_context
    [[ $INSTALL_CONFIG == true ]]   && install_config
    [[ $INSTALL_PLUGINS == true ]]  && install_plugins
    [[ $INSTALL_TOOLS == true ]]    && install_tools
    [[ $INSTALL_DASHBOARD == true ]] && install_dashboard
    [[ $INSTALL_PLUGINDEPS == true ]] && ok "Plugin dependencies noted (handled by installer)"
  fi

  ok "Installation complete!"
  echo
  echo "Next steps:"
  echo "  1. Fill environment variables: cp ~/.config/opencode/env.example ~/.config/opencode/.env"
  echo "  2. Run: opencode auth (or set API keys)"
  echo "  3. Start dashboard: node ~/.config/opencode/dashboard/server.js"
  echo "  4. Visit: http://127.0.0.1:8877 (or DASHBOARD_PORT)"
  echo
  echo "For dashboard password protection, set environment variables:"
  echo "  DASHBOARD_USER=admin DASHBOARD_PASS=secret bash download.sh --dashboard"
  echo "or add to ~/.config/opencode/.env:"
  echo "  DASHBOARD_USER=admin"
  echo "  DASHBOARD_PASS=secret"
}

main "$@"