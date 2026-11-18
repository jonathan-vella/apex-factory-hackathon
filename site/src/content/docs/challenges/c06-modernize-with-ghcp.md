---
title: "C6: Modernize with GitHub Copilot"
description: Run the Upgrade agent's seven tasks to .NET 10, with the app running on the dev VM.
---

## Background

This is the core modernization. GitHub Copilot's Upgrade agent does the work in seven tasks, and you stay in charge: a build, a local run and a commit after every task. By the end Contoso University is on .NET 10 and packaged for the App Service you deployed in C5.

**Business context.** Dana, the CIO, needs the app on a platform with a future. C6 moves Contoso University to .NET 10 and ASP.NET Core and packages it for App Service.

**Business outcome.** Current platform. The app builds and runs on .NET 10, and its secrets come from Key Vault and managed identity, not from a configuration file.

**Objective.** Be able to drive the Upgrade agent task by task, check its output, and package the result as a container image.

**Time and scope.** Day 1, **14:45**, resuming Day 2 at **09:00**, **180 min**, **Member**. The time box is split across both days.

## Challenge

**Validated baseline:** GitHub Copilot upgrade extension **1.1.612** on VS Code **1.139.0**, recorded in `versions.md`. Documentation reviewed **2026-10-30**, not a new runtime test. If no dashboard opens, ask Copilot to show `plan.md` and `tasks.md`. The owner retests current versions before the dry run.

**Starting point.** C3's reviewed assessment and approved plan (`plan.md`, committed on `main` in `C:\src\<your-repo>`; no task has started). C5's deployed archetype (for the registry and the App Service identity you'll check against, not deploy to).

**Fixed by the kit.** The target: .NET 10 and ASP.NET Core MVC, with uploads on Blob, notifications on Service Bus, secrets in Key Vault and telemetry in Application Insights. The app runs on `vm-dev01` against the source database, and is packaged for App Service. The seven agent tasks and their checks are in the playbook.

The kit keeps the **Azure Monitor OpenTelemetry Distro**, which its runtime validation used. [Current Learn guidance](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable) recommends the **Microsoft OpenTelemetry Distro** for new apps; adopting it here needs a separate runtime revalidation, not a package change during this exercise.

**You decide.** Nothing about the target. You decide whether each agent task's output passes its check before you commit it.

:::note[Where to work]

Everything runs on <span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt; (VS Code &amp; pwsh)</span> on `main` ([Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01)):

- Run all seven Upgrade agent tasks, gap checks, and container publish (`dotnet publish /t:PublishContainer`) directly in `C:\src\<your-repo>` on `main`. The private registry has no public access, so the image push requires `vm-dev01`.
- Your Git commits on `main` and the image tag in ACR are the deliverables—no manual `task-checks.md` commit-hash or screenshot transcription file is needed.
- Never stop or shut down `vm-dev01`: it's your workstation for the whole event.

:::

Paste-ready prompts are in the [prompt library](../../prompts/): [Run a task](../../prompts/vscode/02-run-a-task/), [CVE scan](../../prompts/vscode/03-cve-scan/), [Troubleshoot](../../prompts/vscode/04-troubleshoot/) and [App Service check](../../prompts/vscode/05-app-service-check/). The playbook stays the source for the checks.

**Three kinds of numbers appear here.** **Requirements 1 to 5** are this page's. **Agent task 01 to 07** are the Upgrade agent's seven tasks (`feat(app): task 0N <name>` commits on `main`). **Playbook Step 0 to 5** are the sections of `.github/modernization/playbook.md`.

### The source database login

Locally, the app uses the `contosoapp` SQL login against the source database on `vm-app01`. It's the lab-only login the datacenter creates, with a documented lab password (the playbook's user-secrets command already has it). It's reachable only from inside the private network, and the app accepts it only in `Development`: outside `Development` the app refuses a user name or password. User secrets are per-user settings that `dotnet user-secrets` stores outside the repo, so nothing is committed.

The only Azure resource change in C6 is the image push (requirement 4). Your sign-in already has Monitoring Metrics Publisher from the archetype; if that assignment is missing, grant it once using playbook Step 2, agent task 06.

## Requirements

1. **Open `C:\src\<your-repo>` on `vm-dev01`** <span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt; (VS Code)</span> and follow the [GitHub Copilot upgrade guide](../../guides/ghcp-upgrade/) and the modernization playbook at `.github/modernization/playbook.md`. In VS Code, open Copilot Chat and set **Session Target** to **Local** (not Copilot) and the agent to **Upgrade**. Use one chat per agent task, build and run the app after every agent task, then commit and `git push` on `main` before the next. Done when the playbook's Step 0 **Check** line passes and either the picker lists **Upgrade** or `@upgrade` responds.

2. **Run all seven agent tasks in order:** <span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt; (VS Code &amp; pwsh)</span> 01 .NET 10 and ASP.NET Core MVC; 02 SQL Managed Instance; 03 Blob; 04 Service Bus; 05 Key Vault; 06 OpenTelemetry; 07 CVE audit. Each agent task's check is in the playbook's Step 2 task checks table: don't skip a check to save time. Done when you have seven commits (`feat(app): task 0N <name>`) pushed on `main`, each after a passing build and a local run.

3. **Close the gaps the agent tasks don't fully cover,** <span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt; (VS Code &amp; pwsh)</span> with playbook Step 3. If one of its two searches finds something, use the matching skill in `.github/skills/` (`aspnet-startup-migration`, `notification-service-di` or `trace-to-opentelemetry`) by asking in a new chat: `Use the <skill> skill. Scope: app/ContosoUniversity only.` Done when both `git grep` searches in playbook Step 3 print nothing; run the app again, then commit (`fix(app): gaps`) and push on `main`.

4. **Package the app** <span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt;\app\ContosoUniversity (pwsh)</span> with .NET SDK container publishing (no `Dockerfile`) and push it to your archetype's private registry, with playbook Step 4 (the `sdk-container-publish` skill explains it). Done when `az acr repository show-tags` lists `c6`.

5. **Check, don't set, the web app's App Service configuration:** <span class="sl-badge note">vm-dev01 · PowerShell 7</span> its identity, its app settings, its Key Vault access, and that your image landed in the registry. Playbook Step 5 and the `app-service-configuration` skill have the commands. This vault uses Azure RBAC, not access policies, so ignore the vault's **Access policies** blade: the web app's access is a role assignment. Set up the names once, then run the checks:

   ```powershell title="vm-dev01 — PowerShell 7"
   $rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
   $suffix = $rg -replace '^rg-university-', ''
   az webapp config appsettings list -g $rg -n "app-university-$suffix" --query "[].name" -o tsv
   $id = az identity show -g $rg -n "id-university-$suffix" --query principalId -o tsv
   az role assignment list --assignee $id --all --query "[].{role:roleDefinitionName, scope:scope}" -o table
   ```

   Done when the app settings list has every key the app reads (playbook Step 5), the role list has **Key Vault Secrets User** on a scope that ends with `kv-university-<suffix>`, and `show-tags` from requirement 4 lists your image.

   :::caution[Don't point the web app at your image yet]
   The modernized app reads its database at startup, and the database isn't migrated until C7. Pointing App Service at your image now only makes the app exit on every start.
   :::

## Success criteria

To complete this challenge, review with your coach on `vm-dev01`:

- [ ] Seven agent task commits (`feat(app): task 0N <name>`), each preceded by a passing build and a local run, pushed on `main` in `C:\src\<your-repo>`.
- [ ] The app running on `vm-dev01` against the source database, with uploads landing in Blob, a notification toast appearing within 5 seconds of an edit, and telemetry reaching Application Insights.
- [ ] `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` reporting nothing, or a documented remediation.
- [ ] The image tag in your registry (`az acr repository show-tags`).
- [ ] The App Service identity, app settings and Key Vault access checked (not changed to point at your image yet).
- [ ] Outcome check: search the committed app and its configuration files for a database password or key, and confirm none is left.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

<details>
<summary>The app falls back to LocalDB after agent task 01</summary>

LocalDB is a small local test database, not your source. Agent task 01 changes the project's `UserSecretsId`, so re-set your user secrets (connection string, Blob, Service Bus) afterward. See the **Local configuration** section in playbook Step 2.

</details>

<details>
<summary>Blob or Service Bus calls return 403</summary>

`AZURE_TOKEN_CREDENTIALS=AzureCliCredential` isn't set in this terminal. Set it once at the user level and restart every terminal and VS Code.

</details>

<details>
<summary>Production refuses to start</summary>

That's correct outside `Development` without `KeyVault:VaultUri`: it's by design, not a bug. Use `dotnet run` (not `--no-launch-profile`) for local Development validation.

</details>

<details>
<summary>If you need to start over</summary>

To restart the seven agent tasks from a clean .NET Framework 4.8 tree without losing your C1–C5 commits on `main`, find your C3 baseline commit (`git log --oneline -- .github/upgrades`) and restore only `app` and `.github/upgrades`:

```powershell
cd C:\src\<your-repo>
git restore --source=<c3-commit-sha> --worktree --staged -- app .github/upgrades
git clean -fdx -- app .github/upgrades
```

Never run `git reset --hard` or `git push --force` on `main`.

</details>

## References

- [.NET SDK container publishing](https://learn.microsoft.com/dotnet/core/containers/overview)
- [Enable OpenTelemetry in Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable)
- [DefaultAzureCredential overview](https://learn.microsoft.com/dotnet/api/overview/azure/identity-readme)
