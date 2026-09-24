# B03: Import Contoso University and publish the legacy package

| Field | Value |
|---|---|
| Milestone | P1 Skeleton and datacenter |
| Type | Both |
| Depends on | B01 |
| Unblocks | B04 |
| Effort | 1–2 hours |
| Cost | None. Actions minutes are free for public repos |
| Teardown | Not applicable |
| PRD | §2 App scope, §6, §7 |

## Outcome

- `app/ContosoUniversity/` holds the upstream Contoso University sample from a pinned commit, unchanged.
- A workflow builds the app on Windows whenever `app/` changes. On `main`, it publishes the deployable package `ContosoUniversity-legacy.zip` to the `legacy-v1` release. The datacenter kit (B04) deploys that package to `vm-app01`.
- Dependabot ignores the app's NuGet packages, so the app stays outdated on purpose.
- `app/README.md`, `NOTICE` and `versions.md` record the source.

## Before you start

1. `npm run check` passes on an up-to-date `main`.
2. `gh api repos/Azure-Samples/dotnet-migration-copilot-samples/commits/7c1bf47b7e2627fe5a1c764716638815d35e0282 --jq .sha` prints that SHA.
3. `gh release view legacy-v1` fails with `release not found`. If the release exists, stop and ask.

## Requirements

### Import

1. Copy the `ContosoUniversity` folder of `Azure-Samples/dotnet-migration-copilot-samples` at commit `7c1bf47b7e2627fe5a1c764716638815d35e0282` to `app/ContosoUniversity/`. The source has exactly 90 files, including `ContosoUniversity.sln` and `.gitignore`. Download the commit archive rather than cloning the repo.
2. Don't change any file under `app/ContosoUniversity/`. See **Notes and traps**.

### App README

3. `app/README.md` describes the legacy starting state:
   - What it is: an ASP.NET MVC 5 app on .NET Framework 4.8, with EF Core 3.1, SQL Server, MSMQ and local file uploads.
   - A source table: repo and folder (linked at the commit), the full commit SHA, "Changes: none", and the licence (MIT, `app/LICENSE`, noting that upstream has no LICENSE file at that commit).
   - A legacy dependencies table, with where each one lives and its modernization target:

     | Dependency | Where | Target |
     |---|---|---|
     | SQL Server (LocalDB in the sample, SQL Server 2022 in the datacenter) | `Web.config`, `DefaultConnection` | Azure SQL Managed Instance with managed identity |
     | Local file uploads | `Uploads/TeachingMaterials/`, `CoursesController` | Azure Blob Storage |
     | MSMQ private queue | `Web.config`, `NotificationQueuePath`; `Services/NotificationService.cs` | Azure Service Bus |
     | .NET Framework 4.8, `Global.asax`, bundling | The whole project | .NET 10 and ASP.NET Core |

   - A package section: the workflow, the `legacy-v1` release, that B04 deploys it to `vm-app01`, and that the workflow adds the missing Bootstrap CSS to the package only.

### Build workflow

4. `.github/workflows/build-legacy.yml`, named **Build legacy app**:
   - Triggers: PRs and pushes to `main` that touch `app/**` or the workflow itself, plus manual dispatch.
   - Runs only when `github.repository == 'jonathan-vella/apex-factory-hackathon'`, so template copies don't build or release.
   - One job on `windows-latest`, 20-minute timeout, `pwsh`, working directory `app/ContosoUniversity`, `contents: write`, a concurrency group per ref that doesn't cancel runs in progress, Node 24 for JavaScript actions.
   - Steps: checkout, set up MSBuild and NuGet (current major versions of `microsoft/setup-msbuild` and `NuGet/setup-nuget`), `nuget restore`, then `msbuild` the solution in Release.
5. Package: stage the web app without source (no `obj`, `packages`, `Properties`, `.vs`, `*.cs`, `*.csproj`, `*.user`, `*.sln`, `packages.config`, `*.md`, `.gitignore`), copy `bootstrap.css` and `bootstrap.min.css` from the restored `bootstrap` 5.3.3 NuGet package (`packages/bootstrap.5.3.3/content/Content`) into the package's `Content` folder, and zip it as `ContosoUniversity-legacy.zip`.
6. Check the package before publishing it. It must contain `Web.config`, `Global.asax`, `Views/Web.config`, `Views/Home/Index.cshtml`, `bin/ContosoUniversity.dll`, `Content/bootstrap.css` and `Content/Site.css`, and no `.cs`, `.csproj` or `.sln` file. On success, print `Package OK: <n> entries.`; otherwise fail and list what's missing or not allowed.
7. Upload the zip as the workflow artifact `ContosoUniversity-legacy` on every run.
8. On pushes to `main`, and on manual runs from `main` only (`github.ref == 'refs/heads/main'`), publish to the `legacy-v1` release. Create it the first time (title "Legacy Contoso University package", targeting the built commit). After that, replace the asset. The notes always say which commit the package was built from and that B04 deploys it to `vm-app01`. PRs and manual runs from other branches only upload the artifact.

### Dependabot

9. `.github/dependabot.yml` gets a last entry for NuGet in `/app/ContosoUniversity`, weekly, ignoring every dependency, with a comment that the legacy app stays outdated on purpose. Without it, Dependabot security updates would open PRs against the app, and `dependabot-auto-merge.yml` would merge them.

### Records

10. `NOTICE` lists `app/ContosoUniversity`, copied unchanged from the `ContosoUniversity` folder of `Azure-Samples/dotnet-migration-copilot-samples` at the full commit SHA (MIT, see `app/LICENSE`). `app/LICENSE` holds the standard MIT License text with `Copyright (c) Microsoft Corporation.`
11. `versions.md` gets two rows, validated today: Contoso University (upstream sample) at `7c1bf47`, used in `app/ContosoUniversity` (B03); and .NET Framework `4.8`, used by the legacy app and its build (B03).

### PR

12. `npm run check` passes. It doesn't lint `app/`: B01 excluded it.
13. The PR changes exactly 96 files: the 90 app files, `app/README.md`, `app/LICENSE`, `build-legacy.yml`, `dependabot.yml`, `NOTICE` and `versions.md`.
14. The **Build legacy app** check passes on the PR. Copy its `Package OK:` line into the PR body. If the build fails, stop and report the error: don't change the app to make it build.
15. The PR body carries this after-merge checklist for the owner: the "Build legacy app" run on `main` succeeded; `gh release view legacy-v1 --json assets -q '.assets[].name'` prints `ContosoUniversity-legacy.zip`.

## Deliverables

- `app/ContosoUniversity/` (90 files, unchanged from upstream), `app/README.md` and `app/LICENSE`.
- `.github/workflows/build-legacy.yml`.
- Changes to `.github/dependabot.yml`, `NOTICE` and `versions.md`.

## Verify

```powershell
(git ls-files app/ContosoUniversity | Measure-Object).Count
npm run check
gh pr checks --watch
```

- The count is `90`, and `app/LICENSE` exists. With it and the other deliverables, the PR changes 96 files.
- `npm run check` passes.
- **Build legacy app** passes on the PR and prints `Package OK:`.

## Done when

- [ ] `app/ContosoUniversity/` matches upstream exactly, and `app/README.md` and `app/LICENSE` exist.
- [ ] The workflow builds, checks, uploads and (outside PRs) publishes the package as described.
- [ ] Dependabot ignores the app's NuGet packages.
- [ ] `NOTICE` and `versions.md` have the new entries.
- [ ] The PR build passes, and the PR body has the `Package OK:` line and the after-merge checklist.

## Commit message

```text
feat: import Contoso University and build the legacy package
```

## Stop and ask if

- The download doesn't contain exactly 90 files.
- The CI build fails, or the package check reports missing or disallowed files.
- `legacy-v1` already exists.

## Notes and traps

- **Don't change the app.** The legacy state is the starting point for every challenge: LocalDB in `Web.config`, `debug="true"`, the MSMQ queue, local uploads and `Trace` logging. The GitHub Copilot assessment must find what it would find at a customer. The datacenter kit sets the real connection string on the VM at deploy time.
- **Bootstrap CSS:** `BundleConfig.cs` and the project reference `Content/bootstrap.css`, which upstream doesn't include. Only the package gets a copy.
- **File name case:** `BundleConfig.cs` asks for `~/Content/site.css` and the file is `Site.css`. IIS doesn't mind. A Linux container does, which makes it a real finding for the modernization. Don't fix it here.
- **robocopy**, if you use it: exit codes 0–7 mean success. GitHub Actions fails a `pwsh` step if the last native command exits non-zero, so reset the exit code after it.
- **Release updates:** later changes to `app/` on `main` replace the zip in the same `legacy-v1` release. The tag stays on the first commit, and the notes name the latest one.
- **Dependabot:** `ignore` applies to both version and security updates. Dependabot alerts still list the app's vulnerable packages. That's expected: the assessment should find them too.
- **Views compile at run time** with the C# 5 compiler in .NET Framework, because `Web.config` has no `system.codedom` section. The upstream views use only C# 5 syntax, which is one more reason not to touch them.
- **Licence:** upstream has no LICENSE file at `7c1bf47`, so `app/LICENSE` records MIT (Copyright Microsoft Corporation), as the owner approved. It sits in `app/`, outside the unchanged upstream folder.
- **Database:** the app calls `EnsureCreated()` and seeds a small data set (9 students, 8 courses, 12 enrollments) at `Application_Start`. B04 relies on this to create the schema; B05 adds volume.
- **MSMQ:** `BaseController` creates a `NotificationService` whose constructor calls `MessageQueue.Exists`/`Create` without a try/catch, so the app won't start without MSMQ. B04 installs it and pre-creates the queue.
