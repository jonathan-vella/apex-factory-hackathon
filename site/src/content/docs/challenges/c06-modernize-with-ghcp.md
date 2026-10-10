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

Everything runs on `vm-dev01`, not in the dev container, in VS Code and PowerShell on the VM, in your clone of the kit at `C:\src\factory`, on your `vm-dev01-work` branch. Connect through Bastion and set up the branch first: see [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01). The configuration checks in task 5 that only read Azure Resource Manager (the identity, app settings and role assignments) also work in any browser or with `az` on any computer. The image check needs `vm-dev01`, because the registry has no public access.

Never stop or deallocate `vm-dev01`: it's your workstation for the whole event.

Start with Step 0 of the playbook (`.github/modernization/playbook.md`) if you haven't finished it in C3: the sign-ins, git identity and `AZURE_TOKEN_CREDENTIALS` take time, and they count against the 180 minutes. The time box is split across two days.

## Your tasks

1. Switch to `vm-dev01` as described in [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01) (you did most of this in C3), then follow the [GHCP upgrade guide](../../guides/ghcp-upgrade/) and the modernization playbook at `.github/modernization/playbook.md` in your clone: harness **Local**, agent **Upgrade**, one task per new chat, build and run the app after every task, then commit and `git push` to your work branch before the next. Read the [branch rules](../../guides/ghcp-upgrade/#save-your-work-and-keep-the-branches-straight) once.
2. Run all seven tasks in order: .NET 10 and ASP.NET Core MVC; SQL Managed Instance; Blob; Service Bus; Key Vault; OpenTelemetry; CVE audit. Each task's check is in the playbook's task table — don't skip a check to save time.
3. Close the gaps the tasks don't fully cover, using the three skills in `.github/skills/` if a check fails.
4. Package the app with .NET SDK container publishing (no Dockerfile) and push it to your archetype's private registry.
5. Check — don't set — the web app's App Service configuration: its identity, its app settings, its Key Vault access, and that your image landed in the registry. The playbook's step 5 and the `app-service-configuration` skill have the commands. For the Key Vault access, list the identity's role assignments and look for **Key Vault Secrets User** on `kv-university-<suffix>`:

   ```powershell
   az webapp config appsettings list -g rg-university-<suffix> -n app-university-<suffix> --query "[].name" -o tsv
   $id = az identity show -g rg-university-<suffix> -n id-university-<suffix> --query principalId -o tsv
   az role assignment list --assignee $id --all --query "[].{role:roleDefinitionName, scope:scope}" -o table
   ```

   **Don't point the web app at your image yet**: the modernized app reads its database at startup, and the database isn't migrated until C7. Pointing it now only makes the app exit on every start.

## Evidence

- Seven task commits (`app: task 0N <name>`), each preceded by a passing build and a local run, pushed to `vm-dev01-work` in your own repo. Copy your screenshots and notes to the team repo as in [Copy your evidence to the team repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-the-team-repo), in `evidence/c06/member-<n>/`.
- The app running on `vm-dev01` against the source database, with uploads landing in Blob, a notification toast appearing within 5 seconds of an edit, and telemetry reaching Application Insights.
- `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` reporting nothing, or a documented remediation.
- The image tag in your registry (`az acr repository show-tags`).
- The App Service identity, app settings and Key Vault access checked and recorded (the output of the three commands in task 5) — not changed to point at your image.

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

Up to 5 pts for running the task 07 CVE audit again after the gap fixes and packaging (tasks 3 and 4), and recording that it's still clean, or what it found and how you fixed it.

## Learn more

- [.NET SDK container publishing](https://learn.microsoft.com/dotnet/core/containers/overview)
- [Azure Monitor OpenTelemetry Distro for ASP.NET Core](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable)
- [DefaultAzureCredential overview](https://learn.microsoft.com/dotnet/api/overview/azure/identity-readme)
