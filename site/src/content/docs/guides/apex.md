---
title: APEX
description: Adapting and deploying the CoE archetype with APEX agents and azd.
sidebar:
  order: 3
---

**For:** every member deploying their own archetype.

**When:** [C5](../../challenges/c05-deploy-the-coe-archetype/).

**Before you start:** complete [Step 4: Vending](../../deploy/vending/) and C4's platform ADR, and open your own repo in its dev container. C5 holds the requirements and acceptance bar.

## What APEX does here, and what it doesn't

APEX agents adapt the archetype template and document the result. They don't deploy it. Deployment is `azd provision`, run by you. That's a design choice of this kit: a human approves every live change to Azure.

## Get the archetype into your own repo

You did this in [Step 1: Repo and preflight](../../deploy/set-up-your-repo/#12-import-the-kit): your repo is created from the `apex-accelerator` template, and the import copied the kit into `factory/` and the archetype's APEX project into the repo root. There are two copies of the archetype: the kit's own under `factory/archetype/`, and the working copy at the repo root (`agent-output/university/`, `infra/bicep/university/` and the `/apex-adapt-archetype` skill). Edit and deploy only the root copy.

To redo only the archetype import, run `./factory/archetype/Import-Archetype.ps1 -Force` from the repo root. `-Force` replaces your copy of the archetype, so you lose any changes you made to it.

## Run in the dev container, not natively on Windows

Open the repo in VS Code's dev container. APEX's `.gitattributes` forces LF line endings for `*.bicep` files but not `*.bicepparam` files; a native Windows checkout turns `main.bicepparam` into CRLF line endings, which makes APEX's governance check fail. The dev container avoids this entirely.

## Sign in to azd

`azd` is the Azure Developer CLI, preinstalled in the dev container ([overview](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview)). It keeps its own sign-in, separate from `az login`. In the dev container terminal, run `azd auth login --use-device-code` and follow the prompt, unless `azd` already tells you that you're signed in.

## Adapt and preview

Run the `/apex-adapt-archetype` skill in VS Code's built-in agent mode: open Copilot Chat, choose **Agent** in the mode picker (not the `01-Orchestrator` custom mode, because this flow doesn't need the full orchestrator) and type `/apex-adapt-archetype`. It reads your tenant ID, subscription ID and suffix from `factory/.local/settings.json` and asks you to confirm them. The suffix is the random six-character string of lowercase letters and digits that `Initialize-Settings.ps1` gave you; don't change it, because every later `<suffix>` command and resource name uses it. Rebuilding a dev container normally keeps `factory/.local/` because it is in your local repo. If you deleted the local clone or a volume holding it, restore the suffix with `./scripts/Initialize-Settings.ps1 -Suffix <old suffix>` from `factory/` before you run the skill. The skill then checks a spoke is already vended for you (if it isn't, your team lead runs the `vending` stage for you; members can't), runs a lightweight check of your tenant's Deny policies against the archetype's packaged governance constraints, creates an `azd` environment, and stops at `azd provision --preview`.

## Provision

Review the preview output and [C5's SQL MI licence check](../../challenges/c05-deploy-the-coe-archetype/#requirements), then run `azd provision` yourself in `infra/bicep/university/` (where `azure.yaml` is), in the same terminal as preflight. If you closed it, open PowerShell in the dev container at the repo root and load the settings explicitly:

```powershell
cd infra/bicep/university
$s = Get-Content ../../../factory/.local/settings.json | ConvertFrom-Json
./scripts/preflight.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix
azd provision --preview
```

Review the preview before running `azd provision`. Deployment waits for the SQL Managed Instance and takes about 20 minutes (measured: 22 min 59 s on 2026-10-08, 20 min 2 s on 2026-10-20), so you can start C6 meanwhile. Hooks run preflight, post-deploy tests and a deployment summary automatically.

:::danger[Don't run azd down to start over]

`azd down --purge` deletes `rg-university-<suffix>` and everything in it: the SQL Managed Instance and, after C7, the migrated database, the Key Vault secrets and your image in the registry. Re-provisioning a SQL Managed Instance takes hours. Never run it after C7. If you need a clean redo before C7, ask your coach first. The kit's own cleanup, the `teardown` stage, removes your whole environment and is for the end of the event.

:::

## Document

In Copilot Chat, pick the `08-As-Built` agent and ask it to document the deployed state. It produces the `agent-output/university/07-*.md` documentation suite (for example `07-documentation-index.md`), recording what was actually deployed, and takes about 30 minutes. If `azd` prints an `apex-recall ...` command, run that first in its terminal.

## If you'd rather skip the agents

The fallback runs a plain `az deployment sub create` against the same Bicep, with no agent and no `azd`. It's an optional path, not the primary one: the primary path's agent-plus-`azd` split keeps a human approving every live change. From your repo's root folder, preview, then deploy:

:::danger[The fallback replaces azd; never layer it over azd]

Do not run the fallback for real after `azd` in the same subscription: it targets the same resource group and SQL MI subnet and can reset the app to the placeholder image. Never run it after C7. For C5's comparison bonus, use `-WhatIf` only.

:::

```powershell
cd factory
$s = Get-Content .local/settings.json | ConvertFrom-Json
./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix -WhatIf
./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix
```

The kit supports `azd` and this fallback. APEX Deploy (`07b-Bicep Deploy`) also works, but it is unsupported during the event and coaches do not support it; use the `azd` path above.

## Known gaps

- The archetype now gives its deployer the Monitoring Metrics Publisher role on Application Insights, which C6's OpenTelemetry check (task 06) and C8's telemetry checks need. A deployment that lacks it needs the grant run once by you: the playbook has the one-time command for your own sign-in.
