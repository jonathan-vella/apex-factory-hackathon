---
title: Prerequisites
description: What to have ready before T-14, and the preflight's manual checks.
---

## Access

- An assigned Azure workload subscription (members) or shared services subscription (platform lead).
- GitHub access to the kit's repositories, with GitHub Copilot enabled.
- Multi-factor authentication registered for your Azure identity.

## Automated checks

Run `scripts/Test-Preflight.ps1 -Fix` from a machine with the Azure CLI and PowerShell 7 installed. It checks and can register the resource providers the kit needs, and reports anything it can't fix for itself.

## Manual checks

`Test-Preflight.ps1` can't verify these for you — confirm them yourself before T-14:

- Your GitHub Copilot licence and policy allow the Upgrade agent and agent mode.
- Your Azure role assignments match your kit role (platform lead needs Tenant Root Owner; members need Contributor on their own workload subscription).
- You can sign in interactively to Azure (`az login`) and to GitHub (`gh auth login`) from the machine you'll use for the event.
- If you're the platform lead, you have a shared services subscription separate from every member's workload subscription — ALZ-lite's two-subscription model depends on this.

See the [ALZ-lite guide](../../guides/alz-lite/) for why the model needs two kinds of subscription, and [Pre-work](../pre-work/) for what to actually run.
