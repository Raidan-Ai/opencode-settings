---
name: windows
description: Windows OS administration including PowerShell 7 scripting, WSL2 setup and interop, Windows Server roles (AD, IIS), Task Scheduler, Windows Defender firewall, winget package management, registry, services, event logs, remote management (WinRM/SSH), and disk management. Activate for any Windows administration, PowerShell scripting, Windows Server setup, or Windows hardening task.
---

# Windows Administration Skill

## Purpose
Provides comprehensive Windows administration capabilities: PowerShell 7 scripting, WSL2, Windows Server roles (Active Directory, IIS), Task Scheduler, firewall, winget package management, registry, services, event logs, remote management (WinRM/SSH), and disk management. Includes server-hardening parallels to the linux-server skill.

## When to Activate
- PowerShell 7 scripting and automation
- WSL2 setup, interop, and Linux-on-Windows workflows
- Windows Server role configuration (AD, IIS, DNS, DHCP)
- Task Scheduler task creation and management
- Windows Defender Firewall rule management
- winget package installation and updates
- Registry and services administration
- Event log analysis (Get-WinEvent)
- Remote management (WinRM, SSH, PSRemoting)
- Disk and storage management
- Windows server hardening

## Core Knowledge

### PowerShell 7 (pwsh)
```powershell
# Objects, not text
Get-Process | Where-Object CPU -gt 100 | Sort-Object CPU -Descending

# Error handling
try { Get-Item "C:\app\config.json" }
catch { Write-Error "Failed: $($_.Exception.Message)" }
```

### WSL2
```powershell
wsl --install -d Ubuntu-22.04          # Install distro
wsl --list --verbose                   # List + state
wsl -d Ubuntu-22.04 -- bash -c "sudo apt update"
# Interop: %PATH% passthrough both directions
```

### Windows Server Roles
```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "corp.example.com" -DomainNetbiosName "CORP"
Install-WindowsFeature Web-Server, Web-Asp-Net45
Get-WindowsFeature | Where-Object Installed
```

### Task Scheduler
```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\scripts\backup.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2AM
Register-ScheduledTask -TaskName "DailyBackup" -Action $action -Trigger $trigger `
  -Principal (New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest)
Get-ScheduledTask -TaskName "DailyBackup"
```

### Windows Defender Firewall
```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
Get-NetFirewallRule -Enabled True | Select DisplayName, Direction, Action
```

### winget
```powershell
winget search "visual studio code"
winget install --id Microsoft.VisualStudioCode -e --silent
winget upgrade --all
winget export -o packages.json ; winget import -i packages.json
```

### Registry & Services
```powershell
Set-ItemProperty -Path "HKLM:\Software\MyApp" -Name "Version" -Value "1.0.0"
Get-Service sshd ; Set-Service sshd -StartupType Automatic ; Restart-Service sshd
```

### Event Logs
```powershell
Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4625; StartTime=(Get-Date).AddDays(-1) }
Get-WinEvent -FilterHashtable @{ LogName='Application'; Level=2; StartTime=(Get-Date).AddHours(-24) }
```

### Remote Management (WinRM / SSH)
```powershell
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.1.10" -Force
Invoke-Command -ComputerName server01 -FilePath C:\scripts\deploy.ps1
# OpenSSH: Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

### Disk Management
```powershell
Get-Volume ; Get-PhysicalDisk | Select FriendlyName, HealthStatus
New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter E
Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel "Data"
```

## Workflow

### 1. Initial Windows Server Setup
```powershell
#Update fully, enable firewall + remote mgmt, install core tooling
Get-WUInstall -MicrosoftUpdate -AcceptAll
Set-NetFirewallProfile -All -Enabled True
Enable-PSRemoting -Force            # or install OpenSSH Server
winget install --id Git.Git Microsoft.PowerShell -e
```

### 2. Deploy a Service
```powershell
sc.exe create MyApp binPath= "C:\app\myapp.exe --config C:\app\config.json" start= auto
sc.exe start MyApp ; sc.exe query MyApp
```

### 3. Harden the Server
```powershell
Get-NetFirewallProfile | Set-NetFirewallProfile -DefaultInboundAction Block
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
# Account lockout + auto-update via Group Policy / Windows Update
```

## Tools
```powershell
systeminfo ; Get-ComputerInfo | Select OsName, OsVersion
Get-NetTCPConnection -State Listen ; Test-NetConnection srv1 -Port 443
Get-Process | Sort CPU -Descending | Select -First 10
Get-PSDrive -PSProvider FileSystem            # disk space
```

### MCP Requirements
No official MCP server is bundled. Optional community servers (e.g. WinMCP) exist — verify security before use; do not add to config by default.

## Best Practices
1. **Use PowerShell 7 (pwsh)** over Windows PowerShell 5.1 when possible
2. **Objects over text**: filter with `Where-Object`, not string parsing
3. **Least privilege**: run scripts as needed, warn when admin required
4. **WinRM/SSH**: prefer SSH keys; restrict TrustedHosts to specific hosts
5. **winget** for reproducible package installs; export manifests
6. **Scheduled tasks** for recurring maintenance, run as least-privilege principal
7. **Firewall default-deny**: allow only required inbound ports
8. **Event logs**: use FilterHashtable/XML filters, not heavy `Get-EventLog`
9. **WSL2 for Linux tasks** on Windows instead of native porting
10. **Back up the registry** before editing it

## Anti-patterns
- ❌ Parsing `command | select-string` instead of `Where-Object`
- ❌ Running everything elevated without need
- ❌ Opening all firewall ports or disabling the firewall
- ❌ Storing plaintext credentials in scripts/registry
- ❌ Disabling UAC or Windows Defender for "performance"
- ❌ Editing the registry without a backup/export
- ❌ Enabling SMBv1 or other legacy protocols
- ❌ Ignoring Windows Update security patches

## Verification

### Unit Verification
```powershell
Get-Service -Name MyApp | Select Status, StartType          # Running / Automatic
Get-NetFirewallProfile | Select Name, Enabled, DefaultInboundAction  # True / Block
Get-ScheduledTask -TaskName DailyBackup | Select State       # Ready
Get-NetTCPConnection -LocalPort 443 -State Listen            # Listen
```

### Integration Checks
```powershell
Invoke-Command -ComputerName srv1 -ScriptBlock { Get-Date }   # remote works
Get-Volume | Where-Object DriveLetter | Select DriveLetter, @{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB,1)}}
```

## Examples

### Complete Hardening Script
```powershell
#Requires -RunAsAdministrator
param([switch]$SkipUpdate)

Get-NetFirewallProfile | Set-NetFirewallProfile -DefaultInboundAction Block
New-NetFirewallRule -DisplayName "Allow RDP"      -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow
New-NetFirewallRule -DisplayName "Allow WinRM"    -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
New-NetFirewallRule -DisplayName "Allow HTTPS"    -Direction Inbound -Protocol TCP -LocalPort 443  -Action Allow
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd; Set-Service sshd -StartupType Automatic

if (-not $SkipUpdate) { Install-Module PSWindowsUpdate -Force; Get-WUInstall -AcceptAll -AutoReboot }
```

### WSL2 Full Stack
```powershell
wsl --install -d Ubuntu-22.04
wsl -d Ubuntu-22.04 -- bash -c "sudo apt update && sudo apt install -y build-essential curl git docker.io"
Copy-Item C:\app\config.yaml \\wsl$\Ubuntu-22.04\opt\app\config.yaml
```