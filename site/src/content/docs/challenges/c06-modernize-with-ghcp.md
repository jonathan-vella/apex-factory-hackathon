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

## Where to run

Everything runs on `vm-dev01`, not in the dev container, in VS Code and PowerShell on the VM, in your clone of the kit at `C:\src\factory`, on your `vm-dev01-work` branch. Connect through Bastion and set up the branch first: see [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01). The only exceptions are the portal checks in task 5, which you can do in any browser.

## Your tasks

1. Switch to `vm-dev01` as described in [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01) (you did most of this in C3), then follow the [GHCP upgrade guide](../../guides/ghcp-upgrade/) and the modernization playbook at `.github/modernization/playbook.md` in your clone: harness **Local**, agent **Upgrade**, one task per new chat, build and run the app after every task, then commit and `git push` to your work branch before the next. Read the [branch rules](../../guides/ghcp-upgrade/#save-your-work-and-keep-the-branches-straight) once.
2. Run all seven tasks in order: .NET 10 and ASP.NET Core MVC; SQL Managed Instance; Blob; Service Bus; Key Vault; OpenTelemetry; CVE audit. Each task's check is in the playbook's task table — don't skip a check to save time.
3. Close the gaps the tasks don't fully cover, using the three skills in `.github/skills/` if a check fails.
4. Package the app with .NET SDK container publishing (no Dockerfile) and push it to your archetype's private registry.
5. Check — don't set — the web app's App Service configuration: its identity, its app settings, and that your image landed in the registry. **Don't point the web app at your image yet**: the modernized app reads its database at startup, and the database isn't migrated until C7. Pointing it now just makes the app exit repeatedly, which teaches nothing.

## Evidence

- Seven task commits (`app: task 0N <name>`), each preceded by a passing build and a local run, pushed to `vm-dev01-work` in your own repo. Copy your screenshots and notes to the team repo as in [Copy your evidence to the team repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-the-team-repo), in `evidence/c06/member-<n>/`.
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

## Bonus

Up to 5 pts for running the task 07 CVE audit a second time after any dependency bump elsewhere in the run, to prove the audit still passes clean.

## Learn more

- [.NET SDK container publishing](https://learn.microsoft.com/dotnet/core/containers/overview)
- [Azure Monitor OpenTelemetry Distro for ASP.NET Core](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable)
- [DefaultAzureCredential overview](https://learn.microsoft.com/dotnet/api/overview/azure/identity-readme)
