#!/usr/bin/env bash
# HomeLab Corp — WEB01 Initial Setup Script
# Idempotent: safe to run multiple times

set -euo pipefail

WAZUH_MANAGER_IP="192.168.56.101"
STATIC_IP="192.168.56.101"
DOMAIN="homecorp.local"
DC_IP="192.168.56.10"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
need_root() { [[ $EUID -eq 0 ]] || { echo "Run as root (sudo $0)"; exit 1; }; }
need_root

# ── 1. System Update ─────────────────────────────────────────────────────────
log "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y curl wget git unzip net-tools build-essential

# ── 2. Node.js (via NodeSource) ───────────────────────────────────────────────
if ! command -v node &>/dev/null; then
    log "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi
log "Node $(node --version) | npm $(npm --version)"

# ── 3. PM2 ───────────────────────────────────────────────────────────────────
if ! command -v pm2 &>/dev/null; then
    log "Installing PM2..."
    npm install -g pm2 --quiet
fi

# ── 4. Apache + PHP + MySQL ───────────────────────────────────────────────────
log "Installing Apache, PHP, MySQL..."
apt-get install -y apache2 php libapache2-mod-php php-mysql mysql-server
systemctl enable apache2 mysql
systemctl start apache2 mysql

# ── 5. UFW Firewall ───────────────────────────────────────────────────────────
log "Configuring UFW..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
# Wazuh agent ports
ufw allow from "$DC_IP" to any port 1514
ufw allow from "$DC_IP" to any port 1515

# ── 6. fail2ban ───────────────────────────────────────────────────────────────
log "Installing fail2ban..."
apt-get install -y fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Patch SSH jail settings
python3 - <<'PY'
import re, pathlib
path = pathlib.Path('/etc/fail2ban/jail.local')
content = path.read_text()
content = re.sub(r'\[sshd\].*?(?=\[)', '[sshd]\nenabled = true\nmaxretry = 5\nbantime  = 3600\nfindtime = 600\n\n', content, flags=re.DOTALL)
path.write_text(content)
PY

systemctl enable fail2ban
systemctl start fail2ban

# ── 7. Web Directory ──────────────────────────────────────────────────────────
log "Setting up web directories..."
WEB_DIR="/var/www/raghav-batman"
mkdir -p "$WEB_DIR"
chown -R www-data:www-data /var/www/html
if [[ ! -f "$WEB_DIR/package.json" ]]; then
    log "NOTE: Copy portfolio files to $WEB_DIR then run: npm install && pm2 start backend/server.js --name portfolio"
fi

# ── 8. File Integrity Monitoring prep ─────────────────────────────────────────
log "Setting inotify limit for Wazuh FIM..."
grep -q 'inotify.max_user_watches' /etc/sysctl.conf || \
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
sysctl -p -q

# ── 9. Wazuh Agent ────────────────────────────────────────────────────────────
if ! systemctl list-units --type=service | grep -q wazuh-agent; then
    log "Installing Wazuh Agent (Manager: $WAZUH_MANAGER_IP)..."
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH \
        | gpg --no-default-keyring \
              --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg \
              --import
    chmod 644 /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] \
https://packages.wazuh.com/4.x/apt/ stable main" \
        | tee /etc/apt/sources.list.d/wazuh.list
    apt-get update -qq
    WAZUH_MANAGER="$WAZUH_MANAGER_IP" apt-get install -y wazuh-agent
    systemctl enable wazuh-agent
    systemctl start wazuh-agent
else
    log "Wazuh agent already installed — skipping."
fi

# ── 10. DNS ───────────────────────────────────────────────────────────────────
if [[ -f /etc/systemd/resolved.conf ]]; then
    log "Configuring DNS to use DC01 ($DC_IP)..."
    cat > /etc/systemd/resolved.conf <<RESOLVED
[Resolve]
DNS=$DC_IP
FallbackDNS=8.8.8.8
Domains=$DOMAIN
RESOLVED
    systemctl restart systemd-resolved
fi

# ── Summary ───────────────────────────────────────────────────────────────────
log "Setup complete. Verify:"
log "  ip addr show         (enp0s8 should have $STATIC_IP)"
log "  pm2 status           (portfolio: online — after deploying code)"
log "  sudo ufw status      (firewall rules active)"
log "  sudo fail2ban-client status sshd"
log "  sudo systemctl status wazuh-agent"
