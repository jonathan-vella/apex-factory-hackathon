---
title: Troubleshooting
description: Known traps from the kit's own validation runs.
sidebar:
  order: 1
---

## Accounts, tools and repo setup

- **`az login` signs you in to the wrong tenant or subscription:** sign in again with `az login --tenant '<tenant-id>' --use-device-code`, list your subscriptions with `az account list --output table`, then run `az account set --subscription '<subscription-id>'`. Find the tenant ID in the Azure portal under **Microsoft Entra ID** > **Overview**. Then run `Initialize-Workstation.ps1` (or `./scripts/Initialize-Settings.ps1`) again.
- **`git commit` says "Author identity unknown":** git has no author configured. Run `Initialize-Workstation.ps1` on `vm-dev01`, or set `git config --global user.name "<your name>"` and `git config --global user.email "<your email>"`, then commit again.
- **`git push` fails when pushing `.github/workflows/platform.yml` (`refusing to allow an OAuth App to create or update workflow`):** your GitHub CLI token lacks the `workflow` scope. Run `gh auth refresh --hostname github.com --scopes repo,workflow` on `vm-dev01` (or re-run `Initialize-Workstation.ps1`), then push again.
- **`git clone` returns 404 (or repository not found) when using a pre-created cohort repo:** you have not accepted the GitHub collaborator invitation yet. Sign in to GitHub with the exact username you gave your team lead and accept the email invitation or open `https://github.com/<org>/<repo>/invitations` before cloning.
- **Collaborator invitation fails or student pushes to `main` are rejected in a lead-provisioned cohort:** check the partner organization's outside-collaborator policy (if outside collaborators are disabled, add students as organization members or let students create their own private repo via `Initialize-Workstation.ps1`) and confirm no organization or repository ruleset on `main` blocks direct commits.
- **`node` or `azd` is not recognized on a pre-existing `vm-dev01`:** your VM was provisioned before `node` 24 LTS and `azd` were added to `Install-DevTools.ps1`. Run `Initialize-Workstation.ps1` in PowerShell 7 (`pwsh`) on `vm-dev01` to install both machine-wide and refresh your `PATH`.
- **`Import-Kit.ps1` fails to download or extract:** the error says it could not download the archive from `api.github.com`, or that `tar` failed. Check outbound HTTPS to `api.github.com`, `codeload.github.com` and `*.githubusercontent.com` (see the [network allow-list](../../getting-started/requirements/#network)). Re-run `Initialize-Workstation.ps1` (or `pwsh ./Import-Kit.ps1 -Force`). An HTTP 403 means GitHub's per-IP limit for unauthenticated calls: wait a while or switch network.
- **`Initialize-Settings.ps1` saved the wrong subscription:** run `./scripts/Initialize-Settings.ps1 -SubscriptionId '<subscription-id>' -TenantId '<tenant-id>'` again from `factory/`. It updates only the values you pass.
- **`factory/.local/` is missing on `vm-dev01`:** that git-ignored folder holds your `settings.json` (including `suffix`) and `datacenter.json`. Re-run `Initialize-Workstation.ps1` on `vm-dev01` (it auto-detects any existing `rg-university-<suffix>` in your subscription so your suffix never drifts, or pass `-Suffix '<old suffix>'`).

## Preflight

- **Preflight reports FAIL on Owner:** you have no unconditional Owner assignment on your workload subscription. Contributor doesn't pass. If Owner is eligible through Privileged Identity Management, activate it first; otherwise ask your team lead to escalate to the event owner.
- **Preflight fails on a resource provider:** the `whatif` stage registers missing providers for you. Wait up to 15 minutes for the registration to propagate, then run the stage again.
- **Preflight warns on the public IP feature, or a deployment stops with `SubscriptionNotRegisteredForFeature`:** `Microsoft.Network/AllowBringYourOwnPublicIpAddress` stays `Pending` on standard partner subscriptions and is safe to ignore there; preflight logs a `WARN` and still returns `GO`. On subscriptions that enforce the feature for public IP creation, the `whatif` stage registers it and then `Microsoft.Network` again. If a deployment later stops with `SubscriptionNotRegisteredForFeature`, wait a few minutes and run the stage again, or ask the subscription administrator.

## Datacenter and Arc

- **The `member` stage stops or fails on quota or a VM size:** read the run log, then run the stage again; it converges. If a quota or size error comes back, check **Usage + quotas** for your event's region (`swedencentral` unless told otherwise) in the Azure portal and tell your team lead; they can escalate to the event owner.
- **The `member` stage fails in `dev-01-tools` looking up the PowerShell installer:** PowerShell 7.7 removed MSI installers from its GitHub release. Current `main` installs from the `win-x64.zip` archive instead, and any workflow with `KIT_REF: main` picks up the fix automatically on a rerun. If your `.github/workflows/platform.yml` pins an older commit SHA in `KIT_REF`, re-import the kit (`Import-Kit.ps1 -Force`) or set `KIT_REF: main`, push to `main`, and rerun `stage=member`.
- **The datacenter test fails on in-VM checks:** both VMs must run, and the test precedes Arc. If onboarding never started, fix the failure and rerun. If onboarding already disabled the guest agent, do not rerun `member`: the test cannot use run commands anymore. Preserve the earlier PASS evidence and use the Arc recovery path.
- **Bastion won't connect:** connect from the Azure portal: `rg-datacenter` > the VM > **Connect** > **Bastion**, user `labadmin`. Check the VM is running. The native client (`Connect-DatacenterVm.ps1`) is an optional shortcut that works only from Windows with the Azure CLI Bastion extension.
- **Copilot isn't signed in on `vm-dev01`:** the VS Code extensions install at first logon, so give the first sign-in up to five minutes, then sign in to GitHub in VS Code.
- **Arc onboarding times out:** do not rerun `member`. It refuses an existing Arc machine; if onboarding stopped earlier but disabled the guest agent, a rerun instead fails at the test. Read `C:\LabTools\logs\Connect-AppArc.log` through Bastion and check outbound Arc access through NAT. If `Get-PipelineEvidence.ps1` has no successful run to download, use the [standard lab credentials reference](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/infra/datacenter/README.md#credentials) or get custom credentials privately from the team lead. Before C5, use the approved rebuild below; after C5, ask for a coach repair.

## ALZ-lite and vending

- **Vending can't find the hub:** confirm the `foundation` stage finished and the expected hub resource names exist (`vnet-hub`, `afw-hub`, `afwp-hub`, `rg-hub`) before you run the `vending` stage.
- **A member lacks Owner, shared-services Reader or `id-sqlmi-directory` access because `memberPrincipalId` was missing at vending time:** add the member's Entra object ID (`memberPrincipalId`) to `.local/roster.json` in the team lead's repo, re-run `./scripts/Initialize-PlatformPipeline.ps1 -RosterPath .local/roster.json`, and run `gh workflow run platform.yml -f stage=vending -f members=<index>`.
- **DNS stops resolving after vending:** stopped VMs may need restarting or `ipconfig /renew`. A rebuilt datacenter needs the team lead to rerun vending for that member before restarting. Never redeploy an Arc-connected datacenter.
- **`Grant-SqlMiDirectoryRead.ps1` stops with `InteractionRequired` or `TokenCreatedWithOutdatedPolicies`:** the role holder's Microsoft Graph sign-in is stale. They run `az logout`, then `az login` again as themselves, and repeat.
- **No datacenter exemptions appear:** normally correct: `rg-datacenter` complies with ALZ-lite and needs none. Bastion's standalone public IP is outside the NIC policy's scope. Record compliance and "none needed", plus the C2 deferred-work entry; do not rerun vending just to get exemptions. Investigate actual non-compliance with the team lead rather than ignoring it or bypassing tenant policy.

### If Arc onboarding needs recovery

**After Arc onboarding starts, before C5:** the stage refuses an Arc machine; a partially disabled guest agent can instead break the test. With the event owner's approval, tear down your member scope first, **wait for `teardown` to finish green in Actions**, and then re-run `member`:

- **Team member (`2..n`, in your own repo):** run `gh workflow run platform.yml -f stage=teardown`, wait for it to finish green, then run `gh workflow run platform.yml -f stage=member`.
- **Team lead (for your own slot `1` or a single member `<index>` from the lead repo):** run `gh workflow run platform.yml -f stage=teardown -f members=<index>`, wait for it to finish green, then run `gh workflow run platform.yml -f stage=member -f members=<index>`.

Member `teardown` removes `rg-datacenter`, `rg-spoke` and the archetype, including the SQL Managed Instance. Repeat Step 3 and the `vm-dev01` setup. If the member does not hold eligible Windows Server licenses, add `-f no-hybrid-benefit=true` to the `member` command. If the member was already vended, the team lead must run `vending` for that index afterward. Before T+2, never run a full, unfiltered team `teardown` in the team lead's repo; pass `-f members=<your index>` or ask your team lead to escalate to the event owner for a coach repair. After C5, do not use this recovery; ask the event owner for a coach repair.

## Pipeline

- **`gh workflow run` says the workflow wasn't found (HTTP 404):** GitHub dispatches a workflow only from the default branch. Merge the import to `main` first, or run the stage from the **Actions** tab.
- **A run fails at once, with no steps and no log:** open the job's annotation. Private-repo Actions runs use the plan's included compute first; additional usage is billed to the repository owner. Ask the partner GitHub owner to check **Billing & Licensing**, the budget and payment method, then run the stage again.
- **Step 1.5 cannot create `gh-lab` or set its environment secrets:** check the partner organization's GitHub plan and your repo permissions before T-14. The owner reported a private-repo pipeline test on GitHub Free, but current [GitHub environment documentation](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments) says private-repo environments require Pro for personal accounts or Team for organizations, and private-repo required reviewers are Enterprise-only. Verify the setup in your own organization; if required reviewers are unavailable, write access is the gate. See the [Requirements](../../getting-started/requirements/#accounts-and-access) note and [issue #203](https://github.com/jonathan-vella/apex-factory-hackathon/issues/203).
- **A run waits and nothing happens:** it's waiting for the reviewer. Open the run and choose **Review deployments**. On a private repo with no reviewer option there's no gate, so a run that sits queued has lost its runner: cancel it and run the stage again.
- **Login fails with `AADSTS700213`:** the identity's credential doesn't match what your repo presents. Run `./scripts/Test-PipelineSetup.ps1` (add `-Profile Member` in your own repo): it names the failing check. Re-running `Initialize-PlatformPipeline.ps1` repairs the credential.
- **The guard refuses a subscription:** it isn't on the pipeline's approved list or is on its deny list. Check the roster and the repo's environment secrets with `Test-PipelineSetup.ps1`. Never add a subscription to the approved list to get past this unless it's part of the event.
- **`vm-app01 is already an Arc machine`:** the member stage never redeploys over Arc. Use the recovery above before C5; after C5, ask the event owner for a coach repair.
- **`Vending stopped at member N ... hub is incomplete`:** run the `foundation` stage first. Vending needs `vnet-hub`, `afw-hub`, `log-management` and `id-sqlmi-directory`.
- **The ALZ-lite what-if prints "First deployment":** expected. The what-if can't compare against management groups that don't exist yet. Run the `foundation` stage.
- **Removal stops before the team step:** a member's removal failed. Fix it, run `teardown` again, and the finished members are skipped. It also stops if a subscription under the Corp group isn't in the roster.
- **Preflight or another script fails with "Azure CLI returned an invalid JSON response":** older kit copies could mix Azure CLI warnings into the JSON response. Re-import the kit (`Import-Kit.ps1 -Force`, commit and merge it) to get the fix. If a Python warning is causing the error, `$env:PYTHONWARNINGS = 'ignore'` in that terminal is a temporary workaround.
- **Arc shows `vm-app01` Connected but no SQL Server instance appears:** the Azure extension for SQL Server (`WindowsAgent.SqlServer`) didn't install itself, which happens in some subscriptions (seen with every Defender for Cloud plan on). The `member` stage installs it after 5 minutes. On an older copy, install it in the portal: Azure Arc > Machines > `vm-app01` > Extensions > Add, choose the Azure extension for SQL Server and the **LicenseOnly** license type (Developer edition is free). The instances appear in a few minutes.
- **`Remove-PlatformPipeline.ps1` says it could not check the GitHub environment:** `gh` was refused, so the script can't tell whether it is gone. Sign in with `gh auth login` as an admin of the repo and run it again.
- **A subscription ID shows in a public run log:** delete that run (`gh run delete <id>`), then check that the value is stored as an environment secret and not a variable.

## Modernizing the app

- **The app falls back to a default connection after task 01:** task 01 resets the project's `UserSecretsId`. Re-enter your local user secrets afterward.
- **Blob or Service Bus calls return 403 on the dev VM:** `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` isn't set in that terminal, or VS Code was opened before it was set at the user level. Set it once, then restart every terminal and VS Code.
- **Production configuration refuses to start without Key Vault:** by design. The app refuses a connection string with a user name or password outside `Development`, and requires `KeyVault:VaultUri` outside `Development` too.

## APEX and the archetype

- **A Windows checkout changes the archetype's tree hash (`main.bicepparam` has CRLF line endings):** `Import-Kit.ps1` adds `*.bicepparam text eol=lf` to `.gitattributes`. If an older clone has CRLF line endings in `infra/bicep/university/main.bicepparam`, re-run `Initialize-Workstation.ps1` (or `Import-Kit.ps1 -Force`) and normalize line endings with `git add --renormalize infra/bicep/university`.
- **Preflight stops with `snet-sqlmi already hosts another managed instance`:** the suffix you ran it with isn't the suffix of the managed instance already in your subnet. Preflight accepts only `sqlmi-university-<suffix>` there, so a different suffix looks like someone else's instance. This can happen if you recreate your local settings and get a new suffix. Find the suffix you deployed with, from any resource name such as `rg-university-<suffix>`, set it again (`./scripts/Initialize-Settings.ps1 -Suffix '<old suffix>'` from `factory/`, and `azd env set SUFFIX <old suffix>` in `infra/bicep/university/`), and re-run. Never delete the managed instance to get past it. If the suffix is right and the message stays, a different instance really is on your subnet: stop and ask your team lead, who can escalate to the event owner.
- **`azd provision --preview` looks incomplete:** the preview only lists resource types `azd` has display names for. SQL MI, the managed identity, role assignments and diagnostic settings are still being created even though the preview doesn't name them.
- **Preflight says a SQL virtual cluster still holds `snet-sqlmi`:** a deleted MI's cluster can retain the subnet for hours. Wait for Azure to release it, then retry with the same suffix; do not delete the VNet, change suffix or remove the service association to force it.
- **Governance discovery reports `PARTIAL` on Tenant Root policies, or provisioning fails with `RequestDisallowedByPolicy` for MFA:** vending grants members Reader on the kit management groups (`mg-factory` and `mg-factory-corp`), not on Tenant Root, so custom definitions or assignments at Tenant Root can report `PARTIAL` during `/apex-adapt-archetype`. Policies that check only `requestContext().identity` (such as **Multi Factor Authentication Enforcement - Write** and **- Delete**) test your sign-in token rather than Bicep properties: `/apex-adapt-archetype` continues past them, and you satisfy them by signing in with MFA for both `az login` and `azd auth login`.
- **Preflight cannot read or assign `id-sqlmi-directory`:** the member lacks Reader on the shared subscription or Managed Identity Operator on the identity. The team lead checks the roster's member principal and reruns vending for that index; a user sign-in alone cannot grant the missing role.

## Migration

- **`CREATE USER ... FROM EXTERNAL PROVIDER` fails before cutover:** the replica is read-only until cutover completes. This is expected, not a bug, and the command only succeeds afterward.
- **`CREATE USER` fails after cutover with a directory-read error:** have the team lead run Step 2.2's `Grant-SqlMiDirectoryRead.ps1 -WhatIf`. All three Graph permissions must already be granted to the MI's primary identity; missing grants need the Privileged Role Administrator, not an app password or SQL-authentication workaround.
- **An aborted MI link leaves a writable copy of the database behind:** delete it before reseeding, or the next seed attempt fails.
- **A planned failover run from the managed instance side fails:** cut over from the Arc portal's pane, not with a CLI command issued from the MI. See the [Azure Arc and the MI link guide](../../guides/arc-mi-link/).

## Acceptance and cleanup

- **The acceptance checker reports UNKNOWN:** it could not decide a read/scope check. Keep its actual `NOT ACCEPTED` verdict, collect the portal evidence described in C8, resolve the cause with a coach and rerun. A screenshot cannot turn UNKNOWN into a passing script run.
- **`teardown` times out waiting for an MI subnet association:** Azure has not released the deleted MI's subnet yet. Wait and rerun the same member `teardown`. Do not force-delete the VNet or remove the service association; team cleanup must wait for successful member cleanup.

## Where to go next

Before day one, ask your team lead; they can escalate to the event owner. On event days, ask a coach if the documented recovery steps don't resolve your problem. Otherwise go back to [Requirements](../../getting-started/requirements/), [Member steps](../../deploy/member-steps/) or the [challenges overview](../../challenges/).
