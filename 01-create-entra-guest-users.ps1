$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURATION
# ============================================================

$CsvPath = ".\sample-guests.csv"

# true  = dry run, nothing is created
# false = actually creates guest users in the tenant
$DryRun = $true

# false = create the guest without sending Microsoft's automatic invitation email
# true  = create the guest AND send the invitation email
$SendInvitationMessage = $false

# Redirect URL shown after the guest accepts the invitation
$InviteRedirectUrl = "https://myapps.microsoft.com"

# ============================================================
# FUNCTIONS
# ============================================================

function Format-DisplayName {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $culture   = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
    $textInfo  = $culture.TextInfo

    return $textInfo.ToTitleCase($Text.Trim().ToLower())
}

# ============================================================
# SETUP
# ============================================================

if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

if (-not (Get-Module -ListAvailable Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -AllowClobber -Force
}

Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.SignIns

Connect-MgGraph -Scopes "User.Invite.All", "User.Read.All"

# ============================================================
# READ AND NORMALIZE CSV
# ============================================================

$firstLine = Get-Content -Path $CsvPath -TotalCount 1
$Delimiter = if ($firstLine -match ";") { ";" } else { "," }

$rows = Import-Csv -Path $CsvPath -Delimiter $Delimiter

$people = foreach ($row in $rows) {

    $firstName = Format-DisplayName "$($row.FirstName)"
    $lastName  = Format-DisplayName "$($row.LastName)"
    $email     = "$($row.Email)".Trim().ToLower()

    if ([string]::IsNullOrWhiteSpace($email)) {
        continue
    }

    if ($email -notmatch "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
        [PSCustomObject]@{
            Name  = "$firstName $lastName".Trim()
            Email = $email
            Status = "SKIPPED - invalid email"
        }
        continue
    }

    $displayName = "$firstName $lastName".Trim()
    if ([string]::IsNullOrWhiteSpace($displayName)) {
        $displayName = $email
    }

    [PSCustomObject]@{
        Name  = $displayName
        Email = $email
        Status = "TO_VERIFY"
    }
}

$people = $people | Sort-Object Email -Unique

# ============================================================
# CREATE GUEST USERS
# ============================================================

$results = foreach ($person in $people) {

    if ($person.Status -ne "TO_VERIFY") {
        $person
        continue
    }

    $safeEmail = $person.Email.Replace("'", "''")

    $existing = Get-MgUser `
        -Filter "mail eq '$safeEmail'" `
        -Property Id, DisplayName, Mail, UserPrincipalName, UserType `
        -ErrorAction SilentlyContinue

    if ($existing) {
        [PSCustomObject]@{
            Name  = $person.Name
            Email = $person.Email
            Status = "SKIPPED - already exists in tenant"
        }
        continue
    }

    if ($DryRun) {
        [PSCustomObject]@{
            Name  = $person.Name
            Email = $person.Email
            Status = "DRY_RUN - would be created as guest"
        }
        continue
    }

    try {
        New-MgInvitation `
            -InvitedUserDisplayName $person.Name `
            -InvitedUserEmailAddress $person.Email `
            -InviteRedirectUrl $InviteRedirectUrl `
            -SendInvitationMessage:$SendInvitationMessage `
            -ErrorAction Stop | Out-Null

        [PSCustomObject]@{
            Name  = $person.Name
            Email = $person.Email
            Status = "OK - guest created"
        }
    }
    catch {
        [PSCustomObject]@{
            Name  = $person.Name
            Email = $person.Email
            Status = "ERROR - $($_.Exception.Message)"
        }
    }
}

# ============================================================
# REPORT
# ============================================================

$ReportPath = ".\result-entra-guests.csv"

$results | Format-Table -AutoSize

$results | Export-Csv `
    $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8 `
    -Delimiter ";"

Write-Host ""
Write-Host "Report saved to: $ReportPath" -ForegroundColor Green
