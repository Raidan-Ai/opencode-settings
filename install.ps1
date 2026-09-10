# ──────────────────────────────────────────────────────────────
# install.ps1 — OpenCode codedata installer v2.1.0 (Windows PowerShell)
#
# Copies agents, skills (opencode + nvidia), plugins, commands,
# context, tools, dashboard, and opencode.jsonc into the correct
# locations for OpenCode to consume.
#
# Supports interactive menus, update (no-clobber) mode, and
# component selection for granular installs.
#
# No administrator privileges required — everything installs into
# your user profile.
#
# Usage:
#   .\install.ps1 [OPTIONS]
#
# Options:
#   -Help            Show this help message and exit
#   -DryRun          Print what would happen without modifying anything
#   -Uninstall       Remove installed configuration (backs up first)
#   -NoDashboard     Skip dashboard installation
#   -NoBackup        Skip backup of existing configuration
#   -Force           Overwrite existing files without prompting
#   -Prefix <dir>    Install opencode config into <dir> instead of
#                    ~\.config\opencode. Agents always go to ~\.agents.
#   -Mode <mode>     Force mode: full | update | uninstall | preview
#   -Components "a,b,c"  Comma-separated component subset:
#                    agents,skills,commands,context,config,plugins,
#                    tools,dashboard,plugindeps
#   -Interactive     Force interactive menu even when flags are present
#
# Examples:
#   .\install.ps1                           # Interactive menu
#   .\install.ps1 -Force                    # Non-interactive full install
#   .\install.ps1 -Mode update -Components "agents,tools"
#   .\install.ps1 -DryRun -Prefix C:\tmp\test
#   .\install.ps1 -Uninstall               # Back up and remove installed files
#
# Environment variables:
#   OPENCODE_PREFIX    Same as -Prefix
# ──────────────────────────────────────────────────────────────
param(
  [switch]$Help,
  [switch]$DryRun,
  [switch]$Uninstall,
  [switch]$NoDashboard,
  [switch]$NoBackup,
  [switch]$Force,
  [string]$Prefix = "",
  [string]$Mode = "",
  [string]$Components = "",
  [switch]$Interactive
)

$ErrorActionPreference = 'Stop'
$Version = '2.1.0'

# ── Helpers ───────────────────────────────────────────────────
function Write-Ok   { param([string]$Msg) Write-Host "  [OK]   $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  [WARN] $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "  [ERR]  $Msg" -ForegroundColor Red }
function Write-Info { param([string]$Msg) Write-Host "  [INFO] $Msg" -ForegroundColor Cyan }

# ── Resolve script directory ─────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# ── Component names (canonical list) ─────────────────────────
$AllComponents = @('agents','skills','commands','context','config','plugins','tools','dashboard','plugindeps')

# ── Track which components to install ─────────────────────────
$Selected = @{}
foreach ($c in $AllComponents) { $Selected[$c] = $true }

# ── Active mode variable (may be overridden by menu) ──────────
$ActiveMode = 'full'   # full | update | uninstall | preview

function Show-Usage {
  Write-Host @"

OpenCode codedata installer v$Version

Usage:
  .\install.ps1 [OPTIONS]

Options:
  -Help              Show this help message and exit
  -DryRun            Print what would happen without modifying anything
  -Uninstall         Remove installed configuration (backs up first)
  -NoDashboard       Skip dashboard installation
  -NoBackup          Skip backup of existing configuration
  -Force             Overwrite existing files without prompting
  -Prefix <dir>      Install opencode config into <dir> instead of
                     ~\.config\opencode. Agents always go to ~\.agents.
  -Mode <mode>       Force mode: full | update | uninstall | preview
  -Components "a,b"  Comma-separated component subset (agents, skills,
                     commands, context, config, plugins, tools,
                     dashboard, plugindeps)
  -Interactive       Force interactive menu even when flags are present

Examples:
  .\install.ps1                            # Interactive menu
  .\install.ps1 -Force                     # Non-interactive full install
  .\install.ps1 -Mode update -Components "agents,tools"
  .\install.ps1 -DryRun                    # Preview what would happen
  .\install.ps1 -Prefix C:\tmp\test        # Install to custom prefix
  .\install.ps1 -Uninstall                 # Back up and remove installed files

Environment variables:
  OPENCODE_PREFIX    Same as -Prefix
"@
}

# ── Target paths ──────────────────────────────────────────────
if ($Prefix -ne "") {
  $OpenCodeDir = Join-Path $Prefix '.config\opencode'
} elseif ($env:OPENCODE_PREFIX) {
  $OpenCodeDir = Join-Path $env:OPENCODE_PREFIX '.config\opencode'
} else {
  $OpenCodeDir = Join-Path $env:USERPROFILE '.config\opencode'
}
# Agents always go to the user profile, regardless of prefix.
$AgentsDir = Join-Path $env:USERPROFILE '.agents'

# ── Timestamp helper (unix seconds) ───────────────────────────
function Get-Timestamp {
  return [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
}

# ── Run a step: prints "Would: ..." in dry-run, else executes ─
function Invoke-Step {
  param(
    [string]$Label,
    [ScriptBlock]$Body
  )
  if ($DryRun) {
    Write-Info "Would: $Label"
  } else {
    & $Body
    Write-Ok $Label
  }
}

# ── Backup an existing directory ──────────────────────────────
function Backup-Directory {
  param(
    [string]$Target,
    [string]$Suffix = 'backup'
  )
  if (Test-Path $Target) {
    $Backup = "$Target.$Suffix.$(Get-Timestamp)"
    Invoke-Step "Back up $Target -> $Backup" {
      Copy-Item -Path $Target -Destination $Backup -Recurse -Force
    }
  } else {
    Write-Info "No existing $Target to back up."
  }
}

# ── Copy a directory tree (force-overwrite, used by full mode) ─
function Copy-Tree {
  param(
    [string]$Src,
    [string]$Dst,
    [string]$Label
  )
  if (-not (Test-Path $Src)) {
    Write-Info "Source not found: $Src (skipping)"
    return
  }
  $Count = (Get-ChildItem -Path $Src -Recurse -File -ErrorAction SilentlyContinue).Count
  Invoke-Step "Copy $Label ($Count files) -> $Dst" {
    if (-not (Test-Path $Dst)) { New-Item -ItemType Directory -Path $Dst -Force | Out-Null }
    Copy-Item -Path "$Src\*" -Destination $Dst -Recurse -Force
  }
}

# ── Copy-Tree with no-clobber (used by update mode) ──────────
# Only copies files/dirs that do NOT exist at the destination.
function Copy-Merge-Tree {
  param(
    [string]$Src,
    [string]$Dst,
    [string]$Label
  )
  if (-not (Test-Path $Src)) {
    Write-Info "Source not found: $Src (skipping)"
    return
  }
  Invoke-Step "Merge $Label (no-clobber) -> $Dst" {
    if (-not (Test-Path $Dst)) { New-Item -ItemType Directory -Path $Dst -Force | Out-Null }
    Get-ChildItem -Path $Src -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
      $RelPath = $_.FullName.Substring($Src.Length + 1)
      $TargetPath = Join-Path $Dst $RelPath
      if ($_.PSIsContainer) {
        if (-not (Test-Path $TargetPath)) {
          New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        }
      } else {
        if (-not (Test-Path $TargetPath)) {
          $Parent = Split-Path -Parent $TargetPath
          if (-not (Test-Path $Parent)) { New-Item -ItemType Directory -Path $Parent -Force | Out-Null }
          Copy-Item -Path $_.FullName -Destination $TargetPath -Force
        }
      }
    }
  }
}

# ── Copy a single file with no-clobber ────────────────────────
function Copy-Merge-File {
  param(
    [string]$Src,
    [string]$Dst,
    [string]$Label
  )
  if (-not (Test-Path $Src)) { return }
  if (-not (Test-Path $Dst)) {
    Invoke-Step "Copy $Label -> $Dst" {
      Copy-Item -Path $Src -Destination $Dst -Force
    }
  }
}

# ── Smart copy: full = overwrite, update = no-clobber ─────────
function Smart-Copy-Tree {
  param(
    [string]$Src,
    [string]$Dst,
    [string]$Label
  )
  if ($ActiveMode -eq 'update') {
    Copy-Merge-Tree -Src $Src -Dst $Dst -Label $Label
  } else {
    Copy-Tree -Src $Src -Dst $Dst -Label $Label
  }
}

# ── Install skills ────────────────────────────────────────────
function Install-Skills {
  # OpenCode skills -> ~\.config\opencode\skills\
  $OcSkills = Join-Path $ScriptDir 'skills\opencode'
  if (Test-Path $OcSkills) {
    $OcTarget = Join-Path $OpenCodeDir 'skills'
    $Count = (Get-ChildItem -Path $OcSkills -Directory).Count
    if ($ActiveMode -eq 'update') {
      Copy-Merge-Tree -Src $OcSkills -Dst $OcTarget -Label "OpenCode skills ($Count dirs)"
    } else {
      Invoke-Step "Copy OpenCode skills ($Count dirs) -> $OcTarget" {
        if (-not (Test-Path $OcTarget)) { New-Item -ItemType Directory -Path $OcTarget -Force | Out-Null }
        Copy-Item -Path "$OcSkills\*" -Destination $OcTarget -Recurse -Force
      }
    }
  }

  # NVIDIA skills -> ~\.agents\skills\
  $NvSkills = Join-Path $ScriptDir 'skills\nvidia'
  if (Test-Path $NvSkills) {
    $NvTarget = Join-Path $AgentsDir 'skills'
    $Count = (Get-ChildItem -Path $NvSkills -Directory).Count
    if ($ActiveMode -eq 'update') {
      Copy-Merge-Tree -Src $NvSkills -Dst $NvTarget -Label "NVIDIA skills ($Count dirs)"
    } else {
      Invoke-Step "Copy NVIDIA skills ($Count dirs) -> $NvTarget" {
        if (-not (Test-Path $NvTarget)) { New-Item -ItemType Directory -Path $NvTarget -Force | Out-Null }
        Copy-Item -Path "$NvSkills\*" -Destination $NvTarget -Recurse -Force
      }
    }
  }

  # Skill lock file -> ~\.agents\.skill-lock.json
  $SkillLockSrc = Join-Path $ScriptDir 'skill-lock.json'
  if (Test-Path $SkillLockSrc) {
    $SkillLockDst = Join-Path $AgentsDir '.skill-lock.json'
    if ($ActiveMode -eq 'update') {
      Copy-Merge-File -Src $SkillLockSrc -Dst $SkillLockDst -Label "skill-lock.json"
    } else {
      Invoke-Step "Copy skill-lock.json -> $AgentsDir\.skill-lock.json" {
        Copy-Item -Path $SkillLockSrc -Destination $SkillLockDst -Force
      }
    }
  }
}

# ── Install dashboard ─────────────────────────────────────────
function Install-Dashboard {
  if ($NoDashboard -or -not $Selected['dashboard']) {
    Write-Info "Dashboard skipped"
    return
  }
  $DashSrc = Join-Path $ScriptDir 'dashboard'
  if (Test-Path $DashSrc) {
    $DashDst = Join-Path $OpenCodeDir 'dashboard'
    if ($ActiveMode -eq 'update') {
      Copy-Merge-Tree -Src $DashSrc -Dst $DashDst -Label "dashboard"
    } else {
      Invoke-Step "Copy dashboard -> $DashDst" {
        Copy-Item -Path $DashSrc -Destination $DashDst -Recurse -Force
      }
    }
  }
}

# ── Install plugin dependencies (optional) ────────────────────
function Install-PluginDeps {
  if (-not $Selected['plugindeps']) {
    Write-Info "Plugin deps skipped (not selected)"
    return
  }
  $HasBun = Get-Command bun -ErrorAction SilentlyContinue
  $HasNpm = Get-Command npm -ErrorAction SilentlyContinue

  if ($DryRun) {
    Write-Info "Would: run bun install or npm install (if available)"
    return
  }

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
}

# ── Verify installation ───────────────────────────────────────
function Verify-Install {
  $Warnings = 0

  if ($DryRun) {
    Write-Info "Verification skipped (dry-run)"
    return
  }

  if (Test-Path (Join-Path $OpenCodeDir 'opencode.jsonc')) {
    Write-Ok "opencode.jsonc present"
  } else {
    Write-Warn "opencode.jsonc MISSING"
    $Warnings++
  }

  $AgentDir = Join-Path $OpenCodeDir 'agents'
  if (Test-Path $AgentDir) {
    $AgentCount = (Get-ChildItem -Path $AgentDir -Recurse -File -ErrorAction SilentlyContinue).Count
    if ($AgentCount -gt 0) {
      Write-Ok "Agents: $AgentCount files installed"
    } else {
      Write-Warn "Agents directory is empty"
      $Warnings++
    }
  } else {
    Write-Warn "Agents directory missing"
    $Warnings++
  }

  $SkillDir = Join-Path $OpenCodeDir 'skills'
  if (Test-Path $SkillDir) {
    $SkillCount = (Get-ChildItem -Path $SkillDir -Directory -ErrorAction SilentlyContinue).Count
    Write-Ok "Skills: $SkillCount dirs installed"
  }

  if (-not $NoDashboard -and $Selected['dashboard'] -and (Test-Path (Join-Path $OpenCodeDir 'dashboard\server.js'))) {
    Write-Ok "Dashboard present (server.js)"
  } elseif (-not $NoDashboard -and $Selected['dashboard']) {
    Write-Warn "Dashboard not found (server.js missing)"
    $Warnings++
  }

  if (Test-Path (Join-Path $OpenCodeDir 'env.example')) {
    Write-Ok "env.example present"
  } else {
    Write-Warn "env.example missing"
    $Warnings++
  }

  if ($Warnings -gt 0) {
    Write-Host ""
    Write-Warn "$Warnings issue(s) detected - review above output"
  }
}

# ── Summary box ───────────────────────────────────────────────
function Show-Summary {
  Write-Host ""
  Write-Host "  Installed locations:" -ForegroundColor White
  Write-Host "    [DIR] opencode config : $OpenCodeDir"
  Write-Host "    [DIR] agents/skills   : $AgentsDir"
  Write-Host ""
  Write-Host "  Next steps:" -ForegroundColor White
  Write-Host "    1. Create your .env file:"
  Write-Host "       Copy-Item '$OpenCodeDir\env.example' '$OpenCodeDir\.env'" -ForegroundColor Cyan
  Write-Host "    2. Edit .env with your real tokens" -ForegroundColor White
  Write-Host "    3. Run opencode to start using your agents" -ForegroundColor White
  if (-not $NoDashboard -and $Selected['dashboard']) {
    Write-Host "    4. Launch the dashboard (optional):" -ForegroundColor White
    Write-Host "       node '$OpenCodeDir\dashboard\server.js'" -ForegroundColor Cyan
    Write-Host "       -> http://127.0.0.1:8877" -ForegroundColor Cyan
  }
  Write-Host ""
}

# ── Uninstall flow ────────────────────────────────────────────
function Invoke-Uninstall {
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "║   OpenCode codedata — Uninstaller  v$Version   ║" -ForegroundColor Cyan
  Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host ""

  Write-Host "  [1/2] Backing up before removal..." -ForegroundColor White

  if ($DryRun) {
    if (Test-Path $OpenCodeDir) {
      Write-Info "Would: back up $OpenCodeDir -> $OpenCodeDir.uninstall-backup.$(Get-Timestamp)"
    } else {
      Write-Info "No opencode dir to remove."
    }
    if (Test-Path $AgentsDir) {
      Write-Info "Would: back up $AgentsDir -> $AgentsDir.uninstall-backup.$(Get-Timestamp)"
    } else {
      Write-Info "No agents dir to remove."
    }
  } else {
    if (-not $NoBackup) {
      Backup-Directory -Target $OpenCodeDir -Suffix 'uninstall-backup'
      Backup-Directory -Target $AgentsDir -Suffix 'uninstall-backup'
    } else {
      Write-Info "Backup skipped (-NoBackup)"
    }
  }

  Write-Host ""
  Write-Host "  [2/2] Removing installed directories..." -ForegroundColor White

  foreach ($Dir in @($OpenCodeDir, $AgentsDir)) {
    if (Test-Path $Dir) {
      Invoke-Step "Remove $Dir" {
        Remove-Item -Path $Dir -Recurse -Force
      }
    }
  }

  Write-Host ""
  if ($DryRun) {
    Write-Host "  [DRY-RUN] Uninstall complete - nothing was modified." -ForegroundColor Cyan
  } else {
    Write-Host "  [DONE] Uninstall complete." -ForegroundColor Green
  }
  Write-Host ""
}

# ══════════════════════════════════════════════════════════════
# INTERACTIVE MENU
# ══════════════════════════════════════════════════════════════

function Show-MainMenu {
  Write-Host ""
  Write-Host "  OpenCode codedata Installer v$Version" -ForegroundColor White
  Write-Host "  ─────────────────────────────────────" -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "  [1] Full install    — fresh install of ALL components (existing config backed up first)" -ForegroundColor White
  Write-Host "  [2] Update         — merge: add missing components, NEVER overwrite existing user files" -ForegroundColor White
  Write-Host "  [3] Uninstall      — backup then remove installed dirs" -ForegroundColor White
  Write-Host "  [4] Preview        — dry-run of a full install" -ForegroundColor White
  Write-Host "  [5] Help           — show usage" -ForegroundColor White
  Write-Host "  [0] Exit" -ForegroundColor DarkGray
  Write-Host ""

  $Choice = Read-Host "  Choose [0-5]"
  return $Choice
}

function Show-ComponentSelect {
  param(
    [string]$Prompt = "Components (Enter = keep default):"
  )
  Write-Host ""
  Write-Host "  $Prompt" -ForegroundColor White
  Write-Host "  ─────────────────────────────────────" -ForegroundColor DarkGray
  Write-Host ""

  # Reset all to default (true)
  foreach ($c in $AllComponents) { $Selected[$c] = $true }

  $Labels = @(
    @('agents',      'agents'),
    @('skills',      'skills'),
    @('commands',    'commands'),
    @('context',     'context'),
    @('config',      'config (opencode.jsonc, env.example, package.json)'),
    @('plugins',     'plugins'),
    @('tools',       'tools'),
    @('dashboard',   'dashboard'),
    @('plugindeps',  'plugin deps (bun/npm install)')
  )

  foreach ($Item in $Labels) {
    $Key = $Item[0]
    $Desc = $Item[1]
    $Default = if ($Selected[$Key]) { "Y" } else { "n" }
    $Input = Read-Host "    $Desc  [$Default]"
    if ($Input -match '^(n|no)$') {
      $Selected[$Key] = $false
    } elseif ($Input -match '^(y|yes)$') {
      $Selected[$Key] = $true
    } elseif ($Input -eq '') {
      # Enter pressed — keep current default
    } elseif ($Input -eq 'all') {
      foreach ($c in $AllComponents) { $Selected[$c] = $true }
      Write-Host "    (all components selected)" -ForegroundColor Cyan
      break
    } elseif ($Input -eq 'quit') {
      # Cancel and go back
      Write-Host "    (selection cancelled)" -ForegroundColor Yellow
      return $false
    }
  }

  return $true
}

function Show-InstallSummary {
  param(
    [string]$ModeLabel
  )
  Write-Host ""
  Write-Host "  Summary:" -ForegroundColor White
  Write-Host "  ────────" -ForegroundColor DarkGray
  Write-Host "    Mode       : $ModeLabel" -ForegroundColor White
  Write-Host "    Target     : $OpenCodeDir" -ForegroundColor White
  Write-Host "    Agents     : $AgentsDir" -ForegroundColor White
  if ($DryRun) {
    Write-Host "    Dry-run    : YES (nothing will be modified)" -ForegroundColor Yellow
  }
  Write-Host ""
  Write-Host "    Components:" -ForegroundColor White
  foreach ($c in $AllComponents) {
    $Mark = if ($Selected[$c]) { "[x]" } else { "[ ]" }
    $Color = if ($Selected[$c]) { "Green" } else { "DarkGray" }
    Write-Host "      $Mark $c" -ForegroundColor $Color
  }
  Write-Host ""
}

# ══════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════

# ── Determine if we should show the interactive menu ──────────
# Show menu when: no mode-determining flag AND no -Mode AND stdin is TTY
$HasModeFlag = $DryRun -or $Uninstall -or ($Mode -ne "")
$IsInteractive = $false
if ($Interactive) {
  $IsInteractive = $true
} elseif (-not $HasModeFlag) {
  # Check if stdin is a console (TTY)
  try {
    $IsInteractive = [Console]::IsInputRedirected -eq $false
  } catch {
    $IsInteractive = $true
  }
}

# ── Handle help early ─────────────────────────────────────────
if ($Help) {
  Show-Usage
  exit 0
}

# ── Parse -Mode parameter ─────────────────────────────────────
if ($Mode -ne "") {
  $ModeLower = $Mode.ToLower()
  switch ($ModeLower) {
    'full'     { $ActiveMode = 'full' }
    'update'   { $ActiveMode = 'update' }
    'uninstall'{ $ActiveMode = 'uninstall' }
    'preview'  { $ActiveMode = 'preview'; $DryRun = $true }
    default {
      Write-Err "Invalid mode: $Mode (valid: full, update, uninstall, preview)"
      exit 1
    }
  }
}

# ── Parse -Components parameter ───────────────────────────────
if ($Components -ne "") {
  $CompList = $Components -split ',' | ForEach-Object { $_.Trim().ToLower() }
  # First, deselect all
  foreach ($c in $AllComponents) { $Selected[$c] = $false }
  foreach ($c in $CompList) {
    if ($AllComponents -contains $c) {
      $Selected[$c] = $true
    } else {
      Write-Warn "Unknown component: $c (valid: $($AllComponents -join ', '))"
    }
  }
}

# ── Map legacy flags to mode ──────────────────────────────────
if ($Uninstall) { $ActiveMode = 'uninstall' }
if ($DryRun -and $ActiveMode -eq 'full') { $ActiveMode = 'preview' }

# ══════════════════════════════════════════════════════════════
# INTERACTIVE MENU LOOP (when stdin is TTY and no mode flag)
# ══════════════════════════════════════════════════════════════
if ($IsInteractive) {
  do {
    $MenuChoice = Show-MainMenu

    switch ($MenuChoice) {
      '1' {
        # Full install
        $ActiveMode = 'full'
        $DryRun = $false
        $CompOK = Show-ComponentSelect
        if ($CompOK -eq $false) { continue }
        Show-InstallSummary -ModeLabel "Full install"
        $Proceed = Read-Host "  Proceed? [Y/n]"
        if ($Proceed -match '^(n|no)$') {
          Write-Info "Cancelled."
          continue
        }
        break
      }
      '2' {
        # Update (merge)
        $ActiveMode = 'update'
        $DryRun = $false
        $CompOK = Show-ComponentSelect
        if ($CompOK -eq $false) { continue }
        Show-InstallSummary -ModeLabel "Update (no-clobber)"
        $Proceed = Read-Host "  Proceed? [Y/n]"
        if ($Proceed -match '^(n|no)$') {
          Write-Info "Cancelled."
          continue
        }
        break
      }
      '3' {
        # Uninstall
        $ActiveMode = 'uninstall'
        Show-InstallSummary -ModeLabel "Uninstall"
        $Proceed = Read-Host "  Proceed? [Y/n]"
        if ($Proceed -match '^(n|no)$') {
          Write-Info "Cancelled."
          continue
        }
        break
      }
      '4' {
        # Preview (dry-run full)
        $ActiveMode = 'preview'
        $DryRun = $true
        Show-InstallSummary -ModeLabel "Preview (dry-run)"
        break
      }
      '5' {
        Show-Usage
        continue
      }
      '0' {
        Write-Info "Exiting."
        exit 0
      }
      default {
        Write-Warn "Invalid choice: $MenuChoice"
        continue
      }
    }
    # If we broke out of the switch, we're done with the menu
    break
  } while ($true)
}

# ══════════════════════════════════════════════════════════════
# EXECUTION
# ══════════════════════════════════════════════════════════════

# ── Uninstall path ────────────────────────────────────────────
if ($ActiveMode -eq 'uninstall') {
  Invoke-Uninstall
  exit 0
}

# ── Banner ────────────────────────────────────────────────────
$ModeLabel = if ($ActiveMode -eq 'update') { "update" } elseif ($DryRun) { "preview" } else { "full" }
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   OpenCode codedata — Installer  v$Version   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
if ($DryRun) {
  Write-Host "  (dry-run mode - nothing will be modified)" -ForegroundColor Yellow
}
if ($ActiveMode -eq 'update') {
  Write-Host "  (update mode - will NOT overwrite existing files)" -ForegroundColor Yellow
}
Write-Host ""

# ── [1/7] Check prerequisites ─────────────────────────────────
Write-Host "  [1/7] Checking prerequisites..." -ForegroundColor White
$HasGit = Get-Command git -ErrorAction SilentlyContinue
if (-not $HasGit) {
  Write-Err "git not found. Please install git first."
  exit 1
}
Write-Ok "git $((git --version) -replace 'git version ', '')"
if (Get-Command node -ErrorAction SilentlyContinue) {
  Write-Ok "node $((node --version))"
} else {
  Write-Warn "node not found. Plugin deps will be skipped."
}

# ── [2/7] Backup ──────────────────────────────────────────────
Write-Host ""
Write-Host "  [2/7] Backing up existing configuration..." -ForegroundColor White
if ($DryRun) {
  if (Test-Path $OpenCodeDir) { Write-Info "Would: back up $OpenCodeDir -> $OpenCodeDir.backup.$(Get-Timestamp)" }
  if (Test-Path $AgentsDir)   { Write-Info "Would: back up $AgentsDir -> $AgentsDir.backup.$(Get-Timestamp)" }
} elseif (-not $NoBackup) {
  Backup-Directory -Target $OpenCodeDir -Suffix 'backup'
  Backup-Directory -Target $AgentsDir -Suffix 'backup'
} else {
  Write-Info "Backup skipped (-NoBackup)"
}

# ── Confirmation prompt (non-interactive full mode only) ──────
if (-not $DryRun -and -not $Force -and $ActiveMode -eq 'full' -and (Test-Path $OpenCodeDir)) {
  Write-Host ""
  Write-Host "  Target already exists: $OpenCodeDir" -ForegroundColor Yellow
  $Answer = Read-Host "  Continue and overwrite? [y/N]"
  if ($Answer -notmatch '^[yY]') {
    Write-Info "Aborted by user."
    exit 0
  }
}

# ── [3/7] Create target directories ───────────────────────────
Write-Host ""
Write-Host "  [3/7] Creating target directories..." -ForegroundColor White
$SubDirs = @('agents', 'commands', 'config', 'context', 'dashboard', 'plugins', 'skills', 'tools')
foreach ($Sub in $SubDirs) {
  $Target = Join-Path $OpenCodeDir $Sub
  Invoke-Step "Create $Target" {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
  }
}
$AgentsSkills = Join-Path $AgentsDir 'skills'
Invoke-Step "Create $AgentsSkills" {
  New-Item -ItemType Directory -Path $AgentsSkills -Force | Out-Null
}

# ── [4/7] Install OpenCode configuration ──────────────────────
Write-Host ""
Write-Host "  [4/7] Installing OpenCode configuration..." -ForegroundColor White

if ($Selected['config']) {
  $ConfigFiles = @('opencode.jsonc', 'env.example', 'package.json')
  foreach ($File in $ConfigFiles) {
    $Src = Join-Path $ScriptDir $File
    $Dst = Join-Path $OpenCodeDir $File
    if (Test-Path $Src) {
      if ($ActiveMode -eq 'update') {
        Copy-Merge-File -Src $Src -Dst $Dst -Label $File
      } else {
        Invoke-Step "Copy $File -> $OpenCodeDir" {
          Copy-Item -Path $Src -Destination $Dst -Force
        }
      }
    }
  }
} else {
  Write-Info "Config files skipped (not selected)"
}

# ── Subdirectories (agents, commands, config, context, plugins, tools) ──
$CopyDirs = @('agents', 'commands', 'config', 'context', 'plugins', 'tools')
foreach ($Dir in $CopyDirs) {
  if ($Selected[$Dir]) {
    $Src = Join-Path $ScriptDir $Dir
    if (Test-Path $Src) {
      Smart-Copy-Tree -Src $Src -Dst (Join-Path $OpenCodeDir $Dir) -Label $Dir
    }
  } else {
    Write-Info "$Dir skipped (not selected)"
  }
}

# ── [5/7] Install skills ──────────────────────────────────────
Write-Host ""
Write-Host "  [5/7] Installing skills..." -ForegroundColor White
if ($Selected['skills']) {
  Install-Skills
} else {
  Write-Info "Skills skipped (not selected)"
}

# ── Dashboard ─────────────────────────────────────────────────
Install-Dashboard

# ── [6/7] Install plugin dependencies ─────────────────────────
Write-Host ""
Write-Host "  [6/7] Installing plugin dependencies..." -ForegroundColor White
Install-PluginDeps

# ── [7/7] Verification ────────────────────────────────────────
Write-Host ""
Write-Host "  [7/7] Verifying installation..." -ForegroundColor White
Verify-Install

# ── Final summary ─────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   [OK]  OpenCode codedata installed!         ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Green
Show-Summary
