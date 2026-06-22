# Incident Report: SSH & SMB Brute Force Attack

**Date:** June 4, 2026  
**Duration:** 4 minutes 18 seconds  
**Status:** Contained — No successful authentication  

## Summary

Wazuh SIEM detected coordinated brute force attack against WEB01 (SSH:22) and DC01 (SMB:445) from KALI01 (authorized testing IP 192.168.56.30).

- SSH attacks: 521 attempts → 0 successful logons
- SMB attacks: 847 attempts → 0 successful logons
- Detection latency: 18 seconds (Rule 40101 — port scan)

## Attack Timeline

| Time | Event | Detection |
|------|-------|-----------|
| 14:05:12 | Nmap port scan starts | Rule 40101 (18 sec latency) |
| 14:06:23 | SSH brute force starts (521 attempts) | Rule 5720 (42 sec latency) |
| 14:06:50 | SMB brute force starts (847 attempts) | Rule 18152 (40 sec latency) |
| 14:08:11 | Aggressive Nmap scan | Rule 40111 |
| 14:09:30 | Attack stops | Baseline restored |

## Root Cause

Three vulnerabilities enabled the attack:

1. **No SSH rate limiting** → fail2ban installed (ban after 5 attempts)
2. **No AD account lockout** → GPO configured (5 attempts, 30-min lockout)
3. **No network segmentation** → Firewall rule added (block KALI01 from DC)

## Remediation & Verification

✅ fail2ban deployed on WEB01 — confirmed working (re-tested with Hydra)  
✅ Account lockout policy enabled on DC01 — confirmed working (Event ID 4740)  
✅ Firewall rule added to block 192.168.56.30 → SMB port 445  

## Lessons Learned

- **What worked:** Multi-layer detection (network + auth layer)
- **What failed:** Attacker could have bypassed controls using distributed IPs
- **Next step:** Implement distributed brute force detection rule (different IPs → same account)

## Recommendations

1. Deploy Rule 100020 (detect 5+ different IPs attacking same account in 5 min)
2. Implement MFA on domain accounts (prevents all password-based attacks)
3. Document incident in security log for audit trail

---

**Sign-off:** Raghav Mahajan | 6/4/2026