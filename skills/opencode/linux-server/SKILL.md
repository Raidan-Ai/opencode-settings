---
name: linux-server
description: Linux/Ubuntu/Debian server administration including SSH, systemd, journald, networking (ip, ss, nftables), nginx/caddy web servers, DNS, TLS (certbot), firewall, storage (LVM), permissions, process management, server hardening, and debugging. Activate for any Linux server setup, administration, or troubleshooting task.
---

# Linux Server Skill

## Purpose
Provides comprehensive Linux server administration capabilities for Ubuntu/Debian systems: SSH hardening, systemd service management, journald logging, networking configuration, web servers (nginx, Caddy), DNS, TLS certificates, firewall rules (nftables/ufw), storage management (LVM), permissions, process management, server hardening, and debugging.

## When to Activate
- Setting up or hardening a new Linux server
- Configuring SSH access (key-only, fail2ban)
- Creating or managing systemd services/timers
- Configuring nginx or Caddy reverse proxy
- Setting up TLS certificates with certbot
- Managing firewall rules (nftables, ufw)
- Storage management (df, lsblk, LVM, mount)
- Debugging server issues (journalctl, dmesg, top)
- Process management and monitoring
- DNS configuration

## Core Knowledge

### SSH Hardening
```bash
# Edit /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers deploy
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

# Restart SSH
sudo systemctl restart sshd
```

### systemd Services
```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Application
After=network.target
Wants=postgresql.service

[Service]
Type=simple
User=app
Group=app
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/bin/server --config /opt/myapp/config.yaml
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=myapp
Environment=NODE_ENV=production
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/myapp/data

[Install]
WantedBy=multi-user.target
```

```bash
# Manage services
sudo systemctl daemon-reload
sudo systemctl enable --now myapp
sudo systemctl status myapp
sudo journalctl -u myapp -f
```

### journald Logging
```bash
# View logs for a service
journalctl -u myapp -f               # Follow live
journalctl -u myapp --since today    # Today only
journalctl -u myapp -n 100           # Last 100 lines
journalctl -u myapp --since "2024-01-01" --until "2024-01-02"

# System logs
journalctl -b                         # Current boot
journalctl -b -1                      # Previous boot
journalctl --disk-usage               # Check journal size

# Persist logs
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
```

### Networking
```bash
# View interfaces and IPs
ip addr show
ip -br addr show

# Routing
ip route show

# DNS resolution
resolvectl status
dig example.com
nslookup example.com

# Open ports
ss -tlnp              # TCP listening ports
ss -ulnp              # UDP listening ports
ss -s                 # Connection statistics

# Active connections
ss -tnp state established
```

### Firewall (nftables)
```bash
# List rules
sudo nft list ruleset

# Flush all rules
sudo nft flush ruleset

# Basic stateful firewall
sudo nft add table inet filter
sudo nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter input iif lo accept
sudo nft add rule inet filter input tcp dport { 22, 80, 443 } accept
sudo nft add rule inet filter input icmp type echo-request accept
```

### UFW (Simpler Alternative)
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

### Nginx Reverse Proxy
```nginx
# /etc/nginx/sites-available/myapp
server {
    listen 80;
    server_name myapp.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name myapp.example.com;

    ssl_certificate /etc/letsencrypt/live/myapp.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myapp.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ws {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### Caddy (Auto-TLS)
```
# /etc/caddy/Caddyfile
myapp.example.com {
    reverse_proxy localhost:3000
}

api.example.com {
    reverse_proxy localhost:8000
}
```

```bash
sudo systemctl restart caddy
# TLS certificates are automatic via ACME
```

### TLS Certificates (Certbot)
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot certonly --nginx -d myapp.example.com

# Auto-renewal (systemd timer)
sudo systemctl enable --now certbot.timer
sudo systemctl list-timers | grep certbot

# Test renewal
sudo certbot renew --dry-run
```

### Storage Management
```bash
# Disk usage
df -h                    # Filesystem usage
df -ih                   # Inode usage

# Block devices
lsblk -f                 # List block devices with filesystems
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE

# LVM Setup
sudo pvcreate /dev/sdb1                    # Create physical volume
sudo vgcreate data_vg /dev/sdb1           # Create volume group
sudo lvcreate -L 50G -n app_lv data_vg   # Create logical volume
sudo mkfs.ext4 /dev/data_vg/app_lv       # Format
sudo mkdir /data && sudo mount /dev/data_vg/app_lv /data

# Extend LV
sudo lvextend -L +10G /dev/data_vg/app_lv
sudo resize2fs /dev/data_vg/app_lv       # ext4

# Find large files
du -sh /* 2>/dev/null | sort -rh | head -20
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null
```

### Permissions
```bash
# Numeric (octal) mode
chmod 755 /opt/myapp          # rwxr-xr-x
chmod 600 /etc/secret.conf    # rw-------
chown app:app /opt/myapp -R

# ACLs for finer control
setfacl -m u:www-data:rX /var/www/shared
getfacl /var/www/shared

# Sticky bit (shared directories)
chmod 1777 /tmp
```

### Process Management
```bash
# View processes
ps aux --sort=-%mem | head -20
top -bn1 | head -30
htop

# Kill processes
kill -9 <PID>               # Force kill (last resort)
kill -15 <PID>              # Graceful shutdown

# Find processes by name
pgrep -a myapp
pidof myapp

# Limits
ulimit -a                  # Current limits
cat /proc/<PID>/limits     # Process limits
```

### Server Hardening
```bash
# Fail2ban
sudo apt install fail2ban
sudo systemctl enable --now fail2ban
# /etc/fail2ban/jail.local:
# [sshd]
# enabled = true
# maxretry = 3
# bantime = 3600

# Automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Kernel hardening (/etc/sysctl.conf)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
kernel.randomize_va_space = 2

# Apply
sudo sysctl -p
```

## Workflow

### 1. Initial Server Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Create deploy user
sudo adduser deploy
sudo usermod -aG sudo deploy

# SSH keys
sudo mkdir -p /home/deploy/.ssh
echo "ssh-rsa AAAA..." | sudo tee /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys

# Harden SSH
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Install fail2ban
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban
```

### 2. Deploy Application
```bash
# Create app directory
sudo mkdir -p /opt/myapp/data
sudo useradd -r -s /bin/false app
sudo chown -R app:app /opt/myapp

# Copy binary/files
sudo -u app cp -r ./dist/* /opt/myapp/

# Create systemd service
sudo cp myapp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now myapp
```

### 3. Configure Reverse Proxy + TLS
```bash
# Install nginx
sudo apt install -y nginx

# Copy nginx config
sudo cp myapp.conf /etc/nginx/sites-available/myapp
sudo ln -sf /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# Get TLS certificate
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d myapp.example.com
```

## Tools
```bash
# System info
uname -a
lsb_release -a
uptime
free -h

# Disk
df -h
lsblk
du -sh /var/*

# Network
ip addr
ss -tlnp
curl -I http://localhost

# Services
systemctl list-units --type=service --state=running
journalctl --disk-usage
```

### MCP Integration
```json
{
  "mcpServers": {
    "linux-admin": {
      "command": "npx",
      "args": ["-y", "linux-admin-mcp"],
      "description": "Linux server administration MCP server",
      "tools": ["check_service", "view_logs", "check_disk", "check_network"]
    }
  }
}
```

## Best Practices
1. **SSH key-only auth**: Disable password auth, use ed25519 keys
2. **Fail2ban**: Auto-ban repeated SSH failures
3. **Non-root app user**: Create dedicated user per application
4. **systemd for services**: Use Type=simple, Restart=on-failure, NoNewPrivileges=true
5. **journald for logs**: Use -u flag and SyslogIdentifier for per-service logs
6. **UFW/nftables default deny**: Block all inbound except explicitly allowed ports
7. **Certbot auto-renewal**: systemd timer for automated certificate renewal
8. **LVM for storage**: Logical volumes for flexible disk management
9. **unattended-upgrades**: Automatic security patching
10. **Log rotation**: Use logrotate for custom application logs

## Anti-patterns
- ❌ Running applications as root
- ❌ Password-based SSH authentication
- ❌ No firewall (all ports open to internet)
- ❌ Using `latest` tag for system packages
- ❌ Ignoring `journalctl` logs until failures cascade
- ❌ Manual service management instead of systemd
- ❌ No TLS on public-facing services
- ❌ Storing application data on root partition without monitoring
- ❌ Not setting resource limits (ulimits, systemd MemoryMax)
- ❌ Ignoring kernel updates

## Verification

### Unit Tests
```bash
# Verify SSH is hardened
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication"
# Expected: permitrootlogin no, passwordauthentication no

# Verify nginx config
sudo nginx -t
# Expected: syntax is ok, test is successful

# Verify systemd service exists and is enabled
systemctl is-enabled myapp
# Expected: enabled

# Verify firewall is active
sudo ufw status | head -1
# Expected: Status: active

# Verify fail2ban is running
sudo fail2ban-client status
# Expected: Status for the jail: sshd

# Verify certbot renewal
sudo certbot renew --dry-run
# Expected: Congratulations, all renewals succeeded
```

### Integration Checks
```bash
# Full service stack verification
systemctl status nginx myapp postgresql redis
curl -I https://myapp.example.com  # 200 OK
journalctl -u myapp --since "10 minutes ago" --no-pager
df -h / /data
```

## Examples

### Complete Production Server Setup Script
```bash
#!/bin/bash
set -euo pipefail

# ── System Update ──
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx fail2ban \
  unattended-upgrades curl wget git

# ── Create App User ──
sudo useradd -r -m -d /opt/myapp -s /bin/bash app

# ── Deploy Application ──
sudo mkdir -p /opt/myapp/{bin,data,config}
sudo cp ./myapp /opt/myapp/bin/
sudo chmod +x /opt/myapp/bin/myapp
sudo chown -R app:app /opt/myapp

# ── systemd Service ──
sudo tee /etc/systemd/system/myapp.service > /dev/null << 'EOF'
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=app
Group=app
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/bin/myapp --config /opt/myapp/config/app.yaml
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/myapp/data
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now myapp

# ── Nginx ──
sudo tee /etc/nginx/sites-available/myapp > /dev/null << 'EOF'
server {
    listen 80;
    server_name myapp.example.com;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    server_name myapp.example.com;
    ssl_certificate /etc/letsencrypt/live/myapp.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myapp.example.com/privkey.pem;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# ── TLS ──
sudo certbot --nginx -d myapp.example.com --non-interactive --agree-tos -m admin@example.com
sudo systemctl enable --now certbot.timer

# ── Firewall ──
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# ── Fail2ban ──
sudo systemctl enable --now fail2ban

# ── Automatic Updates ──
sudo dpkg-reconfigure -plow unattended-upgrades

echo "Server setup complete. Verify with: systemctl status myapp"
```

### systemd Timer (Cron Alternative)
```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Backup application data

[Service]
Type=oneshot
User=app
ExecStart=/opt/myapp/scripts/backup.sh
StandardOutput=journal
StandardError=journal
```

```bash
sudo systemctl enable --now backup.timer
sudo journalctl -u backup -f
```

### LVM Workflow
```bash
# 1. Create PV
sudo pvcreate /dev/sdb

# 2. Create VG
sudo vgcreate data_vg /dev/sdb

# 3. Create LV
sudo lvcreate -L 100G -n app_lv data_vg

# 4. Format
sudo mkfs.ext4 /dev/data_vg/app_lv

# 5. Mount
echo '/dev/data_vg/app_lv /data ext4 defaults 0 2' | sudo tee -a /etc/fstab
sudo mount /data

# 6. Extend when needed
sudo lvextend -L +20G /dev/data_vg/app_lv
sudo resize2fs /dev/data_vg/app_lv
```
