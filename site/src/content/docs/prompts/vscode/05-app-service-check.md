---
title: "VS Code: App Service configuration check"
description: C6's read-only check of the web app's identity, settings and Key Vault access.
sidebar:
  order: 6
---

C6's step 5: **check, don't change**, the archetype's App Service configuration. These commands only read Azure
Resource Manager, so they work from any computer with `az` signed in, not only `vm-dev01` — except the image
tag check, which needs the registry (private, reachable only from `vm-dev01`).

## The prompt

```text
Check (don't change) the web app's configuration: its app settings, its managed identity, and that identity's role assignments, especially Key Vault Secrets User on the Key Vault. Use az CLI read-only commands. Report what you find; don't point the web app at the new image yet — that's C7.
```

## Or run the commands yourself

`<suffix>` is the suffix in your resource group's name, `rg-university-<suffix>`. The first two lines read
it from Azure, so you don't type it:

```powershell
$rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
$suffix = $rg -replace '^rg-university-', ''
az webapp config appsettings list --resource-group $rg --name "app-university-$suffix" --query "[].name" --output tsv
$id = az identity show --resource-group $rg --name "id-university-$suffix" --query principalId --output tsv
az role assignment list --assignee $id --all --query "[].{role:roleDefinitionName, scope:scope}" --output table
az acr repository show-tags --name "cruniversity$suffix" --repository contoso-university --output table
```

Use the `app-service-configuration` skill if you want the agent to drive this directly.

## Check

- App settings list `KeyVault__VaultUri` (App Service writes the `:` in `KeyVault:VaultUri` as `__`) and non-secret
  endpoints — no connection strings or secrets in plain app settings.
- The identity's role assignments include **Key Vault Secrets User** on `kv-university-<suffix>`.
- Your `c6`-tagged image is in the registry.
- The web app is **not** yet pointed at that image — it would exit on every start, because the database isn't
  migrated until C7.
