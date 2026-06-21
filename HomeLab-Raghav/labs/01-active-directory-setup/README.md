# Lab 01 — Active Directory Setup

**Status:** ✅ Complete | **Date:** March 2026 | **Platform:** VirtualBox + Windows Server 2022

---

## Overview

Built a complete Active Directory environment from scratch on Windows Server 2022 inside VirtualBox. Configured DC01 as the domain controller for `homecorp.local`, set up static IP and DNS, applied system updates, and created a realistic enterprise OU/user structure using PowerShell.

This lab is the foundation for all subsequent labs — every Wazuh alert, brute force test, and red team exercise operates inside this AD environment.

---

## Environment

| Component | Value |
|-----------|-------|
| VM | DC01 |
| OS | Windows Server 2022 Standard Evaluation (Desktop Experience) |
| IP | 192.168.56.10 (static, Host-Only) |
| Domain | homecorp.local |
| Forest Level | Windows Server 2016 |
| Roles | AD DS, DNS Server |

---

## Setup Steps

### Step 1 — Fresh VM Creation

Wiped the original broken VM and rebuilt from scratch using the correct method:
- Used **Settings → Storage** to manually attach the ISO _after_ VM creation — avoids the Unattended placeholder bug that breaks Windows Setup.
- Selected **Standard Evaluation (Desktop Experience)** — full GUI for Server Manager.
- Added a **60 GB VDI** (dynamically allocated) disk under Controller: SATA.

**Common Issues Hit:**

| Error | Root Cause | Fix |
|-------|------------|-----|
| License Terms not found on boot | Unattended placeholder ISO left in Storage by wizard | Remove it from Settings → Storage |
| No signed drivers found | VirtualBox virtual disk needs no drivers | Click OK — harmless |
| No drives found during install | VM created without a virtual hard disk | Add 60 GB VDI in Settings → Storage |

### Step 2 — Static IP Configuration

```powershell
# Find the correct adapter
Get-NetAdapter

# Assign static IP (Host-Only adapter = Ethernet 2 in this lab)
New-NetIPAddress -InterfaceAlias "Ethernet 2" `
    -IPAddress 192.168.56.10 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.56.1

# Point DNS to itself — DC01 will host homecorp.local zone after promotion
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" `
    -ServerAddresses 192.168.56.10
```

> DNS must point to itself before promotion. After AD DS installs, DC01 runs its own DNS server for `homecorp.local`. Pointing to 8.8.8.8 will cause promotion to fail or create broken DNS records.

### Step 3 — Windows Updates

```powershell
# Install PSWindowsUpdate module
Install-Module PSWindowsUpdate -Force

# Download and install all updates (accepts NuGet prompt automatically)
Install-WindowsUpdate -AcceptAll -AutoReboot
```

### Step 4 — AD DS Role Installation

Via **Server Manager → Add Roles and Features → Active Directory Domain Services**.

After role install completes → click **"Promote this server to a domain controller"**.

**Promotion Settings Used:**

| Setting | Value |
|---------|-------|
| Deployment Operation | Add a new forest |
| Root Domain Name | homecorp.local |
| Forest Functional Level | Windows Server 2016 |
| DNS Server | ✅ Checked |
| Global Catalog | ✅ Checked |
| NetBIOS Name | HOMECORP |
| DSRM Password | Set securely — stored offline |

> Store the DSRM password before clicking Promote. It is separate from the Administrator password and is the only recovery path if AD fails to start.

### Step 5 — OU and User Structure (PowerShell)

```powershell
# Create top-level OU
New-ADOrganizationalUnit -Name "HomeLab Corp" `
    -Path "DC=homecorp,DC=local" `
    -ProtectedFromAccidentalDeletion $true

$base = "OU=HomeLab Corp,DC=homecorp,DC=local"

# Department OUs
New-ADOrganizationalUnit -Name "IT"          -Path $base -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "HR"          -Path $base -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Finance"     -Path $base -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Servers"     -Path $base -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Workstations"-Path $base -ProtectedFromAccidentalDeletion $true

# User accounts
$pw = ConvertTo-SecureString "abcd@1234" -AsPlainText -Force

New-ADUser -Name "Raghav Mahajan"  -SamAccountName "r.mahajan"  -Path "OU=IT,$base"      -AccountPassword $pw -Enabled $true
New-ADUser -Name "John Smith"      -SamAccountName "j.smith"    -Path "OU=IT,$base"      -AccountPassword $pw -Enabled $true
New-ADUser -Name "Backup Service"  -SamAccountName "svc.backup" -Path "OU=IT,$base"      -AccountPassword $pw -Enabled $true
New-ADUser -Name "Alice Jones"     -SamAccountName "a.jones"    -Path "OU=HR,$base"      -AccountPassword $pw -Enabled $true
New-ADUser -Name "Carol Lee"       -SamAccountName "c.lee"      -Path "OU=HR,$base"      -AccountPassword $pw -Enabled $true
New-ADUser -Name "Bob Patel"       -SamAccountName "b.patel"    -Path "OU=Finance,$base" -AccountPassword $pw -Enabled $true
New-ADUser -Name "David Kim"       -SamAccountName "d.kim"      -Path "OU=Finance,$base" -AccountPassword $pw -Enabled $true

# Security groups
New-ADGroup -Name "IT-Admins"     -GroupScope Global -GroupCategory Security -Path "OU=IT,$base"
New-ADGroup -Name "HR-Staff"      -GroupScope Global -GroupCategory Security -Path "OU=HR,$base"
New-ADGroup -Name "Finance-Staff" -GroupScope Global -GroupCategory Security -Path "OU=Finance,$base"

# Group membership
Add-ADGroupMember -Identity "IT-Admins"     -Members "r.mahajan","j.smith","svc.backup"
Add-ADGroupMember -Identity "HR-Staff"      -Members "a.jones","c.lee"
Add-ADGroupMember -Identity "Finance-Staff" -Members "b.patel","d.kim"
```

### Step 6 — Ubuntu Connectivity Fix

Ubuntu (WEB01) uses systemd-resolved by default, which intercepts DNS at 127.0.0.53. To resolve `homecorp.local`, point DNS directly to DC01:

```bash
# Disable systemd-resolved temporarily for testing
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo rm /etc/resolv.conf
echo "nameserver 192.168.56.10" | sudo tee /etc/resolv.conf

# Verify
ping -c 3 192.168.56.10
nslookup DC01.homecorp.local

# Restore after testing
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved
sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

---

## Screenshots

### VM Setup — Errors Encountered & Fixed

**Error 1 — License Terms Not Found (Unattended ISO Bug)**
![License Terms Error](screenshots/01_error_license_terms_not_found.png)
> Root cause: VirtualBox created a 0B unattended placeholder ISO. Fix: remove it from Storage and attach the real ISO manually.

**Error 2 — No Signed Device Drivers**
![No Drivers Error](screenshots/02_error_no_signed_drivers.png)
> Harmless — click OK. VirtualBox virtual disks don't need drivers.

**Error 3 — No Drives Found**
![No Drives Error](screenshots/03_error_no_drives_found.png)
> Root cause: VM created without a virtual hard disk attached. Fix: add 60 GB VDI in Settings → Storage.

**Storage Fix — Both ISOs Visible (Transition State)**
![Storage Both ISOs](screenshots/04_storage_unattended_and_real_iso.png)

**Storage Fix — Real ISO Attached (4.70 GB)**
![Storage Real ISO](screenshots/05_storage_real_iso_470gb.png)
> SERVER_EVAL_x64FRE_en-us.iso confirmed at 4.70 GB — correct.

**Removing Old Broken VM**
![Remove Old VM](screenshots/06_remove_old_windows_home_vm.png)

**OS Selection — Windows Server 2022 Standard Evaluation**
![OS Selection](screenshots/07_os_selection_server2022_standard.png)

---

### Network Configuration

**DC01 — Adapter 1 = NAT (internet access)**
![DC01 Adapter 1 NAT](screenshots/08_dc01_adapter1_nat.png)

**DC01 — Adapter 4 = Host-Only (Promiscuous: Allow VMs)**
![DC01 Adapter 4 Host-Only](screenshots/09_dc01_adapter4_hostonly_allow_vms.png)

**DC01 — Adapter 4 = NAT Network (SOC-HomeLab)**
![DC01 NAT Network](screenshots/10_dc01_adapter4_nat_network_soc.png)

**DC01 — Adapter 2 = Bridged (Realtek WiFi 6)**
![DC01 Bridged Adapter](screenshots/11_dc01_adapter2_bridged.png)

**DC01 — Adapter 4 = Host-Only (Promiscuous: Deny)**
![DC01 Host-Only Deny](screenshots/22_dc01_adapter4_hostonly_deny.png)

---

### Static IP & Windows Updates

**Error — PowerShell Commands Run in CMD (Common Mistake)**
![CMD Not PowerShell](screenshots/12_error_powershell_cmds_in_cmd.png)
> `Get-NetAdapter` and `New-NetIPAddress` fail in CMD — must run in **PowerShell as Administrator**.

**Static IP Set — 192.168.56.10 Confirmed**
![Static IP Set](screenshots/13_dc01_static_ip_192_168_56_10.png)

**Static IP Confirmed + PSWindowsUpdate Installing**
![IP Confirmed Updates](screenshots/15_dc01_static_ip_confirmed_pswindowsupdate.png)

**Windows Updates Installing**
![Windows Updates](screenshots/14_dc01_windows_updates_installing.png)

---

### AD DS Installation

**AD DS Role Installed — Promote to Domain Controller**
![AD DS Installed](screenshots/16_ad_ds_installed_promote_to_dc.png)
> Server Manager shows "Configuration required. Installation succeeded" with the "Promote this server to a domain controller" link. Date: 3/12/2026.

---

### Ubuntu Connectivity (WEB01 → DC01)

**Ubuntu — Adapter 3 = Host-Only (Allow All)**
![Ubuntu Adapter Allow All](screenshots/21_ubuntu_adapter3_hostonly_allow_all.png)

**Ubuntu — Adapter 3 = Host-Only (Deny)**
![Ubuntu Adapter Deny](screenshots/23_ubuntu_adapter3_hostonly_deny.png)

**Ubuntu — Full ip addr show Output**
![ip addr show](screenshots/24_ubuntu_ip_addr_show_full.png)

**Ubuntu — Ping DC01 Fails (100% Packet Loss)**
![Ping DC01 Fails](screenshots/18_ubuntu_ping_dc01_unreachable.png)
> 3 packets transmitted, 0 received — "Destination Host Unreachable" from 192.168.56.20. DNS or adapter mismatch.

**Ubuntu — systemd-resolved DNS Errors**
![DNS Errors](screenshots/19_ubuntu_dns_systemd_resolved_error.png)

**Ubuntu — systemd-resolved Name Resolution Failure**
![Name Resolution Fail](screenshots/20_ubuntu_systemd_resolved_name_fail.png)
> "unable to resolve host ubuntu: Temporary failure in name resolution" — fixed by pointing DNS directly to 192.168.56.10.

**VirtualBox — Drag and Drop Error**
![Drag Drop Error](screenshots/17_error_drag_drop_guest_host.png)
> Guest Additions issue — workaround: use shared folders or SCP instead of drag-and-drop.

---

### DC01 Running — VirtualBox (June 2026)

**DC01 VM — Windows Lock Screen (Confirmed Running)**
![DC01 Lock Screen](screenshots/25_dc01_virtualbox_running_lock_screen.png)
> DC01 running inside VirtualBox. Windows Server lock screen confirming the VM boots cleanly.

**DC01 — HOMECORP\Administrator Login**
![DC01 Admin Login](screenshots/26_dc01_homecorp_administrator_login.png)
> Domain login prompt showing `HOMECORP\Administrator` — confirms Active Directory promotion succeeded and domain is active.

---

## Key Learnings

- DNS is the backbone of Active Directory — every auth failure in this lab traces back to DNS misconfiguration.
- The DSRM password is distinct from the local Administrator password after promotion. Document it before clicking Promote.
- PowerShell cmdlets (`Get-NetAdapter`, `New-NetIPAddress`) do not run in CMD — always use **PowerShell as Administrator**.
- VirtualBox Host-Only adapters must share the exact same adapter name across VMs for inter-VM networking to work.
- Service accounts (`svc.backup`) with Domain group membership are primary Kerberoasting targets — a pattern seen in every real AD penetration test.

---

## MITRE ATT&CK Relevance

| Technique | ID | Relevance |
|-----------|----|-----------|
| Valid Accounts: Domain Accounts | T1078.002 | User accounts created in this lab are targets |
| Kerberoasting | T1558.003 | svc.backup is an intentional Kerberoasting target |
| Account Discovery | T1087.002 | AD structure is enumerable via BloodHound |

---

## Resources

- [Microsoft AD DS Documentation](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview)
- [VirtualBox Host-Only Networking](https://www.virtualbox.org/manual/ch06.html)
- [SwiftOnSecurity Sysmon Config](https://github.com/SwiftOnSecurity/sysmon-config)
