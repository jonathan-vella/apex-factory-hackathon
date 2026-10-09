# B10: Build the modernization playbook, skills and lifelines

| Field | Value |
|---|---|
| Milestone | P3 Build |
| Type | Both |
| Depends on | B06, B09 |
| Unblocks | B11 |
| Effort | 3–4 days |
| Cost | About $4.68/hour while the validation stack is deployed: measured B10 actuals are ALZ-lite $1.30/hour, datacenter $1.55/hour and archetype $1.83/hour; the prior $3.95/hour estimate did not reconcile with those components |
| Teardown | Delete everything this item created, as in B09 |
| PRD | §5 C6, C7; §6 App modernization; §8 GHCP risk |

## Outcome

- `.github/` carries the modernization aids that load into attendees' GitHub Copilot sessions: repo instructions, a playbook that sequences the predefined tasks, and custom skills for the gaps the predefined tasks don't cover. They're built from the B06 golden path.
- Five lifeline branches give a known-good checkpoint after each major step of C6 and C7, and a known-good image is the last resort. They're for coaches and facilitators, not students (owner decision, 2026-10-08).
- The golden-path end state runs on App Service against SQL MI with managed identity, over private endpoints.

## Before you start

1. B06 and B09 are closed. Read the B06 report, both run sheets and the golden-path branch `spike/b06-upgrade-compare-v3` (`54b5b45`). There's no `spike/b06-run2`: B06 skipped run 2 (owner-approved correction, 2026-10-08).
2. The .NET 10 SDK is installed locally: `dotnet --list-sdks` shows a 10.x SDK.
3. `.local/settings.json` has `tenantId`, `subscriptionId`, `location`, `memberIndex` and `suffix`.

## Requirements

### Instructions, playbook and skills

1. `.github/copilot-instructions.md`: short repo instructions for Copilot in an attendee's copy: what the repo is, that `app/ContosoUniversity` is the legacy app being modernized to .NET 10 on App Service for Linux, the target services and how they authenticate (managed identity on App Service, the member's identity with `DefaultAzureCredential` on the dev VM, SQL authentication only to the source database), and a pointer to the playbook. Nothing about the kit's own tooling.
2. `.github/modernization/playbook.md`: the B06 golden path (the v3 rerun, see `docs/spikes/B06-ghcp-golden-path/README.md`), as a sequence an attendee follows: assess and plan (C3), the seven tasks in the B06 order, the gap skills, packaging, and the App Service configuration. For each step: the goal, the prompt to use, what to check before moving on and the known hot spots. No lifeline references: lifelines are coach-only (owner decision, 2026-10-08).
3. The playbook's model guidance, dated and not pinned: a balanced model (Sonnet- or Terra-class) for the assessment, the most capable (Opus- or Sol-class) for planning, and an efficient model at maximum reasoning effort (Luna-class) to explore for execution. It says models change and to check the playbook date.
4. Skills in `.github/skills/<name>/SKILL.md`, one per gap, each with when to use it, the steps, the checks and a short before/after example:

   | Skill | Covers |
   |---|---|
   | `aspnet-startup-migration` | `Global.asax`, `RouteConfig`, `FilterConfig` and bundling to `Program.cs` and static files |
   | `notification-service-di` | The `new NotificationService()` in `BaseController` to constructor injection, with the Service Bus client registered in DI |
   | `trace-to-opentelemetry` | `System.Diagnostics.Trace` to `ILogger` and OpenTelemetry, exporting to Application Insights on App Service |
   | `sdk-container-publish` | Building the image with .NET SDK container publishing (no Docker) and pushing it to the private ACR from the dev VM |
   | `app-service-configuration` | Reading the archetype's app settings (B09), managed identity with the identity's client ID, and the SQL connection for MI |

   Add or merge skills only if the B06 report shows a different set of gaps, and list the change in the PR body.
5. The Copilot CLI alternative gets a short section in the playbook: how to run the same sequence with Copilot CLI, and where it differs.

### Golden-path code and lifelines

6. Build the golden-path end state from `spike/b06-upgrade-compare-v3`, so that it meets every check in B06 requirement 12 and runs on App Service against SQL MI. This is the known-good solution. The kit never hand-fixes application code: the lifelines hold only what GitHub Copilot produced on the golden path, and L5 differs from L4 only in configuration and the app's README (owner decision, 2026-10-08).
7. Lifeline branches, each cut from the golden-path history at a checkpoint and each building on its own:

   | Branch | Checkpoint |
   |---|---|
   | `lifeline/L1-net10` | Upgraded to .NET 10 and ASP.NET Core; builds and runs on the dev VM against the source database |
   | `lifeline/L2-blob` | L1 plus the database task (managed identity ready, SQL authentication on the dev VM) and uploads on Blob |
   | `lifeline/L3-servicebus` | L2 plus MSMQ replaced by Service Bus, with the notification service in DI |
   | `lifeline/L4-ready` | L3 plus Key Vault and OpenTelemetry: C6 complete |
   | `lifeline/L5-cutover` | L4 plus App Service configuration for SQL MI with managed identity: the C7 end state |

8. The known-good image: build L5 with SDK container publishing and publish it publicly as `ghcr.io/jonathan-vella/contoso-university:known-good`, tagged with the commit too. A member imports it into their private registry with `az acr import`, which works because the archetype's registry allows trusted Azure services (B09). 🔎 VERIFY on [Import container images](https://learn.microsoft.com/azure/container-registry/container-registry-import-images).
9. A workflow builds each `lifeline/*` branch on push (build only, no deploy), and a manual workflow publishes the known-good image from `lifeline/L5-cutover`. Both run only in `jonathan-vella/apex-factory-hackathon`.
10. `coach/lifelines.md`: what each lifeline contains, when to hand it out, how the coach applies it, and what it costs in points (a pointer to the rubric, which B12 writes). Lifelines are for coaches and facilitators only: a coach decides when a stuck member gets one, and applies it or hands it over (owner decision, 2026-10-08). Template copies don't reliably include non-default branches, so the coach fetches a lifeline from the upstream public repo into the member's repo: `git fetch https://github.com/jonathan-vella/apex-factory-hackathon.git lifeline/L3-servicebus:lifeline/L3-servicebus`, then `git switch`. For the image, `az acr import`. Test the fetch from a repo created from the template.

### Validate for real

11. Deploy ALZ-lite (shared services subscription), then the datacenter, vending and the archetype (workload subscription) with the kit scripts. Onboard `vm-app01` to Arc with `scripts/Connect-DatacenterArc.ps1`.
12. For L1–L4: 🧑 HUMAN: the owner checks out each branch on `vm-dev01` and confirms it builds and runs against the source database, with the B06 functional checks that apply at that point.
13. For L5, validate the real golden path end to end, not a fresh database:
    1. 🧑 HUMAN: the owner migrates the seeded source database to the archetype's MI with MI link, following `docs/spikes/B07-arc-mi-link/migration.md`, and cuts over.
    2. Create the contained user for the web app's identity on the migrated database, with the roles the app needs.
    3. Push L5's image to the archetype's registry from `vm-dev01` and point the web app at it.
    4. Check through the web app's front end from `vm-dev01` (the web app has no private endpoint: its front end is the documented public exception, PRD §6): pages show the migrated data (row counts match the source), an upload lands in Blob, a notification round-trips through Service Bus, and telemetry reaches Application Insights. Check the database still has compatibility level 110 and the perf kit objects, so C9 works after the migration.
14. Import the known-good image with `az acr import` (the registry allows trusted Azure services, B09), run the web app on it, and repeat the checks in 13.4.
15. 🧑 HUMAN: the owner runs the playbook from a fresh copy of the repo on `vm-dev01` up to L2, using only the playbook and skills, and reports where it was unclear. Fix the playbook.
16. Tear everything down (Teardown row).

## Deliverables

- `.github/copilot-instructions.md`, `.github/modernization/playbook.md`, `.github/skills/*/SKILL.md`.
- Branches `lifeline/L1-net10` to `lifeline/L5-cutover`, pushed.
- The known-good image on GHCR.
- Workflows for lifeline builds and the known-good image.
- `coach/lifelines.md`.
- `versions.md` rows for the lifeline base commit and the image digest.

## Verify

```powershell
git ls-remote origin "refs/heads/lifeline/*"
gh run list --workflow <lifeline build workflow file> --limit 5
docker manifest inspect ghcr.io/jonathan-vella/contoso-university:known-good
npm run check
```

- Five lifeline branches, each with a green build. The image manifest exists (use `crane` or the GHCR web page if Docker isn't installed).
- The PR body has the L5 and known-good checks, the owner's playbook feedback and the cost.

## Done when

- [x] Instructions, playbook and skills exist and follow the B06 golden path.
- [x] Five lifelines build, and L5 and the known-good image pass the end-to-end checks.
- [ ] The owner ran the playbook to L2 and the gaps are fixed. Deferred to the owner (owner decision, 2026-10-08: HUMAN steps that need the Upgrade agent in VS Code don't block the PR).
- [x] Everything is torn down.

## Commit message

```text
feat: add the modernization playbook, skills and lifelines
```

## Stop and ask if

- The B06 result was ❌, or the golden path didn't reach a packaged image.
- The skill set needs to change substantially from requirement 4.
- The MI path with managed identity fails from App Service.

## Notes and traps

- **These files load into attendee sessions on purpose.** Keep instructions short and specific to the modernization, so they help Copilot rather than drown it.
- **Lifelines are public, but coach-run** (owner decision, 2026-10-08). The branches and the image are public, but students don't fetch them: a coach decides and applies them. Creating a repo from a template doesn't reliably copy non-default branches, which is why the coach fetches lifelines from the upstream repo.
- **MI cost:** B07 recorded how long a migration keeps the MI linked (it can't be stopped while linked). The MI bills about $0.68/hour while running, so stop it after cutover.
- **Contained users** for the web app's identity can only be created once the database is writable, which after MI link means after cutover (PRD §6).
- **Contained users need the directory identity** (B09 validation, 2026-10-07). `CREATE USER [<uami>] FROM EXTERNAL PROVIDER` fails with "Server identity does not have Azure Active Directory Readers permission" unless the MI's primary identity is `id-sqlmi-directory` with its Microsoft Graph grant (ALZ-lite plus event prep, `infra/foundation/README.md`). `WITH SID ..., TYPE = E` isn't supported on SQL MI. B09's PR records the exact form that worked; use it in the C7 steps.
- **The modernized app can't start without its database** (B09 validation). `DbInitializer.Initialize()` runs before `app.Run()` with no guard, so before C7 cutover the app exits at startup (code 139) and sends no telemetry. **Decided (owner, 2026-10-08):** no code change. C6 runs the app on `vm-dev01` against the source database, pushes the image and checks the App Service configuration; C7 migrates the database, writes the Key Vault secret, creates the contained user and switches the web app to the image. The app first runs on App Service at the end of C7, and the playbook says the earlier startup failure is expected.
- **Image pulls from the private registry need ARM audience tokens** on ACR (`azureADAuthenticationAsArmPolicyStatus: 'enabled'`). The archetype sets it; if a lifeline or the known-good image fails with `ACRTokenRetrievalFailure`, check that first.
- **Rebuilding lifelines:** if an earlier lifeline changes, later ones must be rebuilt on top of it. Record the base commit of each in `coach/lifelines.md`.
