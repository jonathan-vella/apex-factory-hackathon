---
title: Troubleshooting
description: Known traps from the kit's own validation runs.
sidebar:
  order: 6
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

- **Preflight reports FAIL on Owner:** you have no unconditional Owner assignment on your workload subscription. Contributor doesn't pass. If Owner is eligible through Privileged Identity Management, activate it first; otherwise ask your coach.
- **Preflight fails on a resource provider:** the `whatif` stage registers missing providers for you. Wait up to 15 minutes for the registration to propagate, then run the stage again.
- **Preflight fails on the public IP feature, or a deployment stops with `SubscriptionNotRegisteredForFeature`:** a new subscription hasn't registered `Microsoft.Network/AllowBringYourOwnPublicIpAddress`, which the firewall, NAT and Bastion public IPs need. The `whatif` stage registers the feature and then `Microsoft.Network` again. Wait a few minutes and run it again.

## Datacenter and Arc

- **The `member` stage stops or fails on quota or a VM size:** read the run log, then run the stage again; it converges. If a quota or size error comes back, check **Usage + quotas** for `swedencentral` in the Azure portal and tell your coach.
- **The datacenter test fails on in-VM checks:** the VMs must be running, and the test runs before Arc onboarding. After Arc onboarding the run commands no longer work, so don't run the `member` stage again. The stage stops before Arc when the test fails: read the run log, then run it again. Keep the PASS output from the run that passed as your evidence (`Get-PipelineEvidence.ps1` downloads it).
- **Bastion won't connect:** connect from the Azure portal: `rg-datacenter` > the VM > **Connect** > **Bastion**, user `labadmin`. Check the VM is running. The native client (`Connect-DatacenterVm.ps1`) is an optional shortcut that works only from Windows with the Azure CLI Bastion extension.
- **Copilot isn't signed in on `vm-dev01`:** the VS Code extensions install at first logon, so give the first sign-in up to five minutes, then sign in to GitHub in VS Code.
- **Arc onboarding times out:** don't run the `member` stage again. Once onboarding has started, it turns off the VM's guest agent and the stage refuses a second run, and a redeploy can't recover it. Read the run log, then connect to `vm-app01` through Bastion and read `C:\LabTools\logs\Connect-AppArc.log` (open it in Notepad). Check outbound access to Arc's endpoints through the NAT gateway first if the log shows a network error. If onboarding didn't finish, stop and tell your coach: the recovery is the `teardown` stage, then the `member` stage again. Before C5 only: after C5, `teardown` also removes the archetype, including the SQL Managed Instance, which takes hours to provision again, so never run it then without asking your coach first.

## ALZ-lite and vending

- **Vending can't find the hub:** confirm the `foundation` stage finished and the expected hub resource names exist (`vnet-hub`, `afw-hub`, `afwp-hub`, `rg-hub`) before you run the `vending` stage.
- **DNS stops resolving after vending changes a VNet's DNS servers:** running VMs cache their old DNS settings. The `vending` stage restarts both VMs at T-1; if yours were stopped or redeployed since, restart the VM, or run `ipconfig /renew` inside it.
- **`Grant-SqlMiDirectoryRead.ps1` stops with `InteractionRequired` or `TokenCreatedWithOutdatedPolicies`:** the role holder's Microsoft Graph sign-in is stale. They run `az logout`, then `az login` again as themselves, and repeat.
- **The datacenter shows as policy non-compliant:** expected until it has exemptions. The `vending` stage at T-1 records them, and you check them in C2. It was deployed before the subscription moved under the management group hierarchy. Ignore it in the readiness check.

## Pipeline

- **`gh workflow run` says the workflow wasn't found (HTTP 404):** GitHub dispatches a workflow only from the default branch. Merge the import to `main` first, or run the stage from the **Actions** tab.
- **A run waits and nothing happens:** it's waiting for the reviewer. Open the run and choose **Review deployments**. On a private repo with no reviewer option there's no gate, so a run that sits queued has lost its runner: cancel it and run the stage again.
- **Login fails with `AADSTS700213`:** the identity's credential doesn't match what your repo presents. Run `./scripts/Test-PipelineSetup.ps1` (add `-PipelineProfile Member` in your own repo): it names the failing check. Re-running `Initialize-PlatformPipeline.ps1` repairs the credential.
- **The guard refuses a subscription:** it isn't on the pipeline's approved list or is on its deny list. Check the roster and the repo's environment secrets with `Test-PipelineSetup.ps1`. Never add a subscription to the approved list to get past this unless it's part of the event.
- **`vm-app01 is already an Arc machine`:** the member stage never redeploys over Arc, because Arc can't be undone. Before C5, run the `teardown` stage for that member, then the `member` stage again. After C5, never do this without asking your coach first: the member `teardown` stage removes the archetype, including the SQL Managed Instance, which takes hours to provision again.
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
- **Preflight stops with `snet-sqlmi already hosts another managed instance`:** the suffix you ran it with isn't the suffix of the managed instance already in your subnet. Preflight accepts only `sqlmi-university-<suffix>` there, so a different suffix looks like someone else's instance. This happens when `SUFFIX` or `factory/.local/settings.json` holds a different value than your first deployment, for example after a new dev container, a second clone or a re-imported kit. Find the suffix you deployed with, from any resource name such as `rg-university-<suffix>`, set it again (`./scripts/Initialize-Settings.ps1 -Suffix '<old suffix>'` from `factory/`, and `azd env set SUFFIX <old suffix>` in `infra/bicep/university/`), and re-run. Never delete the managed instance to get past it. If the suffix is right and the message stays, a different instance really is on your subnet: ask your coach.
- **`azd provision --preview` looks incomplete:** the preview only lists resource types `azd` has display names for. SQL MI, the managed identity, role assignments and diagnostic settings are still being created even though the preview doesn't name them.

## Migration

- **`CREATE USER ... FROM EXTERNAL PROVIDER` fails before cutover:** the replica is read-only until cutover completes. This is expected, not a bug, and the command only succeeds afterward.
- **An aborted MI link leaves a writable copy of the database behind:** delete it before reseeding, or the next seed attempt fails.
- **A planned failover run from the managed instance side fails:** cut over from the Arc portal's pane, not with a CLI command issued from the MI. See the [Azure Arc and the MI link guide](../../guides/arc-mi-link/).

## Where to go next

If your problem isn't here, ask your coach. Otherwise go back to [Requirements](../../getting-started/requirements/), [Member steps](../../deploy/member-steps/) or the [challenges overview](../../challenges/).
