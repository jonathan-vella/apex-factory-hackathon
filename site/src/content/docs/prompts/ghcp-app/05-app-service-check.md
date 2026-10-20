---
title: "Copilot App: App Service configuration check"
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

```powershell
az webapp config appsettings list -g rg-university-<suffix> -n app-university-<suffix> --query "[].name" -o tsv
$id = az identity show -g rg-university-<suffix> -n id-university-<suffix> --query principalId -o tsv
az role assignment list --assignee $id --all --query "[].{role:roleDefinitionName, scope:scope}" -o table
az acr repository show-tags -n cruniversity<suffix> --repository contoso-university -o table
```

## Check

- App settings list `KeyVault:VaultUri` and non-secret endpoints — no connection strings or secrets in plain
  app settings.
- The identity's role assignments include **Key Vault Secrets User** on `kv-university-<suffix>`.
- Your `c6`-tagged image is in the registry.
- The web app is **not** yet pointed at that image — it would exit on every start, because the database isn't
  migrated until C7.
