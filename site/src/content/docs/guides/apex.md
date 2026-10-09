---
title: APEX
description: Adapting and deploying the CoE archetype with APEX agents and azd.
---

This guide covers the mechanics of the archetype deploy flow. [C5](../../challenges/c05-deploy-the-coe-archetype/) is the what and the acceptance bar.

## What APEX does here, and what it doesn't

APEX agents adapt the archetype template and document the result. They don't deploy it. Deployment is `azd provision`, run by you — an owner decision to keep a human approving every live change to Azure.

## Get the archetype into your own repo

You did this in [Prerequisites](../../getting-started/prerequisites/): your repo is created from the `apex-accelerator` template, and `Import-Kit.ps1` copied the kit into `factory/` and the archetype's APEX project into the repo root. To redo only the archetype import, run `./factory/archetype/Import-Archetype.ps1 -Ref main -Force` from the repo root.

## Run in the dev container or Codespaces, not natively on Windows

Open the repo in VS Code's dev container, or in GitHub Codespaces. APEX's `.gitattributes` forces LF line endings for `*.bicep` files but not `*.bicepparam` files; a native Windows checkout turns `main.bicepparam` to CRLF, which changes its tree hash and breaks the governance check that compares it against the upstream template. The dev container avoids this entirely.

## Adapt and preview

Run the `adapt-archetype` prompt in VS Code's built-in agent mode (not the `01-Orchestrator` custom mode — this flow doesn't need the full orchestrator). It asks for your tenant ID, subscription ID and suffix, checks a spoke is already vended for you, runs a lightweight live governance check against the upstream template, creates an `azd` environment, and stops at `azd provision --preview`.

## Provision

Review the preview output, then run `azd provision` yourself. Its hooks run a preflight check, post-deploy tests and a deployment summary automatically — you don't need to run them separately.

## Document

Run the As-Built agent (`08-As-Built`) to produce `agent-output/university/07-as-built.md`, recording what was actually deployed.

## If you'd rather skip the agents

`archetype/deploy.ps1 -WhatIf`, then `archetype/deploy.ps1` for real, runs a plain `az deployment sub create` against the same Bicep, with no agent and no `azd` involved. It's a fallback, not the primary path — the primary path's agent-plus-`azd` split is the owner's intended pattern for this kit.

## Known gaps

- Tree-hash drift between this kit's copy of the archetype and the upstream `apex-accelerator` template is a known, deferred issue (tracked as #52) — the governance check may warn without it being a real problem.
- The archetype's deployer identity doesn't currently have the Monitoring Metrics Publisher role on Application Insights (tracked as #60), which can affect C8's telemetry checks until it's granted.
