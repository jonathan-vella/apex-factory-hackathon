# B10: Build the modernization playbook, skills and lifelines

| Field | Value |
|---|---|
| Milestone | P3 Build |
| Type | Both |
| Depends on | B06, B09 |
| Unblocks | B11 |
| Effort | 3–4 days |
| Cost | About $3.65/hour while the validation stack is deployed (same stack as B09) |
| Teardown | Delete everything this item created, as in B09 |
| PRD | §5 C6, C7; §6 App modernization; §8 GHCP risk |

## Outcome

- `.github/` carries the modernization aids that load into attendees' GitHub Copilot sessions: repo instructions, a playbook that sequences the predefined tasks, and custom skills for the gaps the predefined tasks don't cover. They're built from the B06 golden path.
- Five lifeline branches give a known-good checkpoint after each major step of C6 and C7, and a known-good image is the last resort.
- The golden-path end state runs on App Service against SQL MI with managed identity, over private endpoints.

## Before you start

1. B06 and B09 are closed. Read the B06 report, both run sheets and the `spike/b06-run2` branch.
2. The .NET 10 SDK is installed locally: `dotnet --list-sdks` shows a 10.x SDK.
3. `.local/settings.json` has `tenantId`, `subscriptionId`, `location`, `memberIndex` and `suffix`.

## Requirements

### Instructions, playbook and skills

1. `.github/copilot-instructions.md`: short repo instructions for Copilot in an attendee's copy: what the repo is, that `app/ContosoUniversity` is the legacy app being modernized to .NET 10 on App Service for Linux, the target services and how they authenticate (managed identity on App Service, the member's identity with `DefaultAzureCredential` on the dev VM, SQL authentication only to the source database), and a pointer to the playbook. Nothing about the kit's own tooling.
2. `.github/modernization/playbook.md`: the golden path from B06 run 2, as a sequence an attendee follows: assess (C3), upgrade, predefined tasks in the B06 order, the gap skills, packaging, and the App Service configuration. For each step: the goal, the prompt to use, what to check before moving on, the known hot spots and the lifeline to fall back to.
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

6. Build the golden-path end state from `spike/b06-run2`, fixing what the run left rough, so that it meets every check in B06 requirement 12 and runs on App Service against SQL MI. This is the known-good solution.
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
10. `coach/lifelines.md`: what each lifeline contains, when to hand it out, how the member gets it, and what it costs in points (a pointer to the rubric, which B12 writes). Template copies don't reliably include non-default branches, so the member fetches a lifeline from the upstream public repo into their own: `git fetch https://github.com/jonathan-vella/apex-factory-hackathon.git lifeline/L3-servicebus:lifeline/L3-servicebus`, then `git switch`. For the image, `az acr import`. Test the fetch from a repo created from the template.

### Validate for real

11. Deploy ALZ-lite (shared services subscription), then the datacenter, vending and the archetype (workload subscription) with the kit scripts. Onboard `vm-app01` to Arc with `scripts/Connect-DatacenterArc.ps1`.
12. For L1–L4: 🧑 HUMAN: the owner checks out each branch on `vm-dev01` and confirms it builds and runs against the source database, with the B06 functional checks that apply at that point.
13. For L5, validate the real golden path end to end, not a fresh database:
    1. 🧑 HUMAN: the owner migrates the seeded source database to the archetype's MI with MI link, following `docs/spikes/B07-arc-mi-link/migration.md`, and cuts over.
    2. Create the contained user for the web app's identity on the migrated database, with the roles the app needs.
    3. Push L5's image to the archetype's registry from `vm-dev01` and point the web app at it.
    4. Check through the web app's private endpoint from `vm-dev01`: pages show the migrated data (row counts match the source), an upload lands in Blob, a notification round-trips through Service Bus, and telemetry reaches Application Insights. Check the database still has compatibility level 110 and the perf kit objects, so C9 works after the migration.
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

- [ ] Instructions, playbook and skills exist and follow the B06 golden path.
- [ ] Five lifelines build, and L5 and the known-good image pass the end-to-end checks.
- [ ] The owner ran the playbook to L2 and the gaps are fixed.
- [ ] Everything is torn down.

## Commit message

```text
feat: add the modernization playbook, skills and lifelines
```

## Stop and ask if

- The B06 result was ❌, or run 2 didn't reach a packaged image.
- The skill set needs to change substantially from requirement 4.
- The MI path with managed identity fails from App Service.

## Notes and traps

- **These files load into attendee sessions on purpose.** Keep instructions short and specific to the modernization, so they help Copilot rather than drown it.
- **Lifelines are public,** on the honor system (PRD §2). Creating a repo from a template doesn't reliably copy non-default branches, which is why members fetch lifelines from the upstream repo.
- **Free-offer MI credits:** B07 recorded how many vCore hours a migration uses. Check enough are left this month before deploying the archetype's MI.
- **Contained users** for the web app's identity can only be created once the database is writable, which after MI link means after cutover (PRD §6).
- **Rebuilding lifelines:** if an earlier lifeline changes, later ones must be rebuilt on top of it. Record the base commit of each in `coach/lifelines.md`.
