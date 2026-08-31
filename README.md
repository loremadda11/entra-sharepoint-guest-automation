# Entra ID & SharePoint Guest Automation

PowerShell automation to bulk-create external guest users in Microsoft Entra ID and grant them read access to a SharePoint Online site from a simple CSV file.

> **Portfolio context** — This repository is a sanitized public example of the kind of operational automation I build as an IT Specialist: identify a repetitive process, define a safer workflow, automate it, test it, and make the result auditable for real users.

## My role

I approached this as an operational problem rather than a coding exercise:

- mapped the manual guest onboarding and SharePoint access workflow;
- identified duplicate invitations, inconsistent naming and repetitive permission changes as failure points;
- designed a CSV-driven workflow with safe defaults, validation and audit output;
- used AI-assisted development tools alongside PowerShell to accelerate implementation while reviewing and testing the resulting logic;
- structured the automation so an IT operator can preview changes before touching production data.

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

- read the CSV and normalise display names;
- create guest users in Microsoft Entra ID;
- skip users that already exist;
- export a result report;
- add the same guest users to a SharePoint Visitors group;
- support a dry-run mode to preview changes before applying them.

## Workflow

```text
CSV input
   ↓
Validate / normalise users
   ↓
Microsoft Entra ID
   ↓
Create or skip guest
   ↓
SharePoint Online
   ↓
Grant Visitors / Read access
   ↓
CSV audit report
```

## Scripts

| Script | Purpose |
|---|---|
| `01-create-entra-guest-users.ps1` | Creates guest users in Entra ID using Microsoft Graph PowerShell |
| `02-add-guests-to-sharepoint-visitors.ps1` | Adds the guest users to a SharePoint site's Visitors group using PnP PowerShell |

The two scripts are independent and run in sequence, so guest creation can be verified before granting any SharePoint access.

## Technologies

`PowerShell 7` · `Microsoft Graph PowerShell SDK` · `PnP PowerShell` · `Microsoft Entra ID` · `SharePoint Online`

## How it is used

1. Prepare the CSV file (see `sample-guests.csv` for the expected format)
2. Run `01-create-entra-guest-users.ps1` with `$DryRun = $true`
3. Review the console output / report
4. Re-run with `$DryRun = $false` to create the guests
5. Confirm the users now appear as guests in the tenant
6. Run `02-add-guests-to-sharepoint-visitors.ps1` with `$DryRun = $true`
7. Review which users would be added and to which group
8. Re-run with `$DryRun = $false` to grant access

## Design decisions

**Dry-run by default** — both scripts default to `$DryRun = $true`, so the first execution is always a preview. Nothing is created or modified until explicitly enabled.

**Duplicate protection** — before inviting a guest, the script checks via `Get-MgUser` whether a user with that email already exists in the tenant.

**Delimiter auto-detection** — the CSV reader checks the header row and picks `;` or `,` automatically, since regional Excel exports often default to semicolons.

**Per-row error handling** — if one invitation fails, the script logs the error for that row and continues with the rest, so a single failure does not stop the whole batch.

**No hardcoded secrets** — authentication is interactive (`Connect-MgGraph` / `Connect-PnPOnline -Interactive`). No passwords, tokens or tenant-specific secrets are stored in the scripts.

## Practical impact

The automation turns a repetitive multi-portal workflow into a repeatable batch process with preview, duplicate checks and reporting. The main value is not the script itself, but reducing manual work while making guest onboarding more consistent and auditable.

## Requirements

- PowerShell 7+
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/powershell/microsoftgraph/installation) (`Install-Module Microsoft.Graph`)
- [PnP PowerShell](https://pnp.github.io/powershell/) (`Install-Module PnP.PowerShell`)
- An account with `User.Invite.All` / `User.Read.All` Graph permissions, and edit rights on the target SharePoint group

## Security notes

- Dry-run mode is on by default
- No credentials are ever written to the scripts
- All authentication is interactive
- Every run produces a CSV report for auditing
- Never commit real CSV files, names, email addresses or internal tenant URLs

## What I learned

- The difference between inviting a guest via `New-MgInvitation` and simply adding an email to a SharePoint group
- How to make a CSV-driven script resilient to format inconsistencies
- Why per-row error handling matters with real-world input data
- Designing automation so the default behaviour is the safe behaviour
- Using AI-assisted coding as an implementation accelerator while keeping problem definition, validation and operational safety human-owned
