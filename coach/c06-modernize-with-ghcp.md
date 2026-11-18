# C6 answer key: Modernize with GitHub Copilot (coach)

> [!WARNING]
> Coach material. This page has the answers to C6. Attendees run all seven of the Upgrade agent's tasks themselves, following the modernization playbook.

This is the longest member challenge (180 minutes) and the one most likely to run over. Watch for members skipping the "build and run after every task" discipline to save time — it almost always costs more time later when two tasks' problems compound.

## Expected evidence

**Timing cues:** by the Day 1 break, expect the framework migration and database task to build and run. At the Day 2 midpoint, identify any remaining service gaps; reserve the last 30 minutes for packaging and checks. Offer an appropriate lifeline only after the member has tried the documented fixes.

- Seven `feat(app): task 0N <name>` commits on `main` in `C:\src\<your-repo>` (no manual `task-checks.md` file is required).
- The app running on `vm-dev01`: uploads landing in the archetype's Blob container, a notification toast within 5 seconds of a student edit, telemetry visible in Application Insights.
- `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` clean, or a documented remediation for anything it flags.
- The image pushed to the archetype's ACR (`az acr repository show-tags`), with App Service's identity, app settings and Key Vault access (the identity's **Key Vault Secrets User** role assignment) checked but **not changed** to point at the new image.

## Model answer

The seven tasks, in order, and what each should produce:

1. **.NET 10 / ASP.NET Core MVC** — `Global.asax`, `RouteConfig`, `FilterConfig`, `BundleConfig` become `Program.cs` and static files in `wwwroot` (see the `aspnet-startup-migration` skill if anything is left over).
2. **SQL Managed Instance** — connection string and EF Core provider updated for SQL MI; Microsoft Entra authentication, no SQL auth outside Development.
3. **Blob** — uploads move from local disk/UNC to `teaching-materials`, addressed through `Storage:BlobServiceUri` and `Storage:ContainerName`, no SAS tokens.
4. **Service Bus** — notifications move off MSMQ to the `notifications` queue; the `notification-service-di` skill's constructor-injected, single-lifetime Service Bus client pattern applies here.
5. **Key Vault** — secrets come from `KeyVault:VaultUri`, never hard-coded.
6. **OpenTelemetry** — `Trace`/`Debug` calls become `ILogger`, exported through the Azure Monitor distro with Entra auth (the `trace-to-opentelemetry` skill covers this).
7. **CVE audit** — `dotnet list package --vulnerable` clean, or remediated.

After all seven: package with `dotnet publish /t:PublishContainer` (no Dockerfile — see the `sdk-container-publish` skill), push to the archetype's ACR, then check (don't set) App Service's identity/app settings/Key Vault access using the `app-service-configuration` skill as a reference, stopping short of pointing the web app at the image.

## Business outcome check

The outcome is a current platform. Ask the member to show their search of the committed app and its configuration files for a database password or key, and the result. User secrets on the VM and Key Vault are expected; a password in a committed file is not.

## Common mistakes

- Pointing the web app at the new image at the end of C6 "because it's ready" — this is explicitly wrong for this challenge: the database isn't migrated yet, so the app exits at every startup. That's C7's job, after the Key Vault secret and the contained database user exist.
- Skipping the build-and-run step between tasks to save time, then debugging two tasks' worth of breakage at once in task 4 or 5.
- Forgetting to re-set user secrets after task 1 changes `UserSecretsId` — the app silently falls back to LocalDB and every downstream task looks broken.
- Leaving `AZURE_TOKEN_CREDENTIALS` unset on `vm-dev01`, causing 403s on Blob/Service Bus that look like app bugs but are a credential configuration gap.
- Running the CVE audit once at the start and not re-running it after later tasks touch dependencies.

## Lifelines

Offer a lifeline only after the member has tried the playbook's fixes and the time box is at risk. Use the earliest checkpoint that unblocks them: L1 for task 01, L2 for tasks 02–03, L3 for task 04, or L4 for tasks 05–07. Follow the [Lifelines handout](lifelines.md) with the member; preserve their work first and ask the team to note the lifeline in C10's AI-readiness gap register.

## Reset

Not applicable at the infrastructure level. If the app in `C:\src\<your-repo>` needs a clean restart from the C3 baseline commit (`<c3-commit-sha>`), restore only `app` and `.github/upgrades` so C1–C5 commits on `main` are preserved:

```powershell
cd C:\src\<your-repo>
git restore --source=<c3-commit-sha> --worktree --staged -- app .github/upgrades
git clean -fdx -- app .github/upgrades
```

Never run `git reset --hard` or `git push --force` on `main`.
