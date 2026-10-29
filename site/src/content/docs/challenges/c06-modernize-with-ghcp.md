---
title: "C6: Modernize with GHCP"
description: Run the Upgrade agent's seven tasks to .NET 10, with the app running on the dev VM.
---

## Background

This is the core modernization. GitHub Copilot's Upgrade agent does the work in seven tasks, and you stay in charge: a build, a local run and a commit after every task. By the end Contoso University is on .NET 10 and packaged for the App Service you deployed in C5.

**Business context.** Dana, the CIO, needs the app on a platform with a future. C6 moves Contoso University to .NET 10 and ASP.NET Core and packages it for App Service.

**Business outcome.** Current platform. The app builds and runs on .NET 10, and its secrets come from Key Vault and managed identity, not from a configuration file.

**Objective.** Be able to drive the Upgrade agent task by task, check its output, and package the result as a container image.

**Time and points.** Member, **180 min**, **30 pts** (member). The time box is split across two days.

## Challenge

**Starting point.** C3's reviewed assessment and approved plan (`plan.md`, committed as `app: assess and plan`; no task has started). C5's deployed archetype (for the registry and the App Service identity you'll check against, not deploy to).

**Fixed by the kit.** The target: .NET 10 and ASP.NET Core MVC, with uploads on Blob, notifications on Service Bus, secrets in Key Vault and telemetry in Application Insights. The app runs on `vm-dev01` against the source database, and is packaged for App Service. The seven agent tasks and their checks are in the playbook.

**You decide.** Nothing about the target. You decide whether each agent task's output passes its check before you commit it.

**Where to work.** Everything runs on `vm-dev01`, not in the dev container, in VS Code and PowerShell on the VM, in your clone of the kit at `C:\src\factory`, on your `vm-dev01-work` branch. You set the VM up in [Step 3: Datacenter and workstation](../../deploy/member-steps/#33-set-up-vm-dev01) and used it in C3, so you only reconnect: see [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01) if you need to connect again. The configuration checks in requirement 5 that only read Azure Resource Manager (the identity, app settings and role assignments) also work in any browser or with `az` on any computer. The image check needs `vm-dev01`, because the registry has no public access.

Never stop or shut down `vm-dev01`: it's your workstation for the whole event.

Paste-ready prompts are in the [prompt library](../../prompts/): [Run a task](../../prompts/vscode/02-run-a-task/), [CVE scan](../../prompts/vscode/03-cve-scan/), [Troubleshoot](../../prompts/vscode/04-troubleshoot/) and [App Service check](../../prompts/vscode/05-app-service-check/). The playbook stays the source for the checks.

**Three kinds of numbers appear here.** **Requirements 1 to 5** are this page's. **Agent task 01 to 07** are the Upgrade agent's seven tasks, which the playbook's `app: task 0N` commits use. **Playbook Step 0 to 5** are the sections of `.github/modernization/playbook.md`. Step 0 is the set-up you did in the readiness check: if its **Check** line fails, finish it first, because it counts against the 180 minutes.

### The source database login

Locally, the app uses the `contosoapp` SQL login against the source database on `vm-app01`. It's the lab-only login the datacenter creates, with a documented lab password (the playbook's user-secrets command already has it). It's reachable only from inside the private network, and the app accepts it only in `Development`: outside `Development` the app refuses a user name or password. User secrets are per-user settings that `dotnet user-secrets` stores outside the repo, so nothing is committed.

C6 changes Azure only by pushing the image (requirement 4): the archetype gives your sign-in Monitoring Metrics Publisher on Application Insights when you deploy it. If the role is missing on your deployment, grant it once yourself (the playbook's Step 2 check for agent task 06 has the command).

## Requirements

1. **Switch to `vm-dev01`** as described in [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01) (it's already set up, see [set up `vm-dev01`](../../deploy/member-steps/#33-set-up-vm-dev01)), then follow the [GHCP upgrade guide](../../guides/ghcp-upgrade/) and the modernization playbook at `.github/modernization/playbook.md` in your clone. In VS Code, open Copilot Chat and set **Session Target** to **Local** (not Copilot) and the agent to **Upgrade**. Use one chat per agent task, build and run the app after every agent task, then commit and `git push` to your work branch before the next. Read the [branch rules](../../guides/ghcp-upgrade/#save-your-work-and-keep-the-branches-straight) once. Done when the playbook's Step 0 **Check** line passes and the agent picker lists **Upgrade**.

2. **Run all seven agent tasks in order:** 01 .NET 10 and ASP.NET Core MVC; 02 SQL Managed Instance; 03 Blob; 04 Service Bus; 05 Key Vault; 06 OpenTelemetry; 07 CVE audit. Each agent task's check is in the playbook's Step 2 task checks table: don't skip a check to save time. Done when you have seven commits `app: task 0N <name>` on `vm-dev01-work`, each after a passing build and a local run.

3. **Close the gaps the agent tasks don't fully cover,** with playbook Step 3. If one of its two searches finds something, use the matching skill in `.github/skills/` (`aspnet-startup-migration`, `notification-service-di` or `trace-to-opentelemetry`) by asking in a new chat: `Use the <skill> skill. Scope: app/ContosoUniversity only.` Done when both `git grep` searches in playbook Step 3 print nothing.

4. **Package the app** with .NET SDK container publishing (no `Dockerfile`) and push it to your archetype's private registry, with playbook Step 4 (the `sdk-container-publish` skill explains it). Done when `az acr repository show-tags` lists `c6`.

5. **Check, don't set, the web app's App Service configuration:** its identity, its app settings, its Key Vault access, and that your image landed in the registry. Playbook Step 5 and the `app-service-configuration` skill have the commands. This vault uses Azure RBAC, not access policies, so ignore the vault's **Access policies** blade: the web app's access is a role assignment. Set up the names once, then run the checks:

   ```powershell
   $rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
   $suffix = $rg -replace '^rg-university-', ''
   az webapp config appsettings list -g $rg -n "app-university-$suffix" --query "[].name" -o tsv
   $id = az identity show -g $rg -n "id-university-$suffix" --query principalId -o tsv
   az role assignment list --assignee $id --all --query "[].{role:roleDefinitionName, scope:scope}" -o table
   ```

   Done when the app settings list has every key the app reads (playbook Step 5), the role list has **Key Vault Secrets User** on a scope that ends with `kv-university-<suffix>`, and `show-tags` from requirement 4 lists your image.

   **Don't point the web app at your image yet.** The modernized app reads its database at startup, and the database isn't migrated until C7. Pointing it now only makes the app exit on every start.

## Success criteria

To complete this challenge, show your coach:

- [ ] Seven agent task commits (`app: task 0N <name>`), each preceded by a passing build and a local run, pushed to `vm-dev01-work` in your own repo.
- [ ] The app running on `vm-dev01` against the source database, with uploads landing in Blob, a notification toast (a small pop-up at the top right) appearing within 5 seconds of an edit, and telemetry reaching Application Insights.
- [ ] `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` reporting nothing, or a documented remediation.
- [ ] The image tag in your registry (`az acr repository show-tags`).
- [ ] The App Service identity, app settings and Key Vault access checked and recorded (the output of the `appsettings list` and `role assignment list` commands in requirement 5), not changed to point at your image.
- [ ] Outcome check (unscored guidance): search the committed app and its configuration files for a database password or key, and record that none is left.

Save your screenshots and notes as files in `factory/evidence/c06/` of your own repo, on `main`. On `vm-dev01`, that's `C:\src\<your-repo>\factory\evidence\c06\` (the plain clone of your own repo): run `git pull --rebase` first, as in [Copy your evidence to your repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-your-repo). In the dev container, run `git pull` first. Commit with a conventional message (for example `docs: C6 evidence`) and run `git push`.

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

To restart the seven agent tasks from a clean .NET Framework 4.8 tree, reset `vm-dev01-work` to the playbook's `app: assess and plan` commit. Find it with `git log --oneline` in `C:\src\factory`, then run `git reset --hard <commit-id>`. This discards uncommitted work, and your next push needs `git push --force-with-lease`. Check the tree is clean again with the last command in playbook Step 0. Ask your coach first if you've already pushed.

</details>

**Bonus.** Up to 5 pts for running the agent task 07 CVE audit again after the gap fixes and packaging (requirements 3 and 4), and recording that it's still clean, or what it found and how you fixed it.

## References

- [.NET SDK container publishing](https://learn.microsoft.com/dotnet/core/containers/overview)
- [Azure Monitor OpenTelemetry Distro for ASP.NET Core](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable)
- [DefaultAzureCredential overview](https://learn.microsoft.com/dotnet/api/overview/azure/identity-readme)
