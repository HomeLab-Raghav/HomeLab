# TODO — HomeLab-Raghav Lab Tracker

> Last updated: June 2026

---

## Lab Status Overview

| # | Lab | Status | Screenshots | Commands Verified | Write-up |
|---|-----|--------|-------------|-------------------|----------|
| 01 | Active Directory Setup | ✅ Complete | ✅ 26 added | ✅ Yes | ✅ Done |
| 02 | IR Cycle Simulation | ✅ Complete | ✅ 1 added | ✅ Yes | ✅ Done |
| 03 | Network Analysis Lab | 🔄 In Progress | ✅ 3 added | 🔄 Partial | 🔄 Partial |
| 04 | tcpdump Analysis | ✅ Complete | ⚠️ Needed | ✅ Yes | ✅ Done |
| 05 | Ubuntu Server Setup | ✅ Complete | ✅ 17 added | ✅ Yes | ✅ Done |
| 06 | Wireshark Packet Analysis | ✅ Complete | ✅ 6 added | ✅ Yes | ✅ Done |
| 07 | Wazuh SIEM Setup | ✅ Complete | ✅ 5 added | ✅ Yes | ✅ Done |
| 08 | Brute Force Detection | ✅ Complete | ✅ 2 added | ✅ Yes (live run) | ✅ Done |
| 09 | Firewall Misconfiguration | 📋 Planned | ❌ None | ❌ No | 📋 Guide Created |
| 10 | AD + Web Integration | 📋 Planned | ❌ None | ❌ No | 📋 Guide Created |
| 11 | Custom Wazuh Rules | 📋 Planned | ❌ None | ❌ No | 📋 Guide Created |

---

## Detailed Task List

### Lab 01 — Active Directory Setup

- [x] Windows Server 2022 installed on DC01
- [x] Static IP 192.168.56.10 configured
- [x] Windows updates applied
- [x] AD DS role installed
- [x] Domain homecorp.local promoted
- [x] OUs created: IT, HR, Finance, Servers, Workstations
- [x] 7 user accounts created with PowerShell
- [x] Security groups created: IT-Admins, HR-Staff, Finance-Staff
- [x] Ubuntu → DC01 connectivity verified (ping + DNS)
- [x] Screenshots added — 26 total (VM errors, network config, AD DS install, Ubuntu connectivity, DC01 login) ✅
- [ ] **SCREENSHOT NEEDED:** AD Users and Computers showing OU structure
- [ ] **SCREENSHOT NEEDED:** PowerShell output of Get-ADUser -Filter *
- [ ] **SCREENSHOT NEEDED:** DC01 static IP (Get-NetIPAddress output)
- [ ] **TODO:** Configure Account Lockout GPO (5 attempts, 30 min)
- [ ] **TODO:** Install and configure Sysmon on DC01
- [ ] **TODO:** BloodHound enumeration of homecorp.local

### Lab 02 — IR Cycle Simulation

- [x] Lab environment verified (all VMs up, Wazuh agents active)
- [x] Phase 1: Nmap SYN scan from KALI01 → DC01 and WEB01
- [x] Phase 2: SSH brute force (Hydra) → WEB01:22
- [x] Phase 3: SMB brute force (Hydra) → DC01:445
- [x] Phase 4: Aggressive Nmap -A scan
- [x] Phase 5: Wazuh alerts monitored and documented
- [x] MITRE ATT&CK mapping completed
- [x] IOC table documented
- [x] IR Report template completed
- [ ] **SCREENSHOT NEEDED:** Wazuh overview showing alert spike
- [ ] **SCREENSHOT NEEDED:** Wazuh Security Events — DC01 brute force (Rule 18152)
- [ ] **SCREENSHOT NEEDED:** Wazuh Security Events — SSH brute force (Rule 5720)
- [ ] **SCREENSHOT NEEDED:** Expanded alert JSON with source IP
- [ ] **SCREENSHOT NEEDED:** Windows Event Viewer — Event ID 4625 entries

### Lab 03 — Network Analysis Lab

- [ ] Define lab scope and capture scenarios
- [ ] Capture Nmap SYN scan PCAP
- [ ] Capture ARP poisoning PCAP
- [ ] Capture SSH brute force PCAP
- [ ] Analyze each PCAP with Wireshark and tcpdump
- [ ] Document display filters used
- [ ] Write findings section
- [ ] **SCREENSHOT NEEDED:** Wireshark showing SYN flood from Nmap
- [ ] **SCREENSHOT NEEDED:** Wireshark ARP poisoning detection

### Lab 04 — tcpdump Analysis

- [x] BPF filter syntax documented
- [x] All core flags documented with explanations
- [x] SOC use cases written (ARP, port scan, DNS exfil, creds)
- [x] Structured PCAP analysis workflow created
- [x] One-liner quick reference compiled
- [ ] **SCREENSHOT NEEDED:** tcpdump live SYN scan detection output
- [ ] **SCREENSHOT NEEDED:** tcpdump reading PCAP file with BPF filter
- [ ] **TODO:** Run actual captures against HomeLab traffic and save PCAPs

### Lab 05 — Ubuntu Server Setup

- [x] Ubuntu Server 22.04 installed on WEB01
- [x] Network adapter configuration documented (4 adapters)
- [x] systemd-resolved DNS issue diagnosed and fixed
- [x] Static connectivity to DC01 verified
- [x] Interface naming documented (enp0s3/8/9/10)
- [ ] **SCREENSHOT NEEDED:** ip a output showing 192.168.56.20
- [ ] **SCREENSHOT NEEDED:** ping -c 3 192.168.56.10 (0% packet loss)
- [ ] **SCREENSHOT NEEDED:** nslookup DC01.homecorp.local success

### Lab 06 — Wireshark Packet Analysis

- [x] Full OSI model documentation with Wireshark mapping
- [x] All display filters documented by protocol
- [x] Attack detection filters documented
- [x] Hex/binary reading guide written
- [x] TLS/SSL analysis guide written
- [x] Kerberos attack detection documented
- [x] Lab scenarios defined (Nmap, ARP MITM, cleartext creds)
- [ ] **SCREENSHOT NEEDED:** Wireshark TCP 3-way handshake capture
- [ ] **SCREENSHOT NEEDED:** Wireshark TLS Client Hello with SNI
- [ ] **SCREENSHOT NEEDED:** Follow TCP Stream showing HTTP credentials
- [ ] **TODO:** Complete ARP poisoning capture scenario

### Lab 07 — Wazuh SIEM Setup

- [x] Wazuh Manager installed on WEB01
- [x] Wazuh Indexer (OpenSearch) installed and initialized
- [x] Wazuh Dashboard accessible at https://192.168.56.101
- [x] Default admin password changed
- [x] Wazuh Agent installed on DC01 (Windows)
- [x] AD event channels configured in ossec.conf on DC01
- [x] Wazuh Agent installed on WEB01 (Ubuntu, local)
- [x] Apache2 installed and monitoring configured
- [x] FIM enabled on /var/www/html and /etc/apache2
- [x] Test web probes generated — alerts confirmed
- [x] AD brute force validation tests run
- [ ] **SCREENSHOT NEEDED:** Both agents Active (green) in dashboard
- [ ] **SCREENSHOT NEEDED:** Security Events — Apache alert with rule ID
- [ ] **SCREENSHOT NEEDED:** FIM alert for /var/www/html file change
- [ ] **TODO:** Write custom detection rules (see Lab 11)
- [ ] **TODO:** Install Sysmon on DC01 for richer telemetry

### Lab 08 — Brute Force Detection

- [x] Implementation guide written
- [x] Run Hydra SSH brute force against WEB01 ✅ (screenshot: 01_kali_hydra_ssh_brute_force.png)
- [x] Confirm Wazuh alerts fire — 2,021 hits (Rules 5760, 2501, 2502, 5758, 5503) ✅ (screenshot: 02_wazuh_threat_hunting_2021_auth_failures.png)
- [ ] Install and configure fail2ban on WEB01
- [ ] Verify fail2ban bans attacker IP
- [ ] Confirm Wazuh detects the ban event
- [ ] **SCREENSHOT NEEDED:** fail2ban-client status sshd showing banned IP

### Lab 09 — Firewall Misconfiguration

- [x] Implementation guide written
- [ ] Document current UFW/iptables ruleset baseline
- [ ] Introduce intentional misconfiguration
- [ ] Verify Kali can reach previously blocked service
- [ ] Detect with Wazuh (Rule 4946 — firewall rule change)
- [ ] Restore and harden ruleset
- [ ] **SCREENSHOT NEEDED:** iptables -L before/after comparison

### Lab 10 — AD + Web Integration

- [x] Implementation guide written
- [ ] Configure Apache on WEB01 with LDAP auth
- [ ] Test domain-user login to web app
- [ ] Configure Wazuh to correlate Apache + AD events
- [ ] Verify cross-agent alert correlation in dashboard
- [ ] **SCREENSHOT NEEDED:** Domain login to Apache-protected page

### Lab 11 — Custom Wazuh Rules

- [x] 15 custom detection rules written
- [ ] Deploy rules to /var/ossec/etc/rules/local_rules.xml
- [ ] Restart Wazuh Manager and verify rules load
- [ ] Trigger each rule and confirm alert fires
- [ ] Document each rule with test case
- [ ] **SCREENSHOT NEEDED:** Each custom rule alert in Wazuh dashboard

---

## Global TODOs

- [ ] Add screenshots folder content for all labs
- [ ] Record short demo video of Wazuh catching a brute force in real time
- [ ] Run BloodHound against homecorp.local and document attack paths
- [ ] Add TryHackMe write-ups to tryhackme-writeups/ folder
- [ ] Tag all MITRE ATT&CK techniques in lab READMEs
- [ ] Create GitHub Actions CI to validate markdown links

---

> Status legend: ✅ Complete · 🔄 In Progress · 📋 Planned · ⚠️ Needed · ❌ Missing
