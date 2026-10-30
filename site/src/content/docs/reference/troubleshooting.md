---
title: Troubleshooting
description: Known traps from the kit's own validation runs.
sidebar:
  order: 1
---

## Accounts, tools and repo setup

- **`az login` signs you in to the wrong tenant or subscription:** sign in again with `az login --tenant '<tenant-id>' --use-device-code`, list your subscriptions with `az account list --output table`, then run `az account set --subscription '<subscription-id>'`. Find the tenant ID in the Azure portal under **Microsoft Entra ID** > **Overview**. Then run `./scripts/Initialize-Settings.ps1` again and read the subscription name it shows before you accept it.
- **`git commit` says "Author identity unknown":** the dev container has no git identity. Run `git config --global user.name "<your name>"` and `git config --global user.email "<your email>"`, then commit again.
- **`git clone` asks for a password:** don't clone from a terminal. Use VS Code: press `F1` > `Git: Clone`, choose **Clone from GitHub** and sign in when VS Code asks. On Windows 11, press `F1` > `WSL: Connect to WSL` first.
- **The dev container won't build:** check the network allow-list first. The container pulls images and features from `ghcr.io`, `mcr.microsoft.com` and `docker.io`, and installs packages through `packagefeedproxy.microsoft.io`. If Docker Desktop won't start, check WSL 2 is on, as in [Requirements](../../getting-started/requirements/#tools).
- **`docker: command not found` in Ubuntu, or Reopen in Container says Docker isn't found:** open Docker Desktop **Settings** > **Resources** > **WSL integration** and switch on **Ubuntu**, then restart VS Code.
- **`Import-Kit.ps1` fails to download or extract:** the error says it could not download the archive from `api.github.com`, or that `tar` failed. Check outbound HTTPS to `api.github.com`, `codeload.github.com` and `*.githubusercontent.com` (see the [network allow-list](../../getting-started/requirements/#network)). The three-line paste ends with `rm Import-Kit.ps1`, so the script is gone after a failure: run all three lines again from the repo root in the dev container, and add `-Force` to the second line (`pwsh ./Import-Kit.ps1 -Force`) when the script says `factory/` exists (a failed run can leave a partial one). An HTTP 403 means GitHub's per-IP limit for unauthenticated calls: wait a while or switch network.
- **`Initialize-Settings.ps1` saved the wrong subscription:** run `./scripts/Initialize-Settings.ps1 -SubscriptionId '<subscription-id>' -TenantId '<tenant-id>'` again. It updates only the values you pass.
- **You deleted your dev container volume and `factory/.local/` is gone:** that folder holds your settings, including the suffix, and your datacenter credentials, and it isn't in git. Re-import the kit if needed, then run `./scripts/Initialize-Settings.ps1 -Suffix '<old suffix>'` from `factory/` to restore your suffix, and re-enter your other values. Use the suffix you were first given: it's in the names of anything you already deployed, for example `rg-university-<suffix>`. The script refuses a different suffix if one is already stored. The VM admin password was in that folder too: run `./scripts/Get-PipelineEvidence.ps1` again to recreate the credentials file.

## Preflight

- **Preflight reports FAIL on Owner:** you have no unconditional Owner assignment on your workload subscription. Contributor doesn't pass. If Owner is eligible through Privileged Identity Management, activate it first; otherwise ask your team lead to escalate to the event owner.
- **Preflight fails on a resource provider:** the `whatif` stage registers missing providers for you. Wait up to 15 minutes for the registration to propagate, then run the stage again.
- **Preflight fails on the public IP feature, or a deployment stops with `SubscriptionNotRegisteredForFeature`:** a new subscription hasn't registered `Microsoft.Network/AllowBringYourOwnPublicIpAddress`, which the firewall, NAT and Bastion public IPs need. The `whatif` stage registers the feature and then `Microsoft.Network` again. Wait a few minutes and run it again.

## Datacenter and Arc

- **The `member` stage stops or fails on quota or a VM size:** read the run log, then run the stage again; it converges. If a quota or size error comes back, check **Usage + quotas** for your event's region (`swedencentral` unless told otherwise) in the Azure portal and tell your team lead; they can escalate to the event owner.
- **The datacenter test fails on in-VM checks:** both VMs must run, and the test precedes Arc. If onboarding never started, fix the failure and rerun. If onboarding already disabled the guest agent, do not rerun `member`: the test cannot use run commands anymore. Preserve the earlier PASS evidence and use the Arc recovery path.
- **Bastion won't connect:** connect from the Azure portal: `rg-datacenter` > the VM > **Connect** > **Bastion**, user `labadmin`. Check the VM is running. The native client (`Connect-DatacenterVm.ps1`) is an optional shortcut that works only from Windows with the Azure CLI Bastion extension.
- **Copilot isn't signed in on `vm-dev01`:** the VS Code extensions install at first logon, so give the first sign-in up to five minutes, then sign in to GitHub in VS Code.
- **Arc onboarding times out:** do not rerun `member`. It refuses an existing Arc machine; if onboarding stopped earlier but disabled the guest agent, a rerun instead fails at the test. Read `C:\LabTools\logs\Connect-AppArc.log` through Bastion and check outbound Arc access through NAT. If `Get-PipelineEvidence.ps1` has no successful run to download, use the [standard lab credentials reference](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/infra/datacenter/README.md#credentials) or get custom credentials privately from the team lead. Before C5, use the approved rebuild below; after C5, ask for a coach repair.

## ALZ-lite and vending

- **Vending can't find the hub:** confirm the `foundation` stage finished and the expected hub resource names exist (`vnet-hub`, `afw-hub`, `afwp-hub`, `rg-hub`) before you run the `vending` stage.
- **DNS stops resolving after vending:** stopped VMs may need restarting or `ipconfig /renew`. A rebuilt datacenter needs the team lead to rerun vending for that member before restarting. Never redeploy an Arc-connected datacenter.
- **`Grant-SqlMiDirectoryRead.ps1` stops with `InteractionRequired` or `TokenCreatedWithOutdatedPolicies`:** the role holder's Microsoft Graph sign-in is stale. They run `az logout`, then `az login` again as themselves, and repeat.
- **No datacenter exemptions appear:** normally correct: `rg-datacenter` complies with ALZ-lite and needs none. Bastion's standalone public IP is outside the NIC policy's scope. Record compliance and "none needed", plus the C2 deferred-work entry; do not rerun vending just to get exemptions. Investigate actual non-compliance with the team lead rather than ignoring it or bypassing tenant policy.

### If Arc onboarding needs recovery

**After Arc onboarding starts, before C5:** the stage refuses an Arc machine; a partially disabled guest agent can instead break the test. With the event owner's approval, rebuild with `teardown`, then `member`. In the member's own repo (member profile), run:

```bash
gh workflow run platform.yml -f stage=teardown
gh workflow run platform.yml -f stage=member
```

In the team lead's repo, run the same stages with the member's index:

```bash
gh workflow run platform.yml -f stage=teardown -f members=<your index>
gh workflow run platform.yml -f stage=member -f members=<your index>
```

Member `teardown` removes `rg-datacenter`, `rg-spoke` and the archetype, including the SQL Managed Instance. Repeat Step 3 and the `vm-dev01` setup. If the member does not hold eligible Windows Server licenses, add `-f no-hybrid-benefit=true` to the `member` command. If the member was already vended, the team lead must run `vending` for that index afterward. Before T+2, never run a full, unfiltered team `teardown` in the team lead's repo; pass `-f members=<your index>` or ask your team lead to escalate to the event owner for a coach repair. After C5, do not use this recovery; ask the event owner for a coach repair.

## Pipeline

- **`gh workflow run` says the workflow wasn't found (HTTP 404):** GitHub dispatches a workflow only from the default branch. Merge the import to `main` first, or run the stage from the **Actions** tab.
- **A run fails at once, with no steps and no log:** open the job's annotation. Private-repo Actions runs use the plan's included compute first; additional usage is billed to the repository owner. Ask the partner GitHub owner to check **Billing & Licensing**, the budget and payment method, then run the stage again.
- **Step 1.5 cannot create `gh-lab` or set its environment secrets:** check the partner organization's GitHub plan and your repo permissions before T-14. The owner reported a private-repo pipeline test on GitHub Free, but current [GitHub environment documentation](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments) says private-repo environments require Pro for personal accounts or Team for organizations, and private-repo required reviewers are Enterprise-only. Verify the setup in your own organization; if required reviewers are unavailable, write access is the gate. See the [Requirements](../../getting-started/requirements/#accounts-and-access) note and [issue #203](https://github.com/jonathan-vella/apex-factory-hackathon/issues/203).
- **A run waits and nothing happens:** it's waiting for the reviewer. Open the run and choose **Review deployments**. On a private repo with no reviewer option there's no gate, so a run that sits queued has lost its runner: cancel it and run the stage again.
- **Login fails with `AADSTS700213`:** the identity's credential doesn't match what your repo presents. Run `./scripts/Test-PipelineSetup.ps1` (add `-PipelineProfile Member` in your own repo): it names the failing check. Re-running `Initialize-PlatformPipeline.ps1` repairs the credential.
- **The guard refuses a subscription:** it isn't on the pipeline's approved list or is on its deny list. Check the roster and the repo's environment secrets with `Test-PipelineSetup.ps1`. Never add a subscription to the approved list to get past this unless it's part of the event.
- **`vm-app01 is already an Arc machine`:** the member stage never redeploys over Arc. Use the recovery above before C5; after C5, ask the event owner for a coach repair.
- **`Vending stopped at member N ... hub is incomplete`:** run the `foundation` stage first. Vending needs `vnet-hub`, `afw-hub`, `log-management` and `id-sqlmi-directory`.
- **The ALZ-lite what-if prints "First deployment":** expected. The what-if can't compare against management groups that don't exist yet. Run the `foundation` stage.
- **Removal stops before the team step:** a member's removal failed. Fix it, run `teardown` again, and the finished members are skipped. It also stops if a subscription under the Corp group isn't in the roster.
- **Preflight or another script fails with "Azure CLI returned an invalid JSON response":** an older kit copy merged Azure CLI warnings into its JSON (the dev container's Python 3.15 prints a `SyntaxWarning` on every run). Re-import the kit (`Import-Kit.ps1 -Force`, commit and merge it) to get the fix. In the meantime `$env:PYTHONWARNINGS = 'ignore'` in that terminal works around it.
- **Arc shows `vm-app01` Connected but no SQL Server instance appears:** the Azure extension for SQL Server (`WindowsAgent.SqlServer`) didn't install itself, which happens in some subscriptions (seen with every Defender for Cloud plan on). The `member` stage installs it after 5 minutes. On an older copy, install it in the portal: Azure Arc > Machines > `vm-app01` > Extensions > Add, choose the Azure extension for SQL Server and the **LicenseOnly** license type (Developer edition is free). The instances appear in a few minutes.
- **`Remove-PlatformPipeline.ps1` says it could not check the GitHub environment:** `gh` was refused, so the script can't tell whether it is gone. Sign in with `gh auth login` as an admin of the repo and run it again.
- **A subscription ID shows in a public run log:** delete that run (`gh run delete <id>`), then check that the value is stored as an environment secret and not a variable.

## Modernizing the app

- **The app falls back to a default connection after task 01:** task 01 resets the project's `UserSecretsId`. Re-enter your local user secrets afterward.
- **Blob or Service Bus calls return 403 on the dev VM:** `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` isn't set in that terminal, or VS Code was opened before it was set at the user level. Set it once, then restart every terminal and VS Code.
- **Production configuration refuses to start without Key Vault:** by design. The app refuses a connection string with a user name or password outside `Development`, and requires `KeyVault:VaultUri` outside `Development` too.

## APEX and the archetype

- **A native Windows checkout changes the archetype's tree hash:** APEX's `.gitattributes` forces LF for `*.bicep` but not `*.bicepparam`. Always run `/apex-adapt-archetype` in the dev container, never natively on Windows.
- **Preflight stops with `snet-sqlmi already hosts another managed instance`:** the suffix you ran it with isn't the suffix of the managed instance already in your subnet. Preflight accepts only `sqlmi-university-<suffix>` there, so a different suffix looks like someone else's instance. This happens when `SUFFIX` or `factory/.local/settings.json` holds a different value than your first deployment, for example after a new dev container, a second clone or a re-imported kit. Find the suffix you deployed with, from any resource name such as `rg-university-<suffix>`, set it again (`./scripts/Initialize-Settings.ps1 -Suffix '<old suffix>'` from `factory/`, and `azd env set SUFFIX <old suffix>` in `infra/bicep/university/`), and re-run. Never delete the managed instance to get past it. If the suffix is right and the message stays, a different instance really is on your subnet: stop and ask your team lead, who can escalate to the event owner.
- **`azd provision --preview` looks incomplete:** the preview only lists resource types `azd` has display names for. SQL MI, the managed identity, role assignments and diagnostic settings are still being created even though the preview doesn't name them.
- **Preflight says a SQL virtual cluster still holds `snet-sqlmi`:** a deleted MI's cluster can retain the subnet for hours. Wait for Azure to release it, then retry with the same suffix; do not delete the VNet, change suffix or remove the service association to force it.
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
