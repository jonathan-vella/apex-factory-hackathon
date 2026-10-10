---
title: "C5: Deploy the CoE archetype with APEX"
description: Adapt and deploy the platform the modernized app will run on.
---

## Goal

Get the CoE archetype — App Service, ACR, SQL MI, Blob, Service Bus, Key Vault and Application Insights — deployed into your spoke, policy-compliant, with its As-Built record.

## Scope and time box

Member. **90 min** (30 min demo + 60 min hands-on).

## Points

**15 pts** (member).

## Inputs

C2's vended spoke (vended with your object ID, so `-MemberPrincipalId` was set). C4's platform ADR. The APEX repo you created and imported the kit into during Prerequisites.

## Where to run

Open your own repo in its dev container (VS Code, **Reopen in Container**), then in the terminal:

```bash
pwsh
cd factory
$s = Get-Content .local/settings.json | ConvertFrom-Json
```

The `adapt-archetype` prompt runs from the repo root (not `factory/`). `azd` runs in `infra/bicep/university/`, in the same terminal session in which the prompt ran its `./scripts/preflight.ps1` (the prompt takes you there; `azure.yaml` is in that folder). Every other command here runs from `factory/`. If `az account show` fails, run `az login --use-device-code`.

## Your tasks

1. Watch the coach's demo of the archetype's shape and the `adapt-archetype` flow.
2. Open your own repo (created from the `apex-accelerator` template in [Prerequisites](../../getting-started/prerequisites/)) in its dev container or Codespaces, and confirm the archetype is already there: `agent-output/university/`, `infra/bicep/university/` and `.github/prompts/adapt-archetype.prompt.md` exist at the repo root. If they don't, run `./factory/archetype/Import-Archetype.ps1` from the repo root (or the `Import-Kit.ps1` step from Prerequisites if `factory/` doesn't exist).
3. Run the `adapt-archetype` prompt in VS Code's built-in agent mode, in the dev container or Codespaces (not natively on Windows): open Copilot Chat, switch to agent mode and type `/adapt-archetype`. It reads your tenant ID, subscription ID and suffix from `factory/.local/settings.json` (the `$s.tenantId`, `$s.subscriptionId` and `$s.suffix` values from your terminal) and asks you to confirm them; it asks for them if the file is missing. It checks a spoke is already vended, runs a lightweight live governance check, and stops at `azd provision --preview`. If it says the spoke is missing, your platform lead has to vend your subscription (C2); members can't. Done when the prompt shows the preview. If your Codespace or dev container was deleted, `factory/.local/` is gone: restore your suffix first with `./scripts/Initialize-Settings.ps1 -Suffix <old suffix>` from `factory/` (use the suffix you were first given), then reload `$s`.
4. Review the preview, then run `azd provision` yourself from `infra/bicep/university/` to deploy for real. It waits until the SQL Managed Instance is created, which can take a long time, so keep that terminal open. No provisioning time has been measured for this kit yet. You can start C6 on `vm-dev01` while it runs. Done when `azd provision` returns without an error and `rg-university-<suffix>` exists.
5. When `azd provision` returns, run **As-Built** (agent `08-As-Built`): in Copilot Chat in your repo, pick the `08-As-Built` agent from the agent picker and ask it to document the deployed state. If `azd`'s post-provision output says to run an `apex-recall` command first, run it. Done when `agent-output/university/07-as-built.md` exists.
6. Confirm the deployment, from `factory/`, with your suffix:

   ```powershell
   az resource list -g rg-university-$($s.suffix) -o table
   az storage account show -g rg-university-$($s.suffix) -n stuniversity$($s.suffix) --query publicNetworkAccess -o tsv
   az keyvault show -n kv-university-$($s.suffix) --query properties.publicNetworkAccess -o tsv
   az servicebus namespace show -g rg-university-$($s.suffix) -n sbns-university-$($s.suffix) --query publicNetworkAccess -o tsv
   az acr show -n cruniversity$($s.suffix) --query publicNetworkAccess -o tsv
   $id = az identity show -g rg-university-$($s.suffix) -n id-university-$($s.suffix) --query principalId -o tsv
   az role assignment list --assignee $id --all -o table
   ```

   Done when there are no public endpoints other than the web app's front end and Application Insights ingestion (the four `publicNetworkAccess` values are `Disabled`), every resource name follows the convention, and the web app's managed identity has the roles it needs.

## Evidence

Save screenshots and output as files in `evidence/c05/member-<n>/` in the team repo, and commit and push them. Redact subscription, tenant and object IDs first.

- Your own repo, with `adapt-archetype`'s outputs and `azd provision`'s deployment record.
- `agent-output/university/07-as-built.md` from the As-Built agent.
- `az resource list -g rg-university-<suffix> -o table` showing every expected resource.
- A note of any policy-compliance finding the governance check surfaced, and how you resolved it.

## Hints

<details>
<summary>adapt-archetype won't find a vended spoke</summary>

It looks for `rg-spoke`, `vnet-spoke`, `snet-app`, `snet-pe` and `snet-sqlmi` by the naming convention in the [naming and IP plan](../../reference/naming-and-ip-plan/). Confirm C2's vending ran for your member index before retrying.
</details>

<details>
<summary>Preflight says the managed identity "cannot be read" or lacks the assign permission</summary>

Your vending ran without your object ID, so you don't have Managed Identity Operator on `id-sqlmi-directory`. Only the platform lead can fix it: ask them to re-run `Deploy-Vending.ps1` for you with `-MemberPrincipalId` (C2, task 5).
</details>

<details>
<summary>Preflight says a SQL virtual cluster holds snet-sqlmi</summary>

A managed instance was deleted from your spoke earlier, and Azure releases its virtual cluster later (this can take hours). Wait and retry, and ask your coach before you delete anything.
</details>

<details>
<summary>azd provision --preview looks incomplete</summary>

The preview only lists resource types `azd` has display names for — it's expected to omit the SQL Managed Instance, the managed identity, role assignments, diagnostic settings and the maintenance schedule even though they're all in the template and will be created.
</details>

<details>
<summary>I'd rather run this natively on Windows</summary>

Don't: APEX's `.gitattributes` forces LF for `*.bicep` but not `*.bicepparam`, and a native Windows checkout turns `main.bicepparam` to CRLF, which breaks the tree hash. Use the dev container or Codespaces.
</details>

## Bonus

Up to 5 pts for comparing the no-agent fallback with the APEX + `azd` path, in preview only: run `./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix -WhatIf` from `factory/`, and compare its what-if output with `azd provision --preview`. Don't run the fallback for real after `azd` in the same subscription: it deploys the same resource group and SQL managed instance subnet, and it can reset the web app to the placeholder image.

## Learn more

- [What is Azure Developer CLI (`azd`)?](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
