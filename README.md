# OpenCode Settings & Configuration

Personal OpenCode AI agent configuration — agents, skills, plugins, context, and MCP servers.

## What's Inside

| Folder | Contents |
|--------|----------|
| `agents/` | Main agents + specialized subagents (markdown) |
| `skills/opencode/` | OpenCode skills (47 folders) |
| `skills/nvidia/` | NVIDIA domain skills (363 folders) |
| `commands/` | Custom slash commands |
| `context/` | Coding standards, workflows, project intelligence |
| `plugins/` | Notify plugin (TypeScript) |
| `config/` | Agent metadata registry |
| `tools/` | Tool configurations |

## Quick Setup

### Linux / macOS

```bash
# Clone this repo
git clone https://github.com/<USER>/opencode-settings.git
cd opencode-settings

# Create OpenCode config directory if it doesn't exist
mkdir -p ~/.config/opencode

# Symlink to OpenCode config directory
ln -sf "$(pwd)/agents" ~/.config/opencode/agent
ln -sf "$(pwd)/skills/opencode" ~/.config/opencode/skills
ln -sf "$(pwd)/commands" ~/.config/opencode/command
ln -sf "$(pwd)/context" ~/.config/opencode/context
ln -sf "$(pwd)/config" ~/.config/opencode/config
ln -sf "$(pwd)/plugins" ~/.config/opencode/plugin

# Copy main config (backup existing first)
cp ~/.config/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc.bak
cp opencode.jsonc ~/.config/opencode/opencode.jsonc

# Copy NVIDIA skills
mkdir -p ~/.agents
cp -r skills/nvidia/* ~/.agents/skills/
cp skill-lock.json ~/.agents/.skill-lock.json
```

### Windows (Git Bash or WSL)

```bash
# Clone this repo
git clone https://github.com/<USER>/opencode-settings.git
cd opencode-settings

# Using Git Bash (symlinks require admin)
# Option A: Symlinks (run Git Bash as Administrator)
cmd //c "mklink /D %USERPROFILE%\.config\opencode\agent $(pwd)\agents"
cmd //c "mklink /D %USERPROFILE%\.config\opencode\skills $(pwd)\skills\opencode"
cmd //c "mklink /D %USERPROFILE%\.config\opencode\command $(pwd)\commands"
cmd //c "mklink /D %USERPROFILE%\.config\opencode\context $(pwd)\context"
cmd //c "mklink /D %USERPROFILE%\.config\opencode\config $(pwd)\config"
cmd //c "mklink /D %USERPROFILE%\.config\opencode\plugin $(pwd)\plugins"

# Option B: Copy (simpler, no admin needed)
mkdir -p ~/.config/opencode
cp -r agents/* ~/.config/opencode/agent/
cp -r skills/opencode/* ~/.config/opencode/skills/
cp -r commands/* ~/.config/opencode/command/
cp -r context/* ~/.config/opencode/context/
cp -r config/* ~/.config/opencode/config/
cp opencode.jsonc ~/.config/opencode/opencode.jsonc

# Copy NVIDIA skills
mkdir -p ~/.agents
cp -r skills/nvidia/* ~/.agents/skills/
cp skill-lock.json ~/.agents/.skill-lock.json
```

## Secrets Configuration

This repo uses environment variable placeholders. Create `~/.config/opencode/.env` or set these in your environment:

| Variable | Purpose |
|----------|---------|
| `GITHUB_TOKEN` | GitHub personal access token |
| `NOTION_TOKEN` | Notion API token |
| `COMPOSIO_API_KEY` | Composio API key |
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `MILVUS_ADDR` | Milvus vector DB address |
| `AWS_REGION` / `AWS_PROFILE` | AWS credentials |
| `AZURE_*` | Azure credentials |
| `ALIBABA_CLOUD_*` | Alibaba Cloud credentials |
| `GEMINI_API_KEY` | Google Gemini API key |
| `MINIMAX_API_KEY` | MiniMax API key |

## Updating

To pull latest changes:
```bash
cd ~/opencode-settings
git pull
# If using symlinks: nothing else needed
# If using copies: re-run the copy commands above
```

## Structure

- **Agents** are markdown files — edit them directly to customize behavior
- **Skills** are self-contained markdown + supporting files
- **Context** follows MVI (Minimal Viable Information) — small, focused files
- **MCP servers** configured in `opencode.jsonc` — most are disabled by default

## License

Personal configuration. MIT License.
