# Entra ID & SharePoint Guest Automation

PowerShell scripts to bulk-create external guest users in Microsoft Entra ID and grant them read access to a SharePoint Online site — driven by a simple CSV file.

---

## The problem

Organisations frequently need to collaborate with external vendors, consultants, or partners on a SharePoint project site. The manual process looks like this:

1. Open the Microsoft 365 / Entra ID admin portal
2. Invite each external user as a guest, one by one
3. Confirm the user shows up correctly under guest users
4. Open the SharePoint project site
5. Manually add each guest to the Visitors / Read group

With more than a handful of external contacts, this becomes slow, repetitive, and error-prone — duplicate invites, missed users, inconsistent naming.

## Goal

Automate the whole flow starting from a single CSV file:

```csv
FirstName;LastName;Email
John;Smith;john.smith@example.com
Jane;Doe;jane.doe@example.net
```

The automated process should:

- read the CSV and normalise display names
- create guest users in Microsoft Entra ID
- skip users that already exist (no duplicates)
- export a result report
- add the same guest users to a SharePoint "Visitors" group
- support a dry-run mode to preview changes before applying them

---

## Scripts

| Script | Purpose |
|---|---|
| `01-create-entra-guest-users.ps1` | Creates guest users in Entra ID using Microsoft Graph PowerShell |
| `02-add-guests-to-sharepoint-visitors.ps1` | Adds the guest users to a SharePoint site's Visitors group using PnP PowerShell |

The two scripts are independent and run in sequence, so guest creation can be verified before granting any SharePoint access.

---

## Technologies

`PowerShell 7` · `Microsoft Graph PowerShell SDK` · `PnP PowerShell` · `Microsoft Entra ID` · `SharePoint Online`

---

## Workflow

1. Prepare the CSV file (see `sample-guests.csv` for the expected format)
2. Run `01-create-entra-guest-users.ps1` with `$DryRun = $true`
3. Review the console output / report
4. Re-run with `$DryRun = $false` to actually create the guests
5. Confirm the users now appear as guests in the tenant
6. Run `02-add-guests-to-sharepoint-visitors.ps1` with `$DryRun = $true`
7. Review which users would be added and to which group
8. Re-run with `$DryRun = $false` to grant access

---

## Design decisions

**Dry-run by default**: both scripts default to `$DryRun = $true`, so the first execution is always a preview. Nothing is created or modified until you explicitly switch it off.

**Duplicate protection**: before inviting a guest, the script checks via `Get-MgUser` whether a user with that email already exists in the tenant — avoiding duplicate invitations.

**Delimiter auto-detection**: the CSV reader checks the header row and picks `;` or `,` automatically, since regional Excel exports often default to semicolons.

**Per-row error handling**: if one invitation fails (bad permissions, malformed email, throttling), the script logs the error for that row and continues with the rest — a single failure never stops the whole batch.

**No hardcoded secrets**: authentication is always interactive (`Connect-MgGraph` / `Connect-PnPOnline -Interactive`). No passwords, tokens, or tenant-specific data are stored in the scripts.

---

## Requirements

- PowerShell 7+
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/powershell/microsoftgraph/installation) (`Install-Module Microsoft.Graph`)
- [PnP PowerShell](https://pnp.github.io/powershell/) (`Install-Module PnP.PowerShell`)
- An account with `User.Invite.All` / `User.Read.All` Graph permissions, and edit rights on the target SharePoint group

---

## Security notes

- Dry-run mode is on by default
- No credentials are ever written to the scripts
- All authentication is interactive (browser-based Microsoft login)
- Every run produces a CSV report for auditing
- Never commit real CSV files, real names, real email addresses, or internal tenant URLs — only the sample file with placeholder data is included here

---

## What I learned

- The difference between inviting a guest via `New-MgInvitation` and simply adding an email to a SharePoint group — the guest object must exist in Entra ID first
- How to make a CSV-driven script resilient to format inconsistencies (delimiter, casing, whitespace)
- Why per-row error handling matters once you're processing real, messy data instead of a clean test file
- Designing scripts so the default behaviour is always the safe one (dry-run, no secrets, no destructive actions without explicit confirmation)
