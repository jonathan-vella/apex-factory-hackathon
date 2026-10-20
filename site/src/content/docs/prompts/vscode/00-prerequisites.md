---
title: "VS Code: prerequisites"
description: Step 0 of the playbook, condensed to a checklist.
sidebar:
  order: 1
---

This is the kit's validated golden path. Full detail is in the playbook's
[Step 0: Set up](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#step-0-set-up) —
this page is the checklist version.

## Checklist

1. **Signed in.** `gh auth login --web` and `az login --use-device-code`; `az account show` names your
   workload subscription.
2. **Git identity set**, so the first commit on `vm-dev01` doesn't fail.
3. **`AZURE_TOKEN_CREDENTIALS=AzureCliCredential`** set at the user level, then every terminal and VS Code
   restarted. Without it the app gets 403 from Blob, Service Bus and Key Vault — your own identity holds the
   data roles, not the app's managed identity, when running locally.

   ```powershell
   [Environment]::SetEnvironmentVariable('AZURE_TOKEN_CREDENTIALS', 'AzureCliCredential', 'User')
   ```

   Set it only on `vm-dev01`. On App Service the app uses its managed identity instead.
4. **On your `vm-dev01-work` branch**, in the kit clone at `C:\src\factory`, with a clean tree:

   ```powershell
   git branch -vv                       # must show * vm-dev01-work tracking member/vm-dev01-work
   git clean -ndx -- app .github        # dry run first
   git clean -fdx -- app .github
   git status --short --ignored -- app .github   # must print nothing
   ```

5. **VS Code open on the clone root** (`code C:\src\factory`), not the `app` folder — the agent needs
   `.github/skills/` and `.github/modernization/` visible. **GitHub Copilot upgrade** installed and enabled;
   **GitHub Copilot modernization**, if installed, disabled for the workspace.
6. **Harness set to Local** in the Chat panel's Session Target, and the Upgrade server given model access once
   (**MCP: List Servers** > **Upgrade** > **Configure Model Access**).

## Check

`az account show` names your workload subscription, `git status --short` prints nothing, and the agent picker
lists **Upgrade**. Continue to [Assess and plan](../01-assess-and-plan/).
