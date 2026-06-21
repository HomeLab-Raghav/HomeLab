# GitHub Push Instructions — HomeLab-Raghav

Step-by-step to get this repo live on GitHub from your Windows machine.

---

## Prerequisites

- Git installed: `git --version` (if not: https://git-scm.com/download/win)
- GitHub account logged in via browser
- Optional: GitHub CLI (`gh`) for faster setup

---

## Step 1 — Create the GitHub Repo

**Option A — GitHub CLI (fastest):**
```powershell
winget install --id GitHub.cli     # install once
gh auth login                       # follow prompts (browser-based)
cd C:\Users\raagh\Downloads\labs\HomeLab-Raghav
gh repo create HomeLab-Raghav --public --description "Cybersecurity HomeLab documentation — 11 labs covering AD, Wazuh SIEM, network analysis, brute force detection, and incident response" --source . --remote origin --push
```

**Option B — Browser:**
1. Go to https://github.com/new
2. Repository name: `HomeLab-Raghav`
3. Description: `Cybersecurity HomeLab — 11 labs covering AD, Wazuh SIEM, network analysis, brute force detection, and incident response`
4. Visibility: **Public**
5. **Do NOT** initialize with README, .gitignore, or license (we already have them)
6. Click **Create repository**
7. Copy the HTTPS URL shown (e.g., `https://github.com/YOUR_USERNAME/HomeLab-Raghav.git`)

---

## Step 2 — Initialize Git and Push

Open PowerShell, then:

```powershell
cd C:\Users\raagh\Downloads\labs\HomeLab-Raghav

# Initialize git repo
git init

# Stage all files
git add .

# Review what will be committed (sanity check)
git status

# Create the initial commit
git commit -m "Initial commit: HomeLab Corp cybersecurity documentation

11-lab portfolio covering:
- Active Directory setup on Windows Server 2022
- Incident Response cycle simulation with MITRE ATT&CK mapping
- Network analysis (Wireshark + tcpdump)
- Ubuntu web server setup and hardening
- Wazuh SIEM deployment and detection engineering
- Brute force detection (SSH/SMB) with fail2ban and GPO
- Firewall misconfiguration analysis
- AD + web server integration (domain-joined Linux)
- Custom Wazuh detection rules (IDs 100001-100015)"

# Add GitHub remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/HomeLab-Raghav.git

# Push to main branch
git branch -M main
git push -u origin main
```

---

## Step 3 — Set Repo Topics (GitHub Discoverability)

After pushing, go to your repo page on GitHub:
1. Click the gear icon next to **About** (top-right of repo)
2. Add topics:
   ```
   cybersecurity wazuh siem active-directory homelab penetration-testing
   incident-response wireshark network-security blue-team red-team
   security-plus mitre-attack
   ```
3. Check **Releases**, **Packages**, **Deployments** off (not applicable)
4. Click **Save changes**

---

## Step 4 — Pin to GitHub Profile

1. Go to your GitHub profile: `https://github.com/YOUR_USERNAME`
2. Click **Customize your pins**
3. Select `HomeLab-Raghav` → **Save pins**

---

## Step 5 — LinkedIn Post Template

Once pushed, share it:

```
🔐 Just published my Cybersecurity HomeLab portfolio on GitHub

11 labs documenting my hands-on cybersecurity practice:
✅ Active Directory setup (Windows Server 2022 + homecorp.local domain)
✅ Wazuh SIEM deployment with custom detection rules
✅ Incident Response simulation with MITRE ATT&CK mapping
✅ SSH/SMB brute force detection with fail2ban
✅ Wireshark + tcpdump network analysis
✅ Domain-joined Linux (AD + web server integration)

All labs include real commands, Wazuh alert IDs, Windows Event IDs, and IOC documentation.

Built entirely in VirtualBox on a single Windows PC.

GitHub: https://github.com/YOUR_USERNAME/HomeLab-Raghav

#Cybersecurity #BlueTeam #HomeLab #Wazuh #ActiveDirectory #SIEM #SOC #InfoSec
```

---

## Ongoing Workflow (After Initial Push)

As you complete more labs and add screenshots:

```powershell
cd C:\Users\raagh\Downloads\labs\HomeLab-Raghav

# Stage new/changed files
git add labs/02-ir-cycle-simulation/screenshots/
git add labs/07-wazuh-siem-setup/screenshots/

# Commit
git commit -m "Add screenshots for Lab 02 and Lab 07"

# Push
git push
```

### Update TODO.md when a lab is complete:
```powershell
# After editing TODO.md to mark a lab done:
git add TODO.md
git commit -m "Mark Lab 07 as complete in TODO"
git push
```

---

## Security Checklist Before Pushing

Run this before every push to verify no sensitive data:

```powershell
# Search for potential passwords/keys in files
git diff --staged | Select-String -Pattern "password|secret|key|token|P@ss" -CaseSensitive:$false

# Verify .gitignore is catching sensitive patterns
git status --short | Where-Object { $_ -match "\.env|\.key|password" }
```

If anything appears that shouldn't: `git reset HEAD <file>` to unstage it.

---

## Repo Stats to Include on Resume

Once live, your README badge line shows:

```markdown
![GitHub repo size](https://img.shields.io/github/repo-size/YOUR_USERNAME/HomeLab-Raghav)
![GitHub last commit](https://img.shields.io/github/last-commit/YOUR_USERNAME/HomeLab-Raghav)
```

Add these to the top of README.md after the first push and replace `YOUR_USERNAME`.
