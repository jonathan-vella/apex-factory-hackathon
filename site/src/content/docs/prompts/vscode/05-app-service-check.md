---
title: "VS Code: App Service configuration check"
description: C6's read-only check of the web app's identity, settings and Key Vault access.
sidebar:
  label: App Service check (C6)
  order: 7
---

Used in [C6, requirement 5](../../../challenges/c06-modernize-with-ghcp/#requirements).

C6's step 5: **check, don't change**, the archetype's App Service configuration. These commands only read Azure
Resource Manager, so they work from any computer with `az` signed in, not only `vm-dev01` — except the image
tag check, which needs the registry (private, reachable only from `vm-dev01`).

## The prompt

```text
Check (don't change) the web app's configuration: its app settings, its managed identity, and that identity's role assignments, especially Key Vault Secrets User on the Key Vault. Use az CLI read-only commands. Report what you find; don't point the web app at the new image yet — that's C7.
```

## Run the commands yourself

Use the commands in [C6 requirement 5](../../../challenges/c06-modernize-with-ghcp/#requirements) and the playbook's
[Step 5](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#step-5-app-service-configuration-c6-and-go-live-c7).
Those are the single source for the App Service and image checks.

Use the `app-service-configuration` skill if you want the agent to drive this directly.

## Check

- App settings list `KeyVault__VaultUri` (App Service writes the `:` in `KeyVault:VaultUri` as `__`) and non-secret
  endpoints — no connection strings or secrets in plain app settings.
- The identity's role assignments include **Key Vault Secrets User** on `kv-university-<suffix>`.
- Your `c6`-tagged image is in the registry.
- The web app is **not** yet pointed at that image — it would exit on every start, because the database isn't
  migrated until C7.
