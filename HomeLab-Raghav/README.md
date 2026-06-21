# HomeLab-Raghav — Cybersecurity Home Lab Portfolio

**Author:** Raghav Mahajan | **Domain:** homecorp.local | **Updated:** June 2026

A fully documented, enterprise-grade cybersecurity home lab built on VirtualBox. Every lab is hands-on, MITRE ATT&CK mapped, and written to the standard expected in a Tier 1–2 SOC analyst role.

---

## Lab Environment

```
┌──────────────────────────────────────────────────────────────────┐
│                     H O M E C O R P . L O C A L                 │
│                       NETWORK: 192.168.56.0/24                   │
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────────────────┐   │
│  │  DC01            │ ──────► │  WEB01                       │   │
│  │  Windows 2022    │         │  Ubuntu Server 22.04         │   │
│  │  Domain Controller│        │  Wazuh SIEM + Apache         │   │
│  │  192.168.56.10   │         │  192.168.56.101              │   │
│  └──────────────────┘         └──────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────┐                                            │
│  │  KALI01          │  Attack Platform                           │
│  │  Kali Linux      │  192.168.56.30                             │
│  └──────────────────┘                                            │
└──────────────────────────────────────────────────────────────────┘
```

| VM | OS | Role | IP |
|----|----|------|----|
| DC01 | Windows Server 2022 | Active Directory Domain Controller | 192.168.56.10 |
| WEB01 | Ubuntu Server 22.04 | Web Server + Wazuh SIEM Manager | 192.168.56.101 |
| KALI01 | Kali Linux | Red Team / Attack Simulation | 192.168.56.30 |

---

## Labs

| # | Lab | Status | Key Skills |
|---|-----|--------|------------|
| 01 | [Active Directory Setup](labs/01-active-directory-setup/) | ✅ Complete | AD DS, PowerShell, DNS, OUs |
| 02 | [IR Cycle Simulation](labs/02-ir-cycle-simulation/) | ✅ Complete | Incident Response, MITRE ATT&CK, IR Reports |
| 03 | [Network Analysis Lab](labs/03-network-analysis-lab/) | 🔄 In Progress | Wireshark, PCAP, Protocol Analysis |
| 04 | [tcpdump Analysis](labs/04-tcpdump-analysis/) | ✅ Complete | tcpdump, BPF Filters, CLI Forensics |
| 05 | [Ubuntu Server Setup](labs/05-ubuntu-setup/) | ✅ Complete | Linux, Networking, DNS, systemd |
| 06 | [Wireshark Packet Analysis](labs/06-wireshark-packet-analysis/) | ✅ Complete | Wireshark, OSI Model, Attack Detection |
| 07 | [Wazuh SIEM Setup](labs/07-wazuh-siem-setup/) | ✅ Complete | Wazuh, OpenSearch, FIM, Apache |
| 08 | [Brute Force Detection](labs/08-brute-force-detection/) | 🔄 In Progress | Hydra, fail2ban, Detection Engineering |
| 09 | [Firewall Misconfiguration](labs/09-firewall-misconfiguration/) | 📋 Planned | iptables, UFW, Defense Hardening |
| 10 | [AD + Web Integration](labs/10-ad-web-integration/) | 📋 Planned | Domain Join, LDAP, Wazuh Integration |
| 11 | [Custom Wazuh Rules](labs/11-custom-wazuh-rules/) | 📋 Planned | Detection Engineering, SIEM Rules |

---

## Skills Demonstrated

**Blue Team / Defense**
- SIEM deployment and configuration (Wazuh + OpenSearch)
- Active Directory setup, OU design, and security hardening
- File Integrity Monitoring (FIM) and real-time alerting
- Log analysis: Windows Event Logs, /var/log/auth.log, Apache logs
- Incident Response report writing with MITRE ATT&CK mapping

**Red Team / Offense (Purple Teaming)**
- Network reconnaissance: Nmap SYN scans, aggressive enumeration
- Brute force attacks: Hydra against SSH and SMB
- Attack simulation generating detectable IOCs
- PCAP capture and analysis with Wireshark and tcpdump

**Infrastructure**
- Windows Server 2022: AD DS, DNS, GPO, PowerShell automation
- Ubuntu Server 22.04: Apache, Nginx, systemd, UFW, fail2ban
- VirtualBox networking: Host-Only, NAT, Bridged adapters

---

## Certification Alignment

| Certification | Domains Covered |
|---------------|-----------------|
| CompTIA Security+ SY0-701 | Domain 1 (Attacks), Domain 4 (Operations), Domain 5 (Governance) |
| ISC2 CC | Domain 3 (Access Controls), Domain 4 (Network Security) |
| MITRE ATT&CK | T1046, T1082, T1110.001, T1021.002, T1595.001 |

---

## Repository Structure

```
HomeLab-Raghav/
├── README.md               ← This file
├── ARCHITECTURE.md         ← Full network topology + VM specs
├── TODO.md                 ← Lab completion tracker
├── LICENSE
├── .gitignore
├── labs/
│   ├── 01-active-directory-setup/
│   ├── 02-ir-cycle-simulation/
│   ├── 03-network-analysis-lab/
│   ├── 04-tcpdump-analysis/
│   ├── 05-ubuntu-setup/
│   ├── 06-wireshark-packet-analysis/
│   ├── 07-wazuh-siem-setup/
│   ├── 08-brute-force-detection/
│   ├── 09-firewall-misconfiguration/
│   ├── 10-ad-web-integration/
│   └── 11-custom-wazuh-rules/
├── scripts/                ← Shared automation scripts
├── configs/                ← Shared configuration files
├── network-diagrams/       ← Topology diagrams
└── tryhackme-writeups/     ← TryHackMe room write-ups
```

---

> Built by Raghav Mahajan — github.com/HomeLab-Raghav | raghv.dev
