# C6 answer key: Modernize with GHCP

> [!WARNING]
> Coach material. This page has the answers to C6. Attendees run all seven of the Upgrade agent's tasks themselves, following the modernization playbook.

This is the longest member challenge (180 minutes) and the one most likely to run over. Watch for members skipping the "build and run after every task" discipline to save time — it almost always costs more time later when two tasks' problems compound.

## Expected evidence

- Seven commits, one per task, each named `app: task 0N <name>`, each preceded by a passing build and a local run against the source database on `vm-app01`.
- The app running on `vm-dev01`: uploads landing in the archetype's Blob container, a notification toast within 5 seconds of a student edit, telemetry visible in Application Insights.
- `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` clean, or a documented remediation for anything it flags.
- The image pushed to the archetype's ACR (`az acr repository show-tags`), with App Service's identity, app settings and Key Vault access checked but **not changed** to point at the new image.

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

## Common mistakes

- Pointing the web app at the new image at the end of C6 "because it's ready" — this is explicitly wrong for this challenge: the database isn't migrated yet, so the app exits at every startup. That's C7's job, after the Key Vault secret and the contained database user exist.
- Skipping the build-and-run step between tasks to save time, then debugging two tasks' worth of breakage at once in task 4 or 5.
- Forgetting to re-set user secrets after task 1 changes `UserSecretsId` — the app silently falls back to LocalDB and every downstream task looks broken.
- Leaving `AZURE_TOKEN_CREDENTIALS` unset on `vm-dev01`, causing 403s on Blob/Service Bus that look like app bugs but are a credential configuration gap.
- Running the CVE audit once at the start and not re-running it after later tasks touch dependencies.

## Partial credit

- All seven tasks complete, but one or two checks not fully passing (for example, OpenTelemetry events visible but incomplete attribute coverage): partial credit, with the specific gap noted.
- CVE audit shows an unremediated vulnerability in a transitive package with no available fix: accept as documented, not a blocker.
- Image not pushed to the registry by the time C6 ends: partial credit, complete it as the first five minutes of C7.

## Bonus

Re-running the task 07 CVE audit after any later dependency bump, to prove it's still clean, is worth up to 5 bonus points.

## Reset

Not applicable at the infrastructure level — if the app's local git history needs a clean restart, re-run the Upgrade agent's assessment and replan from `app/ContosoUniversity`'s pre-modernization state (coach-assisted; this is a significant redo, so confirm it's really needed before suggesting it).
