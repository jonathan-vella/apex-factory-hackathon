---
title: Troubleshooting
description: Known traps from the kit's own validation runs.
---

## Preflight and onboarding

- **Preflight fails on a resource provider:** re-run `Test-Preflight.ps1 -Fix` and wait up to 15 minutes for the registration to propagate before re-checking.
- **Arc onboarding times out:** don't just run `Connect-DatacenterArc.ps1` again. Once it has started, it turns off the VM's guest agent and refuses a second run. Connect to `vm-app01` through Bastion and read `C:\LabTools\logs\Connect-AppArc.log`. If onboarding didn't finish, redeploy `vm-app01` with `Deploy-Datacenter.ps1` and run the Arc script again. Check outbound access to Arc's endpoints through the NAT gateway first if the log shows a network error.

## ALZ-lite and vending

- **Vending can't find the hub:** confirm ALZ-lite finished and the expected hub resource names exist (`vnet-hub`, `afw-hub`, `afwp-hub`, `rg-hub`) before running `Deploy-Vending.ps1`.
- **DNS stops resolving after vending changes a VNet's DNS servers:** running VMs cache their old DNS settings — restart the VM, or run `ipconfig /renew` inside it.
- **The datacenter shows as policy non-compliant:** expected until `New-DatacenterExemptions.ps1` runs — it was deployed before the subscription moved under the management group hierarchy.

## Modernizing the app

- **The app falls back to a default connection after task 01:** task 01 resets the project's `UserSecretsId` — re-enter your local user secrets afterward.
- **Blob or Service Bus calls return 403 on the dev VM:** `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` isn't set in that terminal, or VS Code was opened before it was set at the user level. Set it once, then restart every terminal and VS Code.
- **Production configuration refuses to start without Key Vault:** by design — the app refuses a connection string with a user name or password outside `Development`, and requires `KeyVault:VaultUri` outside `Development` too.

## APEX and the archetype

- **A native Windows checkout changes the archetype's tree hash:** APEX's `.gitattributes` forces LF for `*.bicep` but not `*.bicepparam`; always run `adapt-archetype` in the dev container or Codespaces, never natively on Windows.
- **`azd provision --preview` looks incomplete:** the preview only lists resource types `azd` has display names for — SQL MI, the managed identity, role assignments and diagnostic settings are still being created even though the preview doesn't name them.

## Migration

- **`CREATE USER ... FROM EXTERNAL PROVIDER` fails before cutover:** the replica is read-only until cutover completes — this is expected, not a bug, and the command only succeeds afterward.
- **An aborted MI link leaves a writable copy of the database behind:** delete it before reseeding, or the next seed attempt fails.
- **A planned failover run from the managed instance side fails:** cut over from the Arc portal's pane, not with a CLI command issued from the MI — see the [Azure Arc and the MI link guide](../../guides/arc-mi-link/).
