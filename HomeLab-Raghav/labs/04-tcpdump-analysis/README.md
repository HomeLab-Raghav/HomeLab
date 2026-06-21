# Lab 04 — tcpdump Analysis

**Status:** ✅ Complete | **Date:** April 2026

---

## Overview

Complete tcpdump reference built from TryHackMe labs, CLI experimentation, `man pcap-filter`, and real traffic analysis against the HomeLab Corp network. Covers all core flags, BPF filter syntax, PCAP investigation workflows, and SOC-relevant use cases including ARP spoofing, port scan detection, DNS exfiltration, and cleartext credential capture.

tcpdump is the go-to tool in headless servers, SSH sessions, and cloud instances where Wireshark is unavailable.

---

## Core Flags

| Flag | What It Does |
|------|-------------|
| `-i <iface>` | Specify interface. Use `any` to capture all. Find names: `ip a s` |
| `-n` | No hostname resolution. Faster, stops tcpdump making DNS queries |
| `-nn` | No hostname AND no port-name resolution. Use this by default |
| `-c <count>` | Capture exactly N packets then stop. Always set on live captures |
| `-w <file>` | Write raw binary to .pcap. Nothing prints to screen |
| `-r <file>` | Read from a saved .pcap instead of live interface |
| `-v / -vv / -vvv` | More detail per packet. -vvv includes TTL, checksum, options |
| `-q` | Quiet. One line per packet. Good for flow overview |
| `-A` | ASCII payload. Shows readable content — HTTP, FTP, Telnet creds |
| `-X` | Hex + ASCII side by side. Full byte-level inspection |
| `-e` | Include Ethernet MAC addresses. Layer 2 visibility |
| `-B <size_kb>` | Set kernel capture buffer. Increase if seeing 'dropped by kernel' |
| `-s 0` | Capture full packet length |

---

## BPF Filter Syntax

Filters use **Berkeley Packet Filter** syntax. Combine with: `and` / `or` / `not`. Wrap complex expressions in single quotes.

### Host & IP Filters

```bash
host 192.168.1.10           # Traffic to/from a host
src host 10.0.0.5           # Source only
dst host 8.8.8.8            # Destination only
not host 192.168.1.1        # Exclude host
net 192.168.0.0/24          # Entire subnet
src net 10.0.0.0/8          # Source subnet
```

### Port Filters

```bash
port 443                    # Single port
src port 22                 # Source port
dst port 80                 # Destination port
portrange 1024-65535        # Port range
not port 53                 # Exclude port
```

### Protocol Filters

```bash
tcp                         # TCP only
udp                         # UDP only
icmp                        # ICMP (ping/traceroute)
arp                         # ARP
udp port 53                 # DNS
tcp port 80                 # HTTP
tcp port 443                # HTTPS
tcp port 22                 # SSH
tcp port 445                # SMB
```

### TCP Flag Filters (BPF Byte Access)

```bash
'tcp[tcpflags] == tcp-syn'         # SYN only — port scan indicator
'tcp[tcpflags] == 18'              # SYN-ACK — server response
'tcp[tcpflags] & tcp-rst != 0'     # RST — blocked connections / scans
'tcp[tcpflags] & tcp-fin != 0'     # FIN — normal session close
```

### Combined Examples

```bash
# HTTP traffic to/from specific host
sudo tcpdump -i ens5 -nn host 192.168.1.10 and port 80

# All traffic except DNS and ICMP
sudo tcpdump -i ens5 -nn not port 53 and not icmp

# SSH or HTTPS from private subnet
sudo tcpdump -i ens5 -nn 'src net 10.0.0.0/8 and (port 22 or port 443)'

# ARP for specific IP
sudo tcpdump -i ens5 -nn arp and host 192.168.56.10

# SYN scan detection from one source
sudo tcpdump -i ens5 -nn 'tcp[tcpflags] == tcp-syn and src host 192.168.56.30'
```

---

## Reading PCAP Files

```bash
# Basic read
tcpdump -r capture.pcap

# Always use -nn (no resolution)
tcpdump -r capture.pcap -nn

# Filter protocol
tcpdump -r capture.pcap -nn tcp

# Filter by host, pipe to less
tcpdump -r capture.pcap -nn host 192.168.1.1 | less

# Full ASCII payload — see cleartext creds, HTTP bodies
tcpdump -r capture.pcap -A | less

# Count total packets
tcpdump -r capture.pcap -nn -q | wc -l
```

### PCAP Investigation Cheat Sheet

| Question | Command |
|----------|---------|
| Who asked for MAC of 192.168.56.10? | `tcpdump -r file.pcap -n arp \| grep 192.168.56.10` |
| What IPs were talking on port 80? | `tcpdump -r file.pcap -nn port 80` |
| Did host X send any ICMP? | `tcpdump -r file.pcap -nn 'icmp and src host X'` |
| What DNS queries were made? | `tcpdump -r file.pcap -nn udp port 53` |
| Any SYN scan activity? | `tcpdump -r file.pcap -nn 'tcp[tcpflags] == tcp-syn'` |
| Traffic leaving local subnet? | `tcpdump -r file.pcap -nn not net 192.168.0.0/16` |
| HTTP POST bodies / plaintext creds? | `tcpdump -r file.pcap -A port 80 \| grep -A5 POST` |
| SMB traffic (lateral movement)? | `tcpdump -r file.pcap -nn port 445` |
| Any FTP credentials? | `tcpdump -r file.pcap -A port 21 \| grep -i 'PASS\|USER'` |

---

## Live Capture Best Practices

Always bound your captures — unbounded live captures fill disks and drop packets.

```bash
# 100 packets, save to file, no resolution
sudo tcpdump -i ens5 -c 100 -nn -w capture.pcap

# Capture for exactly 30 seconds
sudo timeout 30 tcpdump -i ens5 -nn -w capture.pcap

# Rotate: new file every 10MB, keep max 5 files
sudo tcpdump -i ens5 -C 10 -W 5 -w cap.pcap

# Timestamp filenames automatically
sudo tcpdump -i ens5 -w $(date +%F_%T)_capture.pcap -c 200
```

---

## SOC Use Cases

### ARP Spoofing Detection

```bash
# Live ARP monitoring
sudo tcpdump -i ens5 -nn arp

# From PCAP — look for duplicate IPs in Reply messages
tcpdump -r file.pcap -nn arp | grep Reply
```

Signs: multiple IPs resolving to same MAC, rapid ARP replies with no corresponding request.

### Port Scan Detection

```bash
# Flag SYN-only packets
sudo tcpdump -i ens5 -nn 'tcp[tcpflags] == tcp-syn'

# Scope to suspect source
sudo tcpdump -i ens5 -nn 'tcp[tcpflags] == tcp-syn and src host 192.168.56.30'
```

Pattern: flood of SYN packets from one source to many destination ports in a short window, with RST replies from closed ports.

### DNS Exfiltration Detection

```bash
# Capture all DNS
sudo tcpdump -i ens5 -nn -A udp port 53

# From PCAP — grep for abnormally long query strings
tcpdump -r file.pcap -A udp port 53 | grep -E '[A-Za-z0-9+/]{40,}'
```

Normal DNS queries are short. 100+ character queries to unusual domains are suspicious.

### Cleartext Credential Capture

```bash
# HTTP — look for POST data with credentials
tcpdump -r file.pcap -A port 80 | grep -i 'password\|passwd\|user\|login'

# FTP — USER and PASS commands are plaintext
tcpdump -r file.pcap -A port 21
```

### ICMP Tunneling Detection

```bash
# Capture ICMP and inspect payloads
sudo tcpdump -i ens5 -nn -X icmp

# From PCAP
tcpdump -r file.pcap -X icmp | less
```

Normal ICMP payloads are 32–64 bytes. Large payloads suggest tunneling for covert C2.

---

## Structured PCAP Analysis Workflow

When handed an unknown PCAP — CTF, lab, or real incident:

```bash
# 1. Get scope
tcpdump -r file.pcap -nn -q | wc -l

# 2. Protocol breakdown
tcpdump -r file.pcap -nn -q | awk '{print $NF}' | sort | uniq -c | sort -rn | head

# 3. Map the hosts
tcpdump -r file.pcap -nn | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u

# 4. ARP table
tcpdump -r file.pcap -nn arp

# 5. DNS queries
tcpdump -r file.pcap -nn -A udp port 53

# 6. TCP connections
tcpdump -r file.pcap -nn 'tcp[tcpflags] == tcp-syn'

# 7. Inspect suspicious streams
tcpdump -r file.pcap -A host <suspect> | less

# 8. Hand off to Wireshark for deep dissection
wireshark file.pcap
```

---

## One-Liner Quick Reference

```bash
# Capture 100 pkts, no resolution, save file
sudo tcpdump -i ens5 -c 100 -nn -w $(date +%F_%T).pcap

# Read PCAP, filter host, scroll output
tcpdump -r capture.pcap -nn host 192.168.1.50 | less

# Detect SYN scans
tcpdump -r capture.pcap -nn 'tcp[tcpflags] == tcp-syn'

# Extract plaintext HTTP credentials
tcpdump -r capture.pcap -A port 80 | grep -i 'password\|user'

# Monitor DNS in real time
sudo tcpdump -i ens5 -nn udp port 53

# Full packet contents — hex and ASCII
tcpdump -r capture.pcap -X host 10.0.0.1 | less

# Rotating capture — 10MB files, keep 5
sudo tcpdump -i ens5 -C 10 -W 5 -w cap.pcap
```

---

## Key Learnings

- `-nn` should be default — hostname resolution mid-capture adds noise and slows output.
- BPF filters (`tcpdump -i eth0 'tcp[tcpflags] == tcp-syn'`) are the same syntax used by Wireshark capture filters, Snort, and Suricata.
- The structured PCAP analysis workflow (scope → protocols → hosts → ARP → DNS → TCP → payload) is applicable to any CTF challenge or real incident.
- Cleartext protocols (FTP, Telnet, HTTP Basic Auth) are immediate findings in any network audit — the credentials are visible in the ASCII column.

---

## Resources

- `man pcap-filter` — ground truth BPF syntax reference
- [Daniel Miessler tcpdump Reference](https://danielmiessler.com/study/tcpdump/)
- [PacketTotal](https://packettotal.com) — upload PCAP for automated analysis
- [Malware Traffic Analysis](https://malware-traffic-analysis.net) — real malware PCAPs
