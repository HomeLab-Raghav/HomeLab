# Lab 09 — Firewall Misconfiguration Analysis

**Status:** 📋 Planned | **Difficulty:** Intermediate–Advanced

---

## Overview

Intentionally misconfigure and audit firewall rules on WEB01 (UFW/iptables) and DC01 (Windows Firewall). Use Nmap to enumerate exposed services, identify gaps attackers can exploit, then remediate and re-verify. Covers the full audit loop: scan → find → document → fix → re-scan.

**MITRE ATT&CK:** T1562.004 — Impair Defenses: Disable or Modify System Firewall

---

## Prerequisites

- [ ] WEB01 running with UFW installed: `sudo ufw status`
- [ ] DC01 accessible from KALI01 with Nmap
- [ ] Wazuh running (optional — to capture firewall rule change events)

---

## Phase 01 — Baseline Scan (Before Misconfiguration)

Document the current attack surface before any changes.

```bash
# From KALI01 — full TCP port scan of WEB01
sudo nmap -sV -p- 192.168.56.101 -oN /tmp/web01_baseline.txt

# From KALI01 — Windows service scan of DC01
sudo nmap -sV --script=smb-security-mode 192.168.56.10 -oN /tmp/dc01_baseline.txt
```

Record open ports. Expected baseline for WEB01:
- Port 22 (SSH)
- Port 80 (Apache HTTP)
- Port 3000 (Node.js)

Expected for DC01:
- Port 53 (DNS)
- Port 88 (Kerberos)
- Port 389 (LDAP)
- Port 445 (SMB)
- Port 3389 (RDP)

---

## Phase 02 — UFW Misconfigurations on WEB01

### Misconfiguration 1 — Disable UFW (Most Dangerous)

```bash
# INTENTIONAL MISCONFIGURATION — for lab purposes
sudo ufw disable

# All ports now exposed. Re-scan from KALI01:
sudo nmap -sV -p- 192.168.56.101
```

What you find: additional services exposed (MySQL on 3306, Wazuh agent ports).

**Impact:** Any service binding to a port is now reachable from any network node.

```bash
# Remediation — re-enable with proper rules
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw status numbered
```

### Misconfiguration 2 — Allow Any (Wildcard Rule)

```bash
# INTENTIONAL MISCONFIGURATION
sudo ufw allow from any to any

# This allows ALL traffic — disabling UFW without disabling it
sudo ufw status verbose
```

Spot the problem: the "allow any" rule overrides all deny rules. Order matters in UFW.

```bash
# Fix — remove the wildcard rule
sudo ufw status numbered
# Identify the rule number for "ALLOW IN  Anywhere" entries
sudo ufw delete <rule_number>
```

### Misconfiguration 3 — RDP Exposed to Kali

```bash
# Open port 3389 to all (simulating a misconfigured DC01 RDP exposure)
sudo ufw allow 3389/tcp

# From KALI01 — verify it's visible
nmap -p 3389 192.168.56.101
```

**Impact:** RDP brute force surface opened to attacker VM.

```bash
# Fix — restrict RDP to management IP only
sudo ufw delete allow 3389/tcp
sudo ufw allow from 192.168.56.1 to any port 3389
```

---

## Phase 03 — Windows Firewall Misconfiguration (DC01)

### Misconfiguration 1 — Disable Windows Firewall

```powershell
# Run as Administrator on DC01
# INTENTIONAL MISCONFIGURATION
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Verify — Wazuh should alert Event ID 4950 (firewall setting changed)
# Also Event ID 4946 (firewall rule modified)
Get-NetFirewallProfile | Select-Object Name, Enabled
```

**From KALI01 — re-scan:**
```bash
sudo nmap -sV -p 1-1024 192.168.56.10
```

What you find: more services visible that were previously blocked by firewall.

```powershell
# Remediation — re-enable firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

### Misconfiguration 2 — Expose WinRM (Remote Management)

```powershell
# Enable WinRM and allow it through firewall
Enable-PSRemoting -Force
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -Enabled True

# This allows lateral movement via PSRemoting from attacker
# From KALI01 (or any Windows box):
# Enter-PSSession -ComputerName 192.168.56.10 -Credential homecorp\administrator
```

```powershell
# Remediation
Disable-PSRemoting -Force
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -Enabled False
```

---

## Phase 04 — iptables Deep Dive (WEB01)

View and audit raw iptables rules (UFW wraps iptables):

```bash
# View all iptables rules including UFW's rules
sudo iptables -L -v -n

# View NAT table
sudo iptables -t nat -L -v -n

# Find permissive rules (ACCEPT from 0.0.0.0/0)
sudo iptables -L INPUT -v -n | grep -v DROP | grep ACCEPT
```

**Misconfiguration Scenario — Remove Default DROP:**
```bash
# INTENTIONAL MISCONFIGURATION — this removes the default deny
sudo iptables -P INPUT ACCEPT

# All traffic now accepted regardless of rules
# Remediation:
sudo iptables -P INPUT DROP
sudo ufw enable    # restores UFW-managed rules
```

---

## Phase 05 — Audit and Verify

### Re-scan After Remediation

```bash
# WEB01 — final clean state
sudo nmap -sV -p- 192.168.56.101 -oN /tmp/web01_remediated.txt
diff /tmp/web01_baseline.txt /tmp/web01_remediated.txt

# DC01 — final clean state
sudo nmap -sV 192.168.56.10 -oN /tmp/dc01_remediated.txt
```

### Wazuh Audit Queries

```
# Windows firewall changes (DC01)
data.win.system.eventID: "4946" OR data.win.system.eventID: "4950"

# UFW rule changes
rule.groups: "firewall"
```

---

## Findings Summary

| Misconfiguration | Impact | MITRE TTP |
|-----------------|--------|----------|
| UFW disabled | All services exposed | T1562.004 |
| UFW allow-any | All deny rules bypassed | T1562.004 |
| RDP open to all | Brute force surface | T1110 |
| Windows FW disabled | All services exposed | T1562.004 |
| WinRM enabled | Lateral movement via PSRemoting | T1021.006 |
| iptables default ACCEPT | No packet filtering | T1562.004 |

---

## Screenshots Needed

- [ ] Nmap baseline scan output (before misconfiguration)
- [ ] Nmap post-misconfiguration showing more ports open
- [ ] `sudo ufw status verbose` — after each misconfiguration
- [ ] Wazuh alert for Event ID 4946 (firewall rule modified)
- [ ] `sudo iptables -L -v -n` — before/after
- [ ] Nmap remediated output matching baseline

---

## Key Learnings

- UFW rules are ordered — an "allow any" rule above specific deny rules defeats the deny rules entirely. Always check rule order: `sudo ufw status numbered`.
- Disabling Windows Firewall generates Event ID 4950 (Firewall Setting Changed) — a high-value detection opportunity in Wazuh.
- Nmap before/after diff is the standard evidence format for a firewall audit finding — include both scans in any report.
- WinRM (port 5985) is a high-value lateral movement path — it should never be open to untrusted segments.
