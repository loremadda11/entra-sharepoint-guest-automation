# Entra ID & SharePoint Guest Automation

Identity and external-collaboration automation that creates Microsoft Entra ID guest users from CSV input and grants them controlled SharePoint access through a separate, verifiable step.

> **Portfolio context** — This is a sanitized example of how I approach an operational identity/access workflow as an IT Specialist: understand the manual process, separate identity creation from resource access, add safe defaults and validation, automate the repetitive parts, and keep the result auditable.

## Case study at a glance

**Situation** — External vendors, consultants and partners needed guest identities in Microsoft Entra ID and read access to a SharePoint project site.

**Problem** — The manual workflow crossed multiple administration surfaces: invite each external user, verify the guest object, open SharePoint, then grant site access one user at a time. At batch scale this creates repetitive work and increases the chance of duplicate invitations, missed users and inconsistent naming.

**Approach** — I split the process into two independent stages: first create or verify guest identities through Microsoft Graph, then grant SharePoint access only after the identity stage can be reviewed. CSV input, dry-run defaults, validation and execution reports make both stages easier to control.

**Outcome** — Guest onboarding becomes a repeatable identity-and-access workflow rather than a sequence of one-off portal changes, with clearer checkpoints and audit output.

## My role

I approached this as an identity/access process rather than a coding exercise:

- mapped the manual guest onboarding and SharePoint access workflow;
- identified duplicate invitations, inconsistent naming and repetitive permission changes as failure points;
- separated **identity creation** from **resource access** so each stage can be verified independently;
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

Automate the flow starting from a simple CSV file:

```csv
FirstName;LastName;Email
John;Smith;john.smith@example.com
Jane;Doe;jane.doe@example.net
```

The automated process should:

- read the CSV and normalise display names;
- create guest users in Microsoft Entra ID;
- skip users that already exist according to the tenant email lookup;
- export a result report;
- add the same guest users to a SharePoint Visitors group;
- support a dry-run mode to preview changes before applying them.

## Workflow

```text
CSV input
   ↓
Validate / normalise users
   ↓
Microsoft Entra ID / Graph
   ↓
Create or skip guest
   ↓
Review identity-stage report
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

The two scripts are intentionally independent and run in sequence, so guest creation can be verified before granting SharePoint access.

## Technologies

`PowerShell 7` · `Microsoft Graph PowerShell SDK` · `PnP PowerShell` · `Microsoft Entra ID` · `SharePoint Online`

## How it is used

1. Prepare the CSV file (see `sample-guests.csv` for the expected format)
2. Run `01-create-entra-guest-users.ps1` with `$DryRun = $true`
3. Review the console output / report
4. Re-run with `$DryRun = $false` to create the guests
5. Confirm the users now appear as guests in the tenant
6. Configure `$ClientId` in `02-add-guests-to-sharepoint-visitors.ps1` with an Entra ID app registration suitable for PnP PowerShell interactive authentication
7. Run the SharePoint script with `$DryRun = $true`
8. Review which users would be added and to which group
9. Re-run with `$DryRun = $false` to grant access

## Design decisions

**Two-stage identity/access workflow** — guest creation and SharePoint authorization are deliberately separate. Identity changes can be reviewed before resource access is granted.

**Dry-run by default** — both scripts default to `$DryRun = $true`, so the first execution is always a preview. Nothing is created or modified until explicitly enabled.

**Duplicate check** — before inviting a guest, the script queries Entra ID via `Get-MgUser` for the supplied email and skips an existing match.

**Delimiter auto-detection** — the CSV reader checks the header row and picks `;` or `,` automatically, since regional Excel exports often default to semicolons.

**Per-row error handling** — if one invitation fails, the script logs the error for that row and continues with the rest, so a single failure does not stop the whole batch.

**No hardcoded secrets** — authentication is interactive. No passwords, tokens or tenant secrets are stored in the scripts; public configuration values are placeholders.

**Generated reports are ignored** — `.gitignore` excludes execution reports and common local input filenames to reduce the chance of publishing real guest data accidentally.

## Practical impact

The automation turns a repetitive multi-portal workflow into a repeatable identity-and-access process with preview, duplicate checks, stage separation and reporting. The main value is not the script itself, but reducing manual work while making external-user onboarding more consistent and auditable.

This project represents a broader part of how I work: **connect identity, systems and user workflows, then use automation as the implementation layer rather than treating code as the end goal.**

## Requirements

- PowerShell 7+
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/powershell/microsoftgraph/installation) (`Install-Module Microsoft.Graph`)
- [PnP PowerShell](https://pnp.github.io/powershell/) (`Install-Module PnP.PowerShell`)
- Graph permissions appropriate for guest invitation / lookup (`User.Invite.All`, `User.Read.All` in this example)
- an Entra ID app registration / client ID configured for PnP PowerShell interactive authentication
- sufficient rights to manage membership of the target SharePoint group

## Security notes

- Dry-run mode is on by default
- No credentials are written to the scripts
- Authentication is interactive
- Every run produces a CSV report for auditing
- Generated result CSV files are excluded through `.gitignore`
- Never commit real guest lists, names, email addresses, internal tenant URLs or production identifiers

## What I learned

- The difference between creating an Entra B2B guest identity and granting that identity access to a SharePoint resource
- Why separating identity provisioning from authorization makes the workflow easier to validate
- How to make a CSV-driven script resilient to format inconsistencies
- Why per-row error handling matters with real-world input data
- Designing automation so the default behaviour is the safe behaviour
- Using AI-assisted coding as an implementation accelerator while keeping problem definition, validation and operational safety human-owned
