#Requires -RunAsAdministrator
# ──────────────────────────────────────────────────────────────
# install.ps1 — OpenCode codedata installer (Windows PowerShell)
#
# Copies agents, skills (opencode + nvidia), plugins, commands,
# context, tools, and opencode.jsonc into the correct locations.
#
# Usage (as Administrator):
#   .\install.ps1
#   powershell -ExecutionPolicy Bypass -File install.ps1
# ──────────────────────────────────────────────────────────────
$ErrorActionPreference = 'Stop'

# ── Helpers ───────────────────────────────────────────────────
function Write-Ok   { param([string]$Msg) Write-Host "  ✔  $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  ⚠  $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "  ✘  $Msg" -ForegroundColor Red }
function Write-Info { param([string]$Msg) Write-Host "  ℹ  $Msg" -ForegroundColor Cyan }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   OpenCode codedata — Windows Installer      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Target paths ──────────────────────────────────────────────
$OpenCodeDir = Join-Path $env:USERPROFILE '.config\opencode'
$AgentsDir   = Join-Path $env:USERPROFILE '.agents'

# ── Backup existing configs ───────────────────────────────────
Write-Host "[1/6] Backing up existing configuration..." -ForegroundColor White

if (Test-Path $OpenCodeDir) {
  $BackupOC = "$OpenCodeDir.backup.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
  Copy-Item -Path $OpenCodeDir -Destination $BackupOC -Recurse -Force
  Write-Ok "Backed up ~/.config/opencode → $BackupOC"
} else {
  Write-Info "No existing ~/.config/opencode to back up."
}

if (Test-Path $AgentsDir) {
  $BackupAg = "$AgentsDir.backup.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
  Copy-Item -Path $AgentsDir -Destination $BackupAg -Recurse -Force
  Write-Ok "Backed up ~/.agents → $BackupAg"
} else {
  Write-Info "No existing ~/.agents to back up."
}

# ── Create target directories ─────────────────────────────────
Write-Host ""
Write-Host "[2/6] Creating target directories..." -ForegroundColor White

$SubDirs = @('agents', 'commands', 'config', 'context', 'plugins', 'skills', 'tools')
foreach ($Sub in $SubDirs) {
  $Target = Join-Path $OpenCodeDir $Sub
  if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
  }
}
if (-not (Test-Path (Join-Path $AgentsDir 'skills'))) {
  New-Item -ItemType Directory -Path (Join-Path $AgentsDir 'skills') -Force | Out-Null
}
Write-Ok "Target directories created"

# ── Copy OpenCode config files ────────────────────────────────
Write-Host ""
Write-Host "[3/6] Installing OpenCode configuration..." -ForegroundColor White

$ConfigFiles = @('opencode.jsonc', 'env.example', 'package.json')
foreach ($File in $ConfigFiles) {
  $Src = Join-Path $ScriptDir $File
  $Dst = Join-Path $OpenCodeDir $File
  if (Test-Path $Src) {
    Copy-Item -Path $Src -Destination $Dst -Force
  }
}
Write-Ok "opencode.jsonc, env.example, package.json"

# ── Copy subdirectories ──────────────────────────────────────
$CopyMap = @{
  'agents'    = $OpenCodeDir
  'commands'  = $OpenCodeDir
  'config'    = $OpenCodeDir
  'context'   = $OpenCodeDir
  'dashboard' = $OpenCodeDir
  'plugins'   = $OpenCodeDir
  'tools'     = $OpenCodeDir
}

foreach ($Entry in $CopyMap.GetEnumerator()) {
  $Src = Join-Path $ScriptDir $Entry.Key
  $Dst = Join-Path $Entry.Value $Entry.Key
  if (Test-Path $Src) {
    Copy-Item -Path $Src -Destination $Dst -Recurse -Force
    $Count = (Get-ChildItem -Path $Src -Recurse -File).Count
    Write-Ok "$($Entry.Key)/ ($Count files)"
  }
}

# ── Copy Skills ───────────────────────────────────────────────
Write-Host ""
Write-Host "[4/6] Installing skills..." -ForegroundColor White

# OpenCode skills → ~/.config/opencode/skills/
$OcSkills = Join-Path $ScriptDir 'skills\opencode'
if (Test-Path $OcSkills) {
  $OcTarget = Join-Path $OpenCodeDir 'skills'
  Copy-Item -Path "$OcSkills\*" -Destination $OcTarget -Recurse -Force
  $OcCount = (Get-ChildItem -Path $OcSkills -Directory).Count
  Write-Ok "OpenCode skills/ ($OcCount dirs)"
}

# NVIDIA skills → ~/.agents/skills/
$NvSkills = Join-Path $ScriptDir 'skills\nvidia'
if (Test-Path $NvSkills) {
  $NvTarget = Join-Path $AgentsDir 'skills'
  Copy-Item -Path "$NvSkills\*" -Destination $NvTarget -Recurse -Force
  $NvCount = (Get-ChildItem -Path $NvSkills -Directory).Count
  Write-Ok "NVIDIA skills/ ($NvCount dirs)"
}

# Skill lock file
$SkillLockSrc = Join-Path $ScriptDir 'skill-lock.json'
$SkillLockDst = Join-Path $AgentsDir '.skill-lock.json'
if (Test-Path $SkillLockSrc) {
  Copy-Item -Path $SkillLockSrc -Destination $SkillLockDst -Force
  Write-Ok "skill-lock.json → ~/.agents/.skill-lock.json"
}

# ── Install plugin dependencies (optional) ────────────────────
Write-Host ""
Write-Host "[5/6] Installing plugin dependencies..." -ForegroundColor White

$HasBun = Get-Command bun -ErrorAction SilentlyContinue
$HasNpm = Get-Command npm -ErrorAction SilentlyContinue

if ($HasBun) {
  Push-Location $OpenCodeDir
  try {
    bun install --no-save 2>$null
    Write-Ok "bun install"
  } catch {
    Write-Warn "bun install failed (non-critical): $_"
  } finally {
    Pop-Location
  }
} elseif ($HasNpm) {
  Push-Location $OpenCodeDir
  try {
    npm install --no-save 2>$null
    Write-Ok "npm install"
  } catch {
    Write-Warn "npm install failed (non-critical): $_"
  } finally {
    Pop-Location
  }
} else {
  Write-Warn "Skipping plugin deps (no bun or npm found)"
}

# ── Summary ───────────────────────────────────────────────────
Write-Host ""
Write-Host "[6/6] Installation complete!" -ForegroundColor White
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅  OpenCode codedata installed!           ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Installed to:" -ForegroundColor White
Write-Host "    📁 $OpenCodeDir"
Write-Host "    📁 $AgentsDir"
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Create your .env file:" -ForegroundColor White
Write-Host "       Copy-Item '$OpenCodeDir\env.example' '$OpenCodeDir\.env'" -ForegroundColor Cyan
Write-Host "    2. Edit .env with your real tokens" -ForegroundColor White
Write-Host "    3. Run opencode to start using your agents" -ForegroundColor White
Write-Host "    4. Launch the dashboard (optional):" -ForegroundColor White
Write-Host "       node '$OpenCodeDir\dashboard\server.js'" -ForegroundColor Cyan
Write-Host "       → http://127.0.0.1:8877" -ForegroundColor Cyan
Write-Host ""
