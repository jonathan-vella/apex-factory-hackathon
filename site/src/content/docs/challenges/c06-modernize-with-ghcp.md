---
title: "C6: Modernize with GHCP"
description: Run the Upgrade agent's seven tasks to .NET 10, with the app running on the dev VM.
---

## Goal

Take Contoso University from .NET Framework 4.8 to .NET 10 and ASP.NET Core MVC, with uploads on Blob, notifications on Service Bus, secrets in Key Vault and telemetry in Application Insights — running on `vm-dev01` against the source database, and packaged for App Service.

## Scope and time box

Member. **180 min**.

## Points

**30 pts** (member).

## Inputs

C3's reviewed assessment and plan. C5's deployed archetype (for the registry and the App Service identity you'll check against, not deploy to).

## Your tasks

1. Follow the [GHCP upgrade guide](../../guides/ghcp-upgrade/) and the [modernization playbook](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md): harness **Local**, agent **Upgrade**, one task per new chat, build and run the app after every task, commit and push before the next.
2. Run all seven tasks in order: .NET 10 and ASP.NET Core MVC; SQL Managed Instance; Blob; Service Bus; Key Vault; OpenTelemetry; CVE audit. Each task's check is in the playbook's task table — don't skip a check to save time.
3. Close the gaps the tasks don't fully cover, using the three skills in `.github/skills/` if a check fails.
4. Package the app with .NET SDK container publishing (no Dockerfile) and push it to your archetype's private registry.
5. Check — don't set — the web app's App Service configuration: its identity, its app settings, and that your image landed in the registry. **Don't point the web app at your image yet**: the modernized app reads its database at startup, and the database isn't migrated until C7. Pointing it now just makes the app exit repeatedly, which teaches nothing.

## Evidence

- Seven task commits (`app: task 0N <name>`), each preceded by a passing build and a local run.
- The app running on `vm-dev01` against the source database, with uploads landing in Blob, a notification toast appearing within 5 seconds of an edit, and telemetry reaching Application Insights.
- `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` reporting nothing, or a documented remediation.
- The image tag in your registry (`az acr repository show-tags`).
- The App Service identity, app settings and Key Vault access checked and recorded — not changed to point at your image.

## Hints

<details>
<summary>The app falls back to LocalDB after task 01</summary>

Task 01 changes the project's `UserSecretsId`. Re-set your user secrets (connection string, Blob, Service Bus) after task 01 — see the playbook's **Local configuration** section.
</details>

<details>
<summary>Blob or Service Bus calls return 403</summary>

`AZURE_TOKEN_CREDENTIALS=AzureCliCredential` isn't set in this terminal. Set it once at the user level and restart every terminal and VS Code.
</details>

<details>
<summary>Production refuses to start</summary>

That's correct outside `Development` without `KeyVault:VaultUri` — it's by design, not a bug. Use `dotnet run` (not `--no-launch-profile`) for local Development validation.
</details>

## Lifeline

Ask your coach if a task's own validation won't pass after two attempts. Your coach can unblock you at the point you're stuck. Using a lifeline caps C6 at partial credit for the tasks it skips.

## Bonus

Up to 5 pts for running the task 07 CVE audit a second time after any dependency bump elsewhere in the run, to prove the audit still passes clean.

## Learn more

- [.NET SDK container publishing](https://learn.microsoft.com/dotnet/core/containers/overview)
- [Azure Monitor OpenTelemetry Distro for ASP.NET Core](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable)
- [DefaultAzureCredential overview](https://learn.microsoft.com/dotnet/api/overview/azure/identity-readme)
