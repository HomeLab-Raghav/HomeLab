#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory
# HomeLab Corp — DC01 Active Directory Setup Script
# Run from DC01 after AD DS role is installed and the forest is promoted.

param(
    [string]$DomainNetBIOS = "HOMECORP",
    [string]$DomainFQDN    = "homecorp.local"
)

$ErrorActionPreference = "Stop"

function Log { param($Msg) Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Msg" -ForegroundColor Cyan }
function Warn { param($Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }

# ── Helper: safe create OU ───────────────────────────────────────────────────
function New-OUSafe {
    param($Name, $Path)
    $dn = "OU=$Name,$Path"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $false
        Log "Created OU: $dn"
    } else {
        Warn "OU already exists: $dn"
    }
}

# ── Helper: safe create user ─────────────────────────────────────────────────
function New-UserSafe {
    param($SamAccount, $DisplayName, $Path, $Password)
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$SamAccount'" -ErrorAction SilentlyContinue)) {
        $SecurePass = ConvertTo-SecureString $Password -AsPlainText -Force
        New-ADUser `
            -SamAccountName   $SamAccount `
            -UserPrincipalName "$SamAccount@$DomainFQDN" `
            -Name              $DisplayName `
            -DisplayName       $DisplayName `
            -Path              $Path `
            -AccountPassword   $SecurePass `
            -Enabled           $true `
            -PasswordNeverExpires $true
        Log "Created user: $SamAccount"
    } else {
        Warn "User already exists: $SamAccount"
    }
}

# ── Helper: safe create group ────────────────────────────────────────────────
function New-GroupSafe {
    param($Name, $Path, $Description)
    if (-not (Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $Name -GroupScope Global -GroupCategory Security `
            -Path $Path -Description $Description
        Log "Created group: $Name"
    } else {
        Warn "Group already exists: $Name"
    }
}

# ── 1. Domain Root ────────────────────────────────────────────────────────────
$DomainDN = "DC=" + $DomainFQDN.Replace(".", ",DC=")
Log "Domain base: $DomainDN"

# ── 2. Organizational Units ───────────────────────────────────────────────────
Log "Creating OUs..."
New-OUSafe -Name "HomeLab_Corp"       -Path $DomainDN
$CorpDN = "OU=HomeLab_Corp,$DomainDN"

New-OUSafe -Name "IT_Department"      -Path $CorpDN
New-OUSafe -Name "HR_Department"      -Path $CorpDN
New-OUSafe -Name "Service_Accounts"   -Path $CorpDN
New-OUSafe -Name "Security_Groups"    -Path $CorpDN
New-OUSafe -Name "Workstations"       -Path $CorpDN
New-OUSafe -Name "Servers"            -Path $CorpDN

$ITDN      = "OU=IT_Department,OU=HomeLab_Corp,$DomainDN"
$HRDN      = "OU=HR_Department,OU=HomeLab_Corp,$DomainDN"
$SvcDN     = "OU=Service_Accounts,OU=HomeLab_Corp,$DomainDN"
$GrpDN     = "OU=Security_Groups,OU=HomeLab_Corp,$DomainDN"

# ── 3. Users ──────────────────────────────────────────────────────────────────
Log "Creating users..."

# IT Department
New-UserSafe -SamAccount "raghav"      -DisplayName "Raghav Mahajan"    -Path $ITDN  -Password "HomeLab@2026!"
New-UserSafe -SamAccount "testuser01"  -DisplayName "Test User 01"      -Path $ITDN  -Password "P@ssw0rd123!"
New-UserSafe -SamAccount "itadmin"     -DisplayName "IT Admin"           -Path $ITDN  -Password "Admin@2026!"

# HR Department
New-UserSafe -SamAccount "hruser01"    -DisplayName "HR User 01"         -Path $HRDN  -Password "HRPass@2026!"
New-UserSafe -SamAccount "hrmanager"   -DisplayName "HR Manager"         -Path $HRDN  -Password "HRMgr@2026!"

# Service Accounts
New-UserSafe -SamAccount "svc.backup"  -DisplayName "Backup Service"    -Path $SvcDN -Password "Svc@Backup2026!"
New-UserSafe -SamAccount "svc.web"     -DisplayName "Web Service"        -Path $SvcDN -Password "Svc@Web2026!"
New-UserSafe -SamAccount "svc.monitor" -DisplayName "Monitor Service"   -Path $SvcDN -Password "Svc@Mon2026!"

# ── 4. Groups ─────────────────────────────────────────────────────────────────
Log "Creating security groups..."
New-GroupSafe -Name "SOC_Analysts"    -Path $GrpDN -Description "SOC Analyst team"
New-GroupSafe -Name "IT_Admins"       -Path $GrpDN -Description "IT Administrators"
New-GroupSafe -Name "HR_Staff"        -Path $GrpDN -Description "HR Department users"
New-GroupSafe -Name "Service_Accts"   -Path $GrpDN -Description "Service account group"

# ── 5. Group Memberships ──────────────────────────────────────────────────────
Log "Assigning group memberships..."

$Memberships = @(
    @{ Group = "SOC_Analysts";  Members = @("raghav", "testuser01") },
    @{ Group = "IT_Admins";     Members = @("raghav", "itadmin") },
    @{ Group = "HR_Staff";      Members = @("hruser01", "hrmanager") },
    @{ Group = "Service_Accts"; Members = @("svc.backup", "svc.web", "svc.monitor") }
)

foreach ($m in $Memberships) {
    foreach ($u in $m.Members) {
        try {
            Add-ADGroupMember -Identity $m.Group -Members $u -ErrorAction Stop
            Log "  $u -> $($m.Group)"
        } catch {
            Warn "  Could not add $u to $($m.Group): $($_.Exception.Message)"
        }
    }
}

# ── 6. Account Lockout Policy ─────────────────────────────────────────────────
Log "Configuring Account Lockout Policy..."
Set-ADDefaultDomainPasswordPolicy `
    -Identity $DomainFQDN `
    -LockoutThreshold 5 `
    -LockoutDuration (New-TimeSpan -Minutes 30) `
    -LockoutObservationWindow (New-TimeSpan -Minutes 30) `
    -MinPasswordLength 12 `
    -PasswordHistoryCount 5

# ── 7. Audit Policy ───────────────────────────────────────────────────────────
Log "Enabling audit policies..."
auditpol /set /subcategory:"Logon"                         /success:enable /failure:enable
auditpol /set /subcategory:"Logoff"                        /success:enable
auditpol /set /subcategory:"Account Lockout"               /failure:enable
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Authentication Service"    /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management"        /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management"      /success:enable /failure:enable
auditpol /set /subcategory:"Audit Policy Change"            /success:enable /failure:enable
auditpol /set /subcategory:"Filtering Platform Connection"  /failure:enable

# ── 8. SPN for Kerberoasting Demo ─────────────────────────────────────────────
Log "Setting SPN on svc.backup (Kerberoasting target)..."
try {
    Set-ADUser -Identity "svc.backup" `
        -ServicePrincipalNames @{Add="MSSQLSvc/dc01.homecorp.local:1433"}
    Log "SPN set: MSSQLSvc/dc01.homecorp.local:1433 on svc.backup"
} catch {
    Warn "Could not set SPN: $($_.Exception.Message)"
}

# ── 9. DNS A Records ──────────────────────────────────────────────────────────
Log "Adding DNS records..."
$DNSZone = $DomainFQDN
$Records = @(
    @{ Name = "web01";    IP = "192.168.56.101" },
    @{ Name = "portal";   IP = "192.168.56.101" },
    @{ Name = "wazuh";    IP = "192.168.56.104" }
)
foreach ($r in $Records) {
    if (-not (Get-DnsServerResourceRecord -ZoneName $DNSZone -Name $r.Name -ErrorAction SilentlyContinue)) {
        Add-DnsServerResourceRecordA -ZoneName $DNSZone -Name $r.Name -IPv4Address $r.IP
        Log "DNS: $($r.Name).$DNSZone -> $($r.IP)"
    } else {
        Warn "DNS record already exists: $($r.Name)"
    }
}

# ── Summary ───────────────────────────────────────────────────────────────────
Log "AD setup complete. Verify:"
Log "  Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName"
Log "  Get-ADUser -Filter * -SearchBase 'OU=HomeLab_Corp,$DomainDN' | Select-Object Name, SamAccountName"
Log "  Get-ADGroup -Filter * -SearchBase 'OU=HomeLab_Corp,$DomainDN' | Select-Object Name"
Log "  Get-ADDefaultDomainPasswordPolicy"
Log "  nslookup web01.homecorp.local    (from WEB01 or KALI01)"
