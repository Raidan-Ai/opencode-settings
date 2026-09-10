---
name: npx
description: Run npm packages without global installs using npx. Use for one-off CLI tools, scaffolders, MCP servers, and code generators. Covers npx patterns, --yes flag, version pinning, and security checks.
---

# Purpose

Run npm packages without global installs using npx. Use for one-off CLI tools, scaffolders, MCP servers, and code generators. Covers npx patterns, --yes flag, version pinning, and security checks.

# When to activate

- When a one-off CLI tool is needed (MCP server start, code scaffolder, test runner)
- When avoiding global npm pollution is desired
- When working across multiple projects with different dependency needs
- When needing the latest version of a tool without committing to a global install

# Core knowledge

## npx resolution order

1. **Local `node_modules/.bin`**: If the package is installed locally, npx uses `./node_modules/.bin/<pkg>` first
2. **Global cache**: If not local, npx downloads to `~/.npm/_npx/` and caches it
3. **`npm exec` alternative**: `npx` is equivalent to `npx` = `npm exec --`
4. **Version pinning**: `npx -y pkg@<version>` pins exact version; `npx pkg@latest` uses latest

## Key flags

- `-y` or `--yes`: Auto-accept prompts (use in scripts/automation); `npx -y pkg@latest`
- `--no-install`: Use only already-installed packages; `npx --no-install pkg`
- `--package`: Install a one-off dependency; `npx --package lodash pkg`
- `--prefix`: Run with custom `process.cwd()` 

## Security considerations

- **Verify package provenance**: Only use npx with packages from trusted registries
- **Avoid unpinned versions** in scripts: `npx -y pkg@1.2.3` instead of `npx pkg`
- **Sandboxed execution**: npx runs in a temporary environment; be cautious with `prepare` scripts
- **Never run untrusted packages** without reviewing the source code first

# Workflow

## 1. Check local first

```bash
# If pkg is in local node_modules, npx uses that automatically
npx pkg --version

# Or explicitly check local
npx --no-install pkg --version
```

## 2. Use pinned versions in automation

```bash
# In scripts, always pin:
npx -y @azure/mcp@latest server start

# Or exact version:
npx -y ruflo@0.3.0 mcp start
```

## 3. Use --yes for non-interactive contexts

```bash
# Scripts and CI/CD
npx -y playwright@latest install
npx -y shadcn@latest init

# Interactive use (omit -y for prompts):
npx @modelcontextprotocol/server-github --version
```

## 4. Verify provenance and read package docs

```bash
# Check where npx will resolve from
npx --help

# View package info
npx pkg@1.2.3 --help
```

# Tools

- `npx`: Core tool (included with npm v17+; for older npm: `npx` from create-npx-readme)
- `npm exec`: Alternative for running local packages
- `npm pack` + `tar`: Manual installation alternative
- `which npx`: Verify npx is on PATH

# MCP requirements

None. npx is a standalone CLI tool distributed with npm. No external services required beyond npm registry access.

# Best practices

- **Always pin versions** in CI/CD scripts: `npx -y pkg@specific-version`
- **Use `--no-install`** when you want to ensure only locally-installed packages run
- **Review package source** before first-time npx execution
- **Prefer `npm pkg`** over global installs for project-specific tools
- **Document npx usage** in project README for new contributors

# Anti-patterns

- Running `npx` with unpinned versions in production scripts
- Using `npx` as a replacement for `npm install -g` when global is genuinely needed
- Omitting `-y` in automated contexts, causing hanging prompts
- Assuming npx will always find a package without network issues
- Mixing npx with global installs without clear ownership

# Verification

```bash
# Check npx is available
npx --version

# Verify a package resolves correctly
npx -y shadcn@latest init --help

# Confirm local vs remote resolution
cd /tmp/test-npx && mkdir -p project && cd project
npm init -y
npx -y @modelcontextprotocol/server-github --version 2>&1 | head -1

# Verify version pinning works
npx -y shadcn@0.0.1 help 2>&1 | head -3
```

# Examples

```bash
# Start Azure MCP server
npx -y @azure/mcp@latest server start

# Install and run Playwright
npx -y playwright@latest install
npx -y playwright@latest test

# Start Ruflo MCP
npx -y ruflo@latest mcp start

# Initialize shadcn UI
npx -y shadcn@latest init

# Use --no-install with local packages
npx --no-install jq --version

# Run a one-off package without installing
npx lodash chunk ['a', 'b'], 2
```