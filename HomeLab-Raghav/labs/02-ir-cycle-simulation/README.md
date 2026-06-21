# Lab 02 — Incident Response Cycle Simulation

**Status:** ✅ Complete | **Date:** June 2026 | **Lab ID:** HCLAB-IR-001

---

## Overview

Full purple-team exercise simulating a realistic kill chain against HomeLab Corp. Executed reconnaissance, SSH brute force, SMB brute force, and aggressive service enumeration from KALI01. Monitored every attack phase in Wazuh SIEM in real time, then wrote a professional Incident Response report mapping all findings to MITRE ATT&CK.

This lab demonstrates the complete SOC analyst workflow: detect → analyze → document → remediate.

---

## Environment

| VM | Role | IP |
|----|------|----|
| KALI01 | Attacker | 192.168.56.30 |
| DC01 | Target — Domain Controller | 192.168.56.10 |
| WEB01 | Target — Web/SSH Server | 192.168.56.20 |
| Wazuh | SIEM | 192.168.56.104 |

---

## Attack Phases

### Phase 1 — Reconnaissance (Nmap SYN Scan)

```bash
# Half-open SYN scan — ports 1-1000 on DC01
sudo nmap -sS -p 1-1000 192.168.56.10

# Also scan WEB01
sudo nmap -sS -p 1-1000 192.168.56.20

# Aggressive scan with OS/version detection
sudo nmap -A -T4 192.168.56.10
```

**Expected DC01 Open Ports:**

| Port | Service | Significance |
|------|---------|--------------|
| 53 | DNS | Confirms DC is DNS server |
| 88 | Kerberos | Confirms Domain Controller |
| 139/445 | SMB | File sharing — brute force target |
| 389/636 | LDAP/LDAPS | Active Directory confirmed |

**MITRE:** T1046 — Network Service Scanning | T1595.001 — Active Scanning

**Wazuh Detection:** Rule 40101 (port scan detected)

---

### Phase 2 — SSH Brute Force (WEB01)

```bash
# Unzip rockyou wordlist if needed
sudo gunzip /usr/share/wordlists/rockyou.txt.gz

# Brute force SSH on WEB01
hydra -l administrator -P /usr/share/wordlists/rockyou.txt \
    192.168.56.20 ssh -t 4 -V -f

# Also try the actual Linux username
hydra -l raghav -P /usr/share/wordlists/rockyou.txt \
    192.168.56.20 ssh -t 4 -V -f
```

> Let Hydra run 30–60 seconds to generate enough failed auth events for Wazuh to trigger. Goal is detection, not credential compromise.

**MITRE:** T1110.001 — Brute Force: Password Guessing

**Wazuh Detection:** Rule 5710 (non-existent user), Rule 5720 (brute force — Level 10)

---

### Phase 3 — SMB Brute Force (DC01)

```bash
# SMB brute force against Domain Controller
hydra -l administrator -P /usr/share/wordlists/rockyou.txt \
    192.168.56.10 smb -V

# Alternative with CrackMapExec
crackmapexec smb 192.168.56.10 -u administrator \
    -p /usr/share/wordlists/rockyou.txt
```

**Verify on DC01 (Event Viewer):**
```
Start → Event Viewer → Windows Logs → Security → Filter: Event ID 4625
```

**MITRE:** T1110.001 — Brute Force | T1021.002 — SMB/Windows Admin Shares

**Wazuh Detection:** Rule 18116 (multiple auth failures), Rule 18152 (brute force — Critical)

---

### Phase 4 — Aggressive Service Enumeration

```bash
# OS detection + version + scripts + traceroute
sudo nmap -A -T4 192.168.56.10

# Version detection only (quieter)
sudo nmap -sV -p 22,80,135,139,445 192.168.56.10

# Full attack chain (run all at once for maximum alert coverage)
sudo nmap -sS -p 1-1000 192.168.56.10
sudo nmap -sS -p 1-1000 192.168.56.20
hydra -l administrator -P /usr/share/wordlists/rockyou.txt 192.168.56.20 ssh -t 4 -V &
hydra -l administrator -P /usr/share/wordlists/rockyou.txt 192.168.56.10 smb -V &
sudo nmap -A -T4 192.168.56.10
sleep 60 && kill %1 %2
```

**MITRE:** T1082 — System Information Discovery

---

### Phase 5 — Monitor in Wazuh

**Navigate to:** `https://192.168.56.104` → Security Events → Set filter: Last 1 Hour

**Key filters:**
```
agent.name: DC01
agent.name: WEB01
data.win.system.eventID: "4625"
rule.groups: "authentication_failed"
rule.level: [10 TO 15]
```

**Alert Rule Reference:**

| Rule ID | Description | Severity | Phase |
|---------|-------------|----------|-------|
| 5710 | SSH: login with non-existent user | Medium | SSH Brute |
| 5720 | SSH: multiple authentication failures | High | SSH Brute |
| 18116 | Windows: multiple auth failures | High | SMB Brute |
| 18152 | Windows: brute force detected | Critical | SMB Brute |
| 40101 | Network scan detected | Medium | Nmap Recon |
| 40111 | Multiple scan sources | High | Aggressive Scan |

---

## MITRE ATT&CK Mapping

| TTP ID | Technique | Tactic | Tool | Observable |
|--------|-----------|--------|------|------------|
| T1046 | Network Service Scanning | Discovery | Nmap -sS | Wazuh Rule 40101 |
| T1082 | System Information Discovery | Discovery | Nmap -A | OS fingerprint |
| T1110.001 | Password Guessing (SSH) | Credential Access | Hydra | Rule 5720, /var/log/auth.log |
| T1110.001 | Password Guessing (SMB) | Credential Access | Hydra | Rule 18152, Event ID 4625 |
| T1021.002 | SMB/Windows Admin Shares | Lateral Movement | Hydra SMB | Port 445 auth failures |
| T1595.001 | Active Scanning: IP Blocks | Reconnaissance | Nmap /24 | Multiple hosts scanned |

---

## Indicators of Compromise (IOCs)

| IOC Type | Value | Context |
|----------|-------|---------|
| Source IP | 192.168.56.30 | KALI01 — all attack traffic |
| Target IP | 192.168.56.10 | DC01 — SMB brute + port scan |
| Target IP | 192.168.56.20 | WEB01 — SSH brute force |
| Port | 445/tcp | SMB — brute force target |
| Port | 22/tcp | SSH — brute force target |
| Tool | Nmap SYN scan | Half-open TCP to ports 1-1000 |
| Tool | Hydra login attempts | Rapid sequential auth failures |
| Windows Event | Event ID 4625 | Account failed to logon — DC01 |
| Wazuh Rule | 5720 | SSH brute force — WEB01 |
| Wazuh Rule | 18152 | Windows brute force — DC01 |
| Username Targeted | administrator | Used in both SSH and SMB attacks |
| Wordlist | rockyou.txt | Common password dictionary |

---

## IR Report (HCLAB-IR-001)

### Executive Summary

On June 2026, HomeLab Corp's Wazuh SIEM detected a series of reconnaissance and brute force attacks originating from internal IP 192.168.56.30 (KALI01). The attack targeted the domain controller (DC01) via SMB and port scan, and the web server (WEB01) via SSH brute force. No credentials were successfully compromised. The attack was simulated as a purple team exercise and all phases were fully detected by Wazuh.

**Severity:** HIGH | **Status:** CONTAINED (no credentials compromised)

### Incident Timeline

```
14:02 — Recon       — Nmap SYN scan from 192.168.56.30 → DC01 (ports 1-1000)
14:03 — Recon       — Nmap SYN scan from 192.168.56.30 → WEB01 (ports 1-1000)
14:05 — Cred Access — SSH brute force started (Hydra) → WEB01:22
14:06 — Cred Access — SMB brute force started (Hydra) → DC01:445
14:08 — Discovery   — Aggressive Nmap (-A) scan → DC01
14:10 — Detection   — Wazuh Rule 18152 fired — brute force confirmed
14:12 — Response    — Attack traffic stopped, investigation initiated
```

### Containment & Remediation

```powershell
# DC01 — Block attacker IP at Windows Firewall
New-NetFirewallRule -DisplayName 'Block KALI01' `
    -Direction Inbound `
    -RemoteAddress 192.168.56.30 `
    -Action Block

# DC01 — Enable Account Lockout Policy
# gpedit.msc → Computer Config → Account Policies → Account Lockout
# Threshold: 5 attempts | Duration: 30 min | Reset: 30 min
```

```bash
# WEB01 — Install and configure fail2ban
sudo apt install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit [sshd] section:
# enabled = true | maxretry = 5 | bantime = 3600 | findtime = 600
sudo systemctl enable fail2ban && sudo systemctl start fail2ban
sudo fail2ban-client status sshd

# WEB01 — UFW rate limiting
sudo ufw default deny incoming
sudo ufw allow from 192.168.56.1 to any port 22
sudo ufw deny from 192.168.56.30
sudo ufw enable
```

### Lessons Learned

1. Wazuh SIEM successfully detected all four attack phases — detection coverage confirmed.
2. No account lockout policy was configured — unlimited brute force attempts allowed. **Remediated.**
3. SSH accessible from all internal IPs — restrict to management subnet only.
4. Port scanning detected but not blocked — evaluate network IPS for future hardening.
5. Lab demonstrates the value of SIEM correlation rules and centralized log monitoring.

---

## Screenshots

### Phase 1 — Reconnaissance

**Kali — Nmap Scan of WEB01 (192.168.56.20) — Open Ports Discovered**
![Nmap Scan Results](screenshots/01_kali_nmap_scan_target_open_ports.png)
> Nmap reveals open ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 3306 (MySQL), 3389 (RDP). This output directly feeds Phase 2 attack targeting.

---

## Resources

- [MITRE ATT&CK](https://attack.mitre.org)
- [Hydra Documentation](https://github.com/vanhauser-thc/thc-hydra)
- [Wazuh Rule Reference](https://documentation.wazuh.com/current/user-manual/ruleset/)
