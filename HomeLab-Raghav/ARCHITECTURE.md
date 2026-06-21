# Architecture — HomeLab Corp (homecorp.local)

## Network Topology

```
                        HOST MACHINE (Windows 11)
                        192.168.56.1 (vboxnet0 gateway)
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼──────┐ ┌───────▼────────┐ ┌───▼──────────────────────────┐
    │    DC01         │ │    KALI01      │ │    WEB01                      │
    │  Windows 2022   │ │  Kali Linux    │ │  Ubuntu 22.04                 │
    │                 │ │                │ │                               │
    │  ● AD DS        │ │  ● Nmap        │ │  ● Wazuh Manager              │
    │  ● DNS Server   │ │  ● Hydra       │ │  ● Wazuh Indexer (OpenSearch) │
    │  ● Wazuh Agent  │ │  ● Wireshark   │ │  ● Wazuh Dashboard            │
    │  ● Event Logs   │ │  ● tcpdump     │ │  ● Wazuh Agent (self)         │
    │  ● Sysmon       │ │  ● Metasploit  │ │  ● Apache2 Web Server         │
    │                 │ │                │ │  ● fail2ban                   │
    │  192.168.56.10  │ │ 192.168.56.30  │ │  192.168.56.101               │
    └─────────────────┘ └────────────────┘ └───────────────────────────────┘
              │                                        │
              └────────── Wazuh Agents ───────────────►│
                           TCP 1514 / 1515              │
```

---

## VM Specifications

### DC01 — Domain Controller

| Field | Value |
|-------|-------|
| OS | Windows Server 2022 Standard Evaluation (Desktop Experience) |
| RAM | 4 GB |
| Storage | 60 GB VDI (dynamically allocated) |
| Network Adapter | VirtualBox Host-Only (vboxnet0) |
| IP Address | 192.168.56.10 (static) |
| Subnet | 192.168.56.0/24 |
| DNS | 192.168.56.10 (self — hosts homecorp.local zone) |
| Domain | homecorp.local |
| Forest Functional Level | Windows Server 2016 |
| Roles | AD DS, DNS Server |

**Active Directory Structure:**
```
homecorp.local
└── HomeLab Corp (OU)
    ├── IT (OU)
    │   ├── r.mahajan (user)
    │   ├── j.smith (user)
    │   ├── svc.backup (service account) ← Kerberoasting target
    │   └── IT-Admins (security group)
    ├── HR (OU)
    │   ├── a.jones (user)
    │   ├── c.lee (user)
    │   └── HR-Staff (security group)
    ├── Finance (OU)
    │   ├── b.patel (user)
    │   ├── d.kim (user)
    │   └── Finance-Staff (security group)
    ├── Servers (OU)
    └── Workstations (OU)
```

---

### WEB01 — Ubuntu Server / Wazuh SIEM

| Field | Value |
|-------|-------|
| OS | Ubuntu Server 22.04 LTS |
| RAM | 4 GB minimum (Wazuh Indexer requires it) |
| Storage | 50 GB VDI |
| Network Adapter | VirtualBox Host-Only (vboxnet0) |
| IP Address | 192.168.56.101 (static) |
| Services | Wazuh Manager, Wazuh Indexer (OpenSearch), Wazuh Dashboard, Apache2 |

**Wazuh Port Reference:**
```
TCP 443   ← Wazuh Dashboard (HTTPS)
TCP 9200  ← Wazuh Indexer (OpenSearch)
TCP 55000 ← Wazuh Manager API
TCP 1514  ← Agent log forwarding
TCP 1515  ← Agent registration
TCP 80    ← Apache HTTP
```

**Log File Locations:**
```
/var/ossec/logs/alerts/alerts.log   ← Live Wazuh alerts
/var/ossec/logs/ossec.log           ← Agent/Manager status
/var/ossec/etc/ossec.conf           ← Main config
/var/ossec/etc/rules/local_rules.xml ← Custom detection rules
/var/log/apache2/access.log         ← Apache access log
/var/log/apache2/error.log          ← Apache error log
/var/log/auth.log                   ← SSH auth attempts
```

---

### KALI01 — Attack Platform

| Field | Value |
|-------|-------|
| OS | Kali Linux (rolling) |
| RAM | 2 GB |
| Network Adapter | VirtualBox Host-Only (vboxnet0) |
| IP Address | 192.168.56.30 |
| Role | Red team / purple team attack simulation |
| Tools | Nmap, Hydra, Wireshark, tcpdump, CrackMapExec, BloodHound, arpspoof |

---

## Network Security Zones

```
┌─────────────────────────────────────────────┐
│  MANAGEMENT ZONE (192.168.56.0/24)          │
│                                             │
│  All lab VMs communicate here               │
│  Isolated Host-Only — no internet           │
│  Monitored by Wazuh on WEB01                │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  INTERNET ACCESS (NAT Adapter)              │
│                                             │
│  WEB01 Adapter 1 — for apt updates          │
│  DC01 Adapter 1 — for Windows updates       │
│  Traffic NOT monitored (external)           │
└─────────────────────────────────────────────┘
```

---

## Monitoring Architecture

```
DC01 (Windows Agent)                WEB01 (Linux Agent)
       │                                   │
       │  Event ID 4624/4625/4728...       │  /var/log/auth.log
       │  Sysmon Events                    │  /var/log/apache2/*.log
       │  AD Event Channels                │  /var/www/html (FIM)
       │                                   │
       └──────────► Wazuh Manager ◄────────┘
                    WEB01:1514
                         │
                    Wazuh Indexer
                    (OpenSearch)
                    WEB01:9200
                         │
                  Wazuh Dashboard
                  https://192.168.56.101
```

---

## Key Windows Event IDs Monitored

| Event ID | Meaning | Threat Signal |
|----------|---------|---------------|
| 4624 | Successful logon | Baseline |
| 4625 | Failed logon | Brute Force |
| 4648 | Explicit credential use | Pass-the-Hash |
| 4720 | User account created | Persistence |
| 4728 | Added to security group | Privilege Escalation |
| 4769 | Service ticket request | Kerberoasting |
| 4771 | Kerberos pre-auth failure | AS-REP Roasting |
| 4776 | NTLM auth attempt | Pass-the-Hash |

---

> HomeLab Corp · homecorp.local · Built by Raghav Mahajan · June 2026
