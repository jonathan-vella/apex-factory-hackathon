---
title: APEX
description: Adapting and deploying the CoE archetype with APEX agents and azd.
sidebar:
  order: 2
---

This guide covers the mechanics of the archetype deploy flow. [C5](../../challenges/c05-deploy-the-coe-archetype/) is the what and the acceptance bar.

## What APEX does here, and what it doesn't

APEX agents adapt the archetype template and document the result. They don't deploy it. Deployment is `azd provision`, run by you. That's a design choice of this kit: a human approves every live change to Azure.

## Get the archetype into your own repo

You did this in [Prerequisites](../../getting-started/prerequisites/): your repo is created from the `apex-accelerator` template, and `Import-Kit.ps1` copied the kit into `factory/` and the archetype's APEX project into the repo root. There are two copies of the archetype: the kit's own under `factory/archetype/`, and the working copy at the repo root (`agent-output/university/`, `infra/bicep/university/` and the `adapt-archetype` prompt). Edit and deploy only the root copy.

To redo only the archetype import, run `./factory/archetype/Import-Archetype.ps1 -Force` from the repo root. `-Force` replaces your copy of the archetype, so you lose any changes you made to it.

## Run in the dev container or Codespaces, not natively on Windows

Open the repo in VS Code's dev container, or in GitHub Codespaces. APEX's `.gitattributes` forces LF line endings for `*.bicep` files but not `*.bicepparam` files; a native Windows checkout turns `main.bicepparam` to CRLF, which changes its tree hash and breaks the governance check that compares it against the upstream template. The dev container avoids this entirely.

## Sign in to azd

`azd` keeps its own sign-in, separate from `az login`. In the dev container terminal, run `azd auth login --use-device-code` and follow the prompt, unless `azd` already tells you that you're signed in.

## Adapt and preview

Run the `adapt-archetype` prompt in VS Code's built-in agent mode (not the `01-Orchestrator` custom mode — this flow doesn't need the full orchestrator). It reads your tenant ID, subscription ID and suffix from `factory/.local/settings.json` and asks you to confirm them. Don't change the suffix: every later `<suffix>` command and resource name uses it. If your Codespace or dev container was deleted, `factory/.local/` went with it: restore the suffix with `./scripts/Initialize-Settings.ps1 -Suffix <old suffix>` from `factory/` before you run the prompt. The prompt then checks a spoke is already vended for you (if it isn't, your platform lead vends it in C2; members can't), runs a lightweight live governance check against the upstream template, creates an `azd` environment, and stops at `azd provision --preview`.

## Provision

Review the preview output, then run `azd provision` yourself, in `infra/bicep/university/` (where `azure.yaml` is; the `adapt-archetype` prompt's shell session is already there; in a new terminal run `cd infra/bicep/university` first). Its hooks run a preflight check, post-deploy tests and a deployment summary automatically — you don't need to run them separately.

:::danger[Don't run azd down to start over]

`azd down --purge` deletes `rg-university-<suffix>` and everything in it: the SQL Managed Instance and, after C7, the migrated database, the Key Vault secrets and your image in the registry. Re-provisioning a SQL Managed Instance takes hours. Never run it after C7. If you need a clean redo before C7, ask your coach first. The kit's own teardown, `Remove-FactoryEnvironment.ps1`, removes your whole environment and is for the end of the event.

:::

## Document

Run the As-Built agent (`08-As-Built`) to produce `agent-output/university/07-as-built.md`, recording what was actually deployed.

## If you'd rather skip the agents

The fallback runs a plain `az deployment sub create` against the same Bicep, with no agent and no `azd`. It's an optional path, not the primary one: the primary path's agent-plus-`azd` split keeps a human approving every live change. From the `factory/` folder of your repo (so the script and `.local/settings.json` resolve), preview, then deploy:

```powershell
cd factory
$s = Get-Content .local/settings.json | ConvertFrom-Json
./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix -WhatIf
./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix
```

Handing the deployment to the APEX Deploy agent (`07b-Bicep Deploy`) instead of `azd` is also possible; [the archetype README](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/archetype/README.md) covers it and what changes (the deployment summary file `azd` writes for you).

## Known gaps

- Tree-hash drift between this kit's copy of the archetype and the upstream `apex-accelerator` template is a known, deferred issue (tracked as [#52](https://github.com/jonathan-vella/apex-factory-hackathon/issues/52)). The governance check may warn without it being a real problem.
- The archetype's deployer identity doesn't currently have the Monitoring Metrics Publisher role on Application Insights (tracked as [#60](https://github.com/jonathan-vella/apex-factory-hackathon/issues/60)). C6's OpenTelemetry check (task 06) needs it on `vm-dev01`, and so can C8's telemetry checks, until it's granted. The playbook has the command for your own sign-in.
