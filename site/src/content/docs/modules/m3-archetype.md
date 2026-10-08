---
title: "M3: Archetype"
description: Deploy the CoE archetype's platform with APEX and azd.
---

## Covers

[C5: Deploy the CoE archetype with APEX](../../challenges/c05-deploy-the-coe-archetype/).

## Prerequisites

M1's vended spoke for the member. M2's platform ADR (informs the archetype's parameters, though the archetype's shape is fixed by the kit).

## Bootstrap (standalone)

Create a repo from the `apex-accelerator` template at the commit pinned in `archetype/README.md`, import this kit's `archetype/` folder, and run the `adapt-archetype` prompt in the dev container or Codespaces, followed by `azd provision`.

## Exit evidence

- `agent-output/university/07-as-built.md` from the As-Built agent.
- Every archetype resource present in `rg-university-<suffix>`, policy-compliant.
- No public endpoints other than the web app's front end and Application Insights ingestion.

## Reset

`azd down --purge` removes the deployment; re-run `adapt-archetype` and `azd provision` to redeploy. The `deploy.ps1 -WhatIf` / `deploy.ps1` fallback works without the agent or `azd` if needed.

## Time box

90 minutes (plus a 30-minute coach demo, not counted in the module's own time box).

## Last validated

2026-10-07 (B09).
