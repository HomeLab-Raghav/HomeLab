# Lab 11 — Custom Wazuh Detection Rules

**Status:** 📋 Planned | **Difficulty:** Advanced

---

## Overview

Write 15 production-quality custom Wazuh detection rules targeting real-world attack patterns observed in HomeLab Corp. Deploy rules to `/var/ossec/etc/rules/local_rules.xml`, trigger each rule with a test case, and confirm alerts fire in the Wazuh dashboard. This lab demonstrates detection engineering — one of the highest-value skills for a SOC analyst role.

---

## Prerequisites

- Lab 07 complete (Wazuh Manager running)
- DC01 and WEB01 agents active
- Sysmon installed on DC01 (recommended for rules 1–5)

---

## Rule Deployment

All custom rules go in one file on WEB01:

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

After any change:
```bash
sudo systemctl restart wazuh-manager

# Verify rules loaded without errors
sudo /var/ossec/bin/wazuh-logtest
```

---

## The 15 Custom Rules

```xml
<!-- /var/ossec/etc/rules/local_rules.xml -->
<group name="homelab_custom,">

  <!-- RULE 01: DC01 logon outside business hours (18:00 - 08:00) -->
  <rule id="100001" level="12">
    <if_sid>60106</if_sid>
    <time>18:00 - 08:00</time>
    <description>DC01: Successful logon outside business hours</description>
    <mitre>
      <id>T1078</id>
    </mitre>
  </rule>

  <!-- RULE 02: SSH brute force — rapid failures from single IP -->
  <rule id="100002" level="14" frequency="10" timeframe="60">
    <if_matched_sid>5710</if_matched_sid>
    <same_source_ip />
    <description>SSH: 10+ failed logins from same IP within 60 seconds</description>
    <mitre>
      <id>T1110.001</id>
    </mitre>
  </rule>

  <!-- RULE 03: New user created in Active Directory (Event ID 4720) -->
  <rule id="100003" level="10">
    <if_sid>60204</if_sid>
    <description>AD: New user account created — verify with AD team</description>
    <mitre>
      <id>T1136.002</id>
    </mitre>
  </rule>

  <!-- RULE 04: User added to Domain Admins group (Event ID 4728) -->
  <rule id="100004" level="15">
    <if_sid>60274</if_sid>
    <field name="win.eventdata.targetUserName">Domain Admins</field>
    <description>CRITICAL: User added to Domain Admins group</description>
    <mitre>
      <id>T1098</id>
    </mitre>
  </rule>

  <!-- RULE 05: Kerberoasting — excessive TGS-REQ (Event ID 4769) -->
  <rule id="100005" level="12" frequency="5" timeframe="30">
    <if_matched_sid>60127</if_matched_sid>
    <description>AD: Multiple service ticket requests — possible Kerberoasting</description>
    <mitre>
      <id>T1558.003</id>
    </mitre>
  </rule>

  <!-- RULE 06: Webshell drop detected by FIM in /var/www/html -->
  <rule id="100006" level="14">
    <if_sid>550</if_sid>
    <field name="file">/var/www/html</field>
    <match>\.php$|\.asp$|\.aspx$|\.jsp$</match>
    <description>FIM: Script file created in web root — possible webshell</description>
    <mitre>
      <id>T1505.003</id>
    </mitre>
  </rule>

  <!-- RULE 07: Apache directory traversal attempt -->
  <rule id="100007" level="10">
    <if_sid>31101</if_sid>
    <url>../</url>
    <description>Web: Directory traversal attempt detected in Apache request</description>
    <mitre>
      <id>T1083</id>
    </mitre>
  </rule>

  <!-- RULE 08: Multiple 404 errors from same source (web scanner) -->
  <rule id="100008" level="10" frequency="20" timeframe="60">
    <if_matched_sid>31101</if_matched_sid>
    <same_source_ip />
    <description>Web: 20+ 404 errors from same IP — possible web scanner</description>
    <mitre>
      <id>T1595.002</id>
    </mitre>
  </rule>

  <!-- RULE 09: Nmap aggressive scan detection (-A flag signature) -->
  <rule id="100009" level="10">
    <if_sid>40111</if_sid>
    <description>Network: Aggressive scan detected (Nmap -A or similar)</description>
    <mitre>
      <id>T1046</id>
    </mitre>
  </rule>

  <!-- RULE 10: SSH login from unexpected IP range -->
  <rule id="100010" level="10">
    <if_sid>5760</if_sid>
    <srcip>!192.168.56.0/24</srcip>
    <description>SSH: Successful login from outside HomeLab network</description>
    <mitre>
      <id>T1078</id>
    </mitre>
  </rule>

  <!-- RULE 11: Wazuh agent disconnected (monitoring gap) -->
  <rule id="100011" level="12">
    <if_sid>502</if_sid>
    <description>SIEM: Wazuh agent disconnected — monitoring gap opened</description>
  </rule>

  <!-- RULE 12: Sudo command run on WEB01 (privilege escalation tracking) -->
  <rule id="100012" level="8">
    <if_sid>5402</if_sid>
    <description>Linux: sudo command executed on WEB01 — review if unexpected</description>
    <mitre>
      <id>T1548.003</id>
    </mitre>
  </rule>

  <!-- RULE 13: Apache .env file access attempt (credential exposure probe) -->
  <rule id="100013" level="12">
    <if_sid>31101</if_sid>
    <url>\.env|\.git|\.htpasswd|wp-config\.php|config\.php</url>
    <description>Web: Sensitive file access attempt — credential exposure probe</description>
    <mitre>
      <id>T1552.001</id>
    </mitre>
  </rule>

  <!-- RULE 14: Windows firewall rule modified (defense evasion) -->
  <rule id="100014" level="12">
    <if_sid>60105</if_sid>
    <field name="win.system.eventID">4946</field>
    <description>Windows: Firewall rule added — possible defense evasion</description>
    <mitre>
      <id>T1562.004</id>
    </mitre>
  </rule>

  <!-- RULE 15: Multiple failed DC01 logons outside business hours -->
  <rule id="100015" level="15" frequency="5" timeframe="120">
    <if_matched_sid>60122</if_matched_sid>
    <time>18:00 - 08:00</time>
    <same_source_ip />
    <description>CRITICAL: Brute force against DC01 outside business hours</description>
    <mitre>
      <id>T1110.001</id>
    </mitre>
  </rule>

</group>
```

---

## Rule Test Cases

| Rule | ID | Test Command | Expected Alert |
|------|----|-------------|----------------|
| After-hours logon | 100001 | Log into DC01 at 19:00 | Level 12 — after-hours logon |
| SSH brute flood | 100002 | `for i in {1..15}; do ssh fake@WEB01; done` | Level 14 — 10+ failures |
| New AD user | 100003 | `New-ADUser -Name "TestUser"` | Level 10 — new user created |
| Domain Admin add | 100004 | `Add-ADGroupMember -Identity "Domain Admins" -Members testuser` | Level 15 — CRITICAL |
| Webshell drop | 100006 | `sudo touch /var/www/html/shell.php` | Level 14 — FIM script in web root |
| Directory traversal | 100007 | `curl "http://WEB01/../../../../etc/passwd"` | Level 10 — traversal detected |
| Web scanner | 100008 | Nikto scan: `nikto -h http://192.168.56.101` | Level 10 — 404 flood |

---

## Verify Rules Are Loaded

```bash
# Test rule with simulated log event
sudo /var/ossec/bin/wazuh-logtest

# Enter a test log line:
# Dec 10 19:30:01 DC01 MSWinEventLog 4625 ...

# Expected output:
# **Phase 3: Completed filtering (rules).
#        Rule id: '100001'
#        Level: '12'
#        Description: 'DC01: Successful logon outside business hours'
```

---

## Screenshots Needed

- [ ] local_rules.xml open in nano showing the 15 rules
- [ ] `wazuh-logtest` output confirming rule 100001 matches
- [ ] Wazuh dashboard — Rule 100004 (Domain Admins add) firing at Level 15
- [ ] Wazuh dashboard — Rule 100006 (webshell FIM) firing
- [ ] All 15 rules visible in Wazuh Management → Rules → Custom

---

## Key Learnings

- Custom rules with `frequency` + `timeframe` + `same_source_ip` create correlation rules that detect patterns, not just individual events — this is real detection engineering.
- Rule IDs in the `100000+` range are reserved for user-defined rules in Wazuh.
- MITRE ATT&CK tags in rules (`<mitre><id>`) appear in the Wazuh dashboard and threat intelligence views — always include them.
- Testing rules with `wazuh-logtest` before deploying saves debugging time — you can feed sample log lines and confirm rule matching without real traffic.
- A portfolio that includes custom detection rules shows active detection engineering skills, not just tool installation.
