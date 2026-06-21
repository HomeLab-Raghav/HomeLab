# Lab 10 — Active Directory + Web Server Integration

**Status:** 📋 Planned | **Difficulty:** Advanced

---

## Overview

Integrate WEB01 (Ubuntu) into the `homecorp.local` Active Directory domain. Configure WEB01 to authenticate users against DC01 using SSSD + Kerberos, enable Apache to serve domain-authenticated pages, and monitor all authentication events across both systems in Wazuh. This lab simulates a real enterprise environment where web servers are domain-joined.

**End State:** WEB01 is a domain member of `homecorp.local`. Domain users can SSH into WEB01 using their AD credentials. Wazuh correlates Windows Kerberos events (DC01) with Linux auth events (WEB01).

---

## Prerequisites

- [ ] Lab 01 complete — DC01 running with `homecorp.local` domain configured
- [ ] Lab 05 complete — WEB01 running at 192.168.56.101
- [ ] Lab 07 complete — Wazuh agents active on both DC01 and WEB01
- [ ] WEB01 can resolve DC01: `nslookup dc01.homecorp.local 192.168.56.10`

---

## Phase 01 — DNS Configuration (WEB01)

WEB01 must use DC01 as its DNS server for AD integration to work.

```bash
# Configure WEB01 to use DC01's DNS
sudo nano /etc/systemd/resolved.conf
```

```ini
[Resolve]
DNS=192.168.56.10
FallbackDNS=8.8.8.8
Domains=homecorp.local
```

```bash
sudo systemctl restart systemd-resolved

# Verify DNS resolution
nslookup homecorp.local 192.168.56.10
nslookup dc01.homecorp.local 192.168.56.10
ping dc01.homecorp.local
```

Expected: all three resolve/respond successfully.

---

## Phase 02 — Required Packages

```bash
sudo apt update
sudo apt install -y \
    realmd \
    sssd \
    sssd-tools \
    libnss-sss \
    libpam-sss \
    adcli \
    samba-common-bin \
    oddjob \
    oddjob-mkhomedir \
    packagekit \
    krb5-user
```

During krb5-user install, when prompted:
- Default Kerberos version 5 realm: `HOMECORP.LOCAL`
- Kerberos servers: `dc01.homecorp.local`
- Administrative server: `dc01.homecorp.local`

---

## Phase 03 — Discover and Join the Domain

```bash
# Discover the domain
sudo realm discover homecorp.local
```

Expected output:
```
homecorp.local
  type: kerberos
  realm-name: HOMECORP.LOCAL
  domain-name: homecorp.local
  configured: no
  server-software: active-directory
  client-software: sssd
  required-package: sssd-tools
  required-package: adcli
  required-package: realmd
  required-package: samba-common-bin
```

```bash
# Join the domain (requires DC01 Administrator password)
sudo realm join --user=administrator homecorp.local
# Enter DC01 administrator password when prompted
```

```bash
# Verify WEB01 is joined
realm list
# Expected: homecorp.local — configured: kerberos-member
```

**On DC01 — verify WEB01 appears as a computer account:**
```powershell
Get-ADComputer -Filter * | Where-Object {$_.Name -eq "WEB01"}
```

---

## Phase 04 — SSSD Configuration

```bash
sudo nano /etc/sssd/sssd.conf
```

```ini
[sssd]
domains = homecorp.local
config_file_version = 2
services = nss, pam

[domain/homecorp.local]
ad_domain = homecorp.local
krb5_realm = HOMECORP.LOCAL
realmd_tags = manages-system joined-with-adcli
cache_credentials = True
id_provider = ad
fallback_homedir = /home/%u@%d
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = True
enumerate = False
access_provider = ad
```

```bash
sudo chmod 600 /etc/sssd/sssd.conf
sudo systemctl restart sssd
sudo systemctl enable sssd
```

---

## Phase 05 — PAM Configuration (Home Directory Auto-Create)

```bash
# Auto-create home dirs for domain users on first login
sudo pam-auth-update --enable mkhomedir

# Or manually add to /etc/pam.d/common-session:
echo "session required pam_mkhomedir.so skel=/etc/skel umask=077" | \
    sudo tee -a /etc/pam.d/common-session
```

---

## Phase 06 — Test Domain Authentication

### SSH Login with AD Credentials

```bash
# From KALI01 or host machine — SSH to WEB01 using a domain user
ssh 'testuser01@homecorp.local'@192.168.56.101
# Password: the AD user's password set during Lab 01

# Alternative format
ssh testuser01@HOMECORP.LOCAL@192.168.56.101
```

```bash
# Verify ID after login
id
# Expected: uid=XXXXXXXXX(testuser01@homecorp.local) gid=...
whoami
# Expected: testuser01@homecorp.local
```

### Look Up AD Users from WEB01

```bash
# Get AD user info from Linux
id 'testuser01@homecorp.local'
getent passwd 'testuser01@homecorp.local'
```

---

## Phase 07 — Kerberos Ticket (Manual Test)

```bash
# Get Kerberos ticket manually
kinit administrator@HOMECORP.LOCAL
# Enter password

# Verify ticket
klist
# Expected: Credentials cache: API:...
#           Principal: administrator@HOMECORP.LOCAL
#           Valid starting: [timestamp]

# Destroy ticket after test
kdestroy
```

---

## Phase 08 — Apache AD Authentication (Optional)

Serve a page that requires AD credential authentication via Kerberos.

```bash
sudo apt install -y libapache2-mod-auth-kerb
sudo a2enmod auth_kerb

# Create Kerberos keytab for Apache (on DC01)
# In AD Users and Computers, create service account: HTTP/web01.homecorp.local
# Then on DC01:
# ktpass -princ HTTP/web01.homecorp.local@HOMECORP.LOCAL -mapuser websvc -pass Password1 -crypto All -ptype KRB5_NT_PRINCIPAL -out C:\http.keytab
```

```bash
# Copy http.keytab to WEB01
# scp administrator@192.168.56.10:C:/http.keytab /etc/apache2/http.keytab
sudo chown www-data /etc/apache2/http.keytab
sudo chmod 400 /etc/apache2/http.keytab

# Create protected directory
sudo nano /etc/apache2/sites-available/ad-protected.conf
```

```apache
<VirtualHost *:80>
    ServerName web01.homecorp.local
    DocumentRoot /var/www/protected

    <Directory /var/www/protected>
        AuthType Kerberos
        AuthName "HomeLab Corp — AD Authentication Required"
        KrbAuthRealms HOMECORP.LOCAL
        Krb5Keytab /etc/apache2/http.keytab
        KrbMethodNegotiate On
        KrbMethodK5Passwd On
        Require valid-user
    </Directory>
</VirtualHost>
```

```bash
sudo mkdir /var/www/protected
echo "<h1>AD Protected Page — You are authenticated as an AD user</h1>" | \
    sudo tee /var/www/protected/index.html

sudo a2ensite ad-protected
sudo systemctl reload apache2
```

---

## Phase 09 — Wazuh Correlation

Once WEB01 is domain-joined, correlate authentication events across both systems:

**Wazuh Dashboard queries:**
```
# All domain user logons on WEB01
agent.name: "WEB01" AND rule.groups: "authentication_success"

# Correlate DC01 Kerberos TGT (4768) with WEB01 SSH login
data.win.system.eventID: "4768" AND data.win.eventdata.targetUserName: "testuser01"

# SSSD auth events on WEB01
agent.name: "WEB01" AND data.srcuser: "*homecorp.local*"
```

---

## Phase 10 — Attack Simulation — Domain Credential Brute Force

With domain users able to SSH into WEB01, test detection:

```bash
# From KALI01 — target domain user account via SSH
hydra -l 'testuser01@homecorp.local' \
    -P /usr/share/wordlists/rockyou.txt \
    192.168.56.101 ssh -t 4 -V -f
```

This attack generates:
- Wazuh Rule 5720 on WEB01 (SSH failures)
- Event ID 4771 on DC01 (Kerberos pre-auth failure) — if using Kerberos auth
- fail2ban ban of KALI01 IP (if configured from Lab 08)

---

## Screenshots Needed

- [ ] `realm list` output showing WEB01 joined to homecorp.local
- [ ] `id testuser01@homecorp.local` output from WEB01
- [ ] SSH session on WEB01 authenticated as domain user
- [ ] DC01 AD Computers showing WEB01 computer account
- [ ] `klist` showing Kerberos TGT
- [ ] Wazuh — domain user SSH auth events correlated across DC01 and WEB01

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `realm discover` shows no output | DNS not pointing to DC01 | Fix `/etc/systemd/resolved.conf` |
| `realm join` fails with KDC error | Clock skew > 5 minutes | `sudo ntpdate 192.168.56.10` |
| Domain users can't SSH | SSSD not running | `sudo systemctl restart sssd` |
| Home directory not created | PAM mkhomedir not enabled | `sudo pam-auth-update --enable mkhomedir` |
| `id domain_user` returns no such user | `enumerate = False` in sssd.conf | Use fully qualified name: `id 'user@homecorp.local'` |

---

## Key Learnings

- Domain-joining Linux machines to Active Directory requires DNS to point at the DC — this is the most common failure point and must be validated first.
- Clock skew over 5 minutes breaks Kerberos authentication entirely — all VMs must be time-synchronized.
- SSSD caches AD credentials locally, which means domain users can log in to WEB01 even if DC01 is temporarily offline.
- A domain-joined web server creates a correlation opportunity: a single user's activity spans Event ID 4768 (DC01 Kerberos) + auth.log entries (WEB01 SSH) — this is the detection surface that advanced SOC playbooks exploit.
- This lab demonstrates the full enterprise security model: centralized AD identity → distributed Linux access → centralized SIEM visibility.
