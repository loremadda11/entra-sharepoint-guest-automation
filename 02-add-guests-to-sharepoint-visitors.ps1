$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURATION
# ============================================================

$CsvPath = ".\sample-guests.csv"

# SharePoint site URL (no trailing /SitePages/...)
$SiteUrl = "https://contoso.sharepoint.com/sites/ProjectSite"

# Name of the SharePoint group with read permission
$ReadGroupName = "Visitors of ProjectSite"

# true  = dry run, nobody is added to the group
# false = actually adds the users to the SharePoint group
$DryRun = $true

# ============================================================
# SETUP
# ============================================================

if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

if (-not (Get-Module -ListAvailable PnP.PowerShell)) {
    Install-Module PnP.PowerShell -Scope CurrentUser -Force
}

Import-Module PnP.PowerShell

Connect-PnPOnline -Url $SiteUrl -Interactive

$group = Get-PnPGroup -Identity $ReadGroupName -ErrorAction Stop

Write-Host ""
Write-Host "SharePoint site: $SiteUrl" -ForegroundColor Cyan
Write-Host "Target group:    $($group.Title)" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# READ CSV
# ============================================================

$firstLine = Get-Content -Path $CsvPath -TotalCount 1
$Delimiter = if ($firstLine -match ";") { ";" } else { "," }

$rows = Import-Csv -Path $CsvPath -Delimiter $Delimiter

$emails = foreach ($row in $rows) {
    $email = "$($row.Email)".Trim().ToLower()

    if ([string]::IsNullOrWhiteSpace($email)) {
        continue
    }

    if ($email -match "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
        $email
    }
}

$emails = $emails | Sort-Object -Unique

# ============================================================
# ADD GUESTS TO GROUP
# ============================================================

$currentMembers = Get-PnPGroupMember -Group $ReadGroupName -ErrorAction SilentlyContinue

$results = foreach ($email in $emails) {

    $alreadyMember = $false

    foreach ($member in $currentMembers) {
        if (
            "$($member.Email)".ToLower() -eq $email -or
            "$($member.LoginName)".ToLower() -like "*$email*" -or
            "$($member.Title)".ToLower() -like "*$email*"
        ) {
            $alreadyMember = $true
            break
        }
    }

    if ($alreadyMember) {
        [PSCustomObject]@{
            Email = $email
            Group = $ReadGroupName
            Status = "SKIPPED - already a member"
        }
        continue
    }

    if ($DryRun) {
        [PSCustomObject]@{
            Email = $email
            Group = $ReadGroupName
            Status = "DRY_RUN - would be added as reader"
        }
        continue
    }

    try {
        New-PnPUser -LoginName $email -ErrorAction SilentlyContinue | Out-Null

        Add-PnPGroupMember `
            -LoginName $email `
            -Group $ReadGroupName `
            -ErrorAction Stop

        [PSCustomObject]@{
            Email = $email
            Group = $ReadGroupName
            Status = "OK - added as reader"
        }
    }
    catch {
        [PSCustomObject]@{
            Email = $email
            Group = $ReadGroupName
            Status = "ERROR - $($_.Exception.Message)"
        }
    }
}

# ============================================================
# REPORT
# ============================================================

$ReportPath = ".\result-sharepoint-visitors.csv"

$results | Format-Table -AutoSize

$results | Export-Csv `
    $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8 `
    -Delimiter ";"

Write-Host ""
Write-Host "Report saved to: $ReportPath" -ForegroundColor Green
