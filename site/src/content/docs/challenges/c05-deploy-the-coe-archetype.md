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

C2's vended spoke. C4's platform ADR. The APEX repo you created and imported the kit into during Prerequisites.

## Where to run

Open your own repo in its dev container (VS Code, **Reopen in Container**), then in the terminal:

```bash
pwsh
cd factory
$s = Get-Content .local/settings.json | ConvertFrom-Json
```

The `adapt-archetype` prompt runs at the repo root (not in `factory/`); `azd` runs in `infra/bicep/university/` (the prompt takes you there; `azure.yaml` is in that folder); every other command here runs from `factory/`. If `az account show` fails, run `az login --use-device-code`.

## Your tasks

1. Watch the coach's demo of the archetype's shape and the `adapt-archetype` flow.
2. Open your own repo (created from the `apex-accelerator` template in [Prerequisites](../../getting-started/prerequisites/)) in its dev container or Codespaces, and confirm the archetype is already there: `agent-output/university/`, `infra/bicep/university/` and `.github/prompts/adapt-archetype.prompt.md` exist at the repo root. If they don't, run `./factory/archetype/Import-Archetype.ps1` from the repo root (or the `Import-Kit.ps1` step from Prerequisites if `factory/` doesn't exist).
3. Run the `adapt-archetype` prompt in VS Code's built-in agent mode, in the dev container or Codespaces (not natively on Windows). It's self-contained: it reads your tenant ID, subscription ID and suffix from `factory/.local/settings.json` (and asks you to confirm them; it asks for them if the file is missing), checks a spoke is already vended, runs a lightweight live governance check, and stops at `azd provision --preview`. If it says the spoke is missing, your platform lead has to vend your subscription (C2); members can't.
4. Review the preview, then run `azd provision` yourself to deploy for real.
5. Run **As-Built** (agent `08-As-Built`) to generate the deployed-state document.
6. Confirm: no public endpoints other than the web app's front end and Application Insights ingestion; every resource uses the naming convention; the web app's managed identity has the roles it needs.

## Evidence

- The archetype repo, with `adapt-archetype`'s outputs and `azd provision`'s deployment record.
- `agent-output/university/07-as-built.md` from the As-Built agent.
- `az resource list -g rg-university-<suffix> -o table` showing every expected resource.
- A note of any policy-compliance finding the governance check surfaced, and how you resolved it.

## Hints

<details>
<summary>`adapt-archetype` won't find a vended spoke</summary>

It looks for `rg-spoke`, `vnet-spoke`, `snet-app`, `snet-pe` and `snet-sqlmi` by the backlog naming convention. Confirm C2's vending ran for your member index before retrying.
</details>

<details>
<summary>`azd provision --preview` looks incomplete</summary>

The preview only lists resource types `azd` has display names for — it's expected to omit the SQL Managed Instance, the managed identity, role assignments, diagnostic settings and the maintenance schedule even though they're all in the template and will be created.
</details>

<details>
<summary>I'd rather run this natively on Windows</summary>

Don't: APEX's `.gitattributes` forces LF for `*.bicep` but not `*.bicepparam`, and a native Windows checkout turns `main.bicepparam` to CRLF, which breaks the tree hash. Use the dev container or Codespaces.
</details>

## Bonus

Up to 5 pts for running the no-agent fallback (`archetype/deploy.ps1 -WhatIf`, then for real) side by side and comparing its output with the APEX + `azd` path.

## Learn more

- [What is Azure Developer CLI (`azd`)?](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
