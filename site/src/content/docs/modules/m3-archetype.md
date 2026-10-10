---
title: "M3: Archetype"
description: Deploy the CoE archetype's platform with APEX and azd.
---

## Covers

[C5: Deploy the CoE archetype with APEX](../../challenges/c05-deploy-the-coe-archetype/). The tasks and evidence are on the challenge page; the [APEX guide](../../guides/apex/) has the mechanics.

## Prerequisites

M1's vended spoke for the member. M2's platform ADR, which informs the archetype's parameters (the archetype's shape is fixed by the kit).

## Where to run

The dev container or Codespaces of your own repo, not natively on Windows. The `adapt-archetype` prompt runs at the repo root, `azd` runs in `infra/bicep/university/`, and the other commands run from `factory/`.

## Bootstrap (standalone)

In your repo created from the `apex-accelerator` template, with the kit imported as in Prerequisites (`Import-Kit.ps1` also imports the archetype), sign in to azd (`azd auth login --use-device-code`), run the `adapt-archetype` prompt, then `azd provision` yourself.

## Exit evidence

The items in [C5's Evidence](../../challenges/c05-deploy-the-coe-archetype/#evidence), including `agent-output/university/07-as-built.md` from the As-Built agent and every expected resource in `rg-university-<suffix>`.

## Reset

:::danger[Resetting deletes the SQL Managed Instance]

`azd down --purge` deletes `rg-university-<suffix>` and everything in it, including the SQL Managed Instance and, after C7, the migrated database, the Key Vault secrets and your registry image. Re-provisioning a SQL Managed Instance takes hours. Never run it after C7, and ask your coach first at any time.

:::

To redeploy, re-run `adapt-archetype` and `azd provision`. The `deploy.ps1` fallback works without the agent or `azd`: see the [APEX guide](../../guides/apex/#if-youd-rather-skip-the-agents).

## Time box

90 minutes, including the 30-minute coach demo.
