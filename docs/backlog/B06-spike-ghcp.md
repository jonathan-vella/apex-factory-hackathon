# B06: Spike: GHCP golden path on the dev VM

| Field | Value |
|---|---|
| Milestone | P2 Spikes |
| Type | Both |
| Depends on | B04 |
| Unblocks | B07, B09, B10 |
| Effort | 2–3 days elapsed, including two owner-driven runs of about 3–4 hours each |
| Cost | Spike resources about $1.05/hour (Service Bus Premium 1 MU about $0.93, ACR Premium about $0.07, 4 private endpoints about $0.04; 🔎 VERIFY the Service Bus price on the [pricing page](https://azure.microsoft.com/pricing/details/service-bus/)), plus the datacenter at about $1.25/hour |
| Teardown | Delete `rg-spike-b06` and `snet-pe-spike` at the end. **Keep** `rg-datacenter` for B07 |
| PRD | §5 C3, C6; §6 App modernization; §8 GHCP risk |

## Outcome

- The golden path for C3 (assess) and C6 (modernize) is recorded: the exact sequence of GitHub Copilot steps and prompts that takes Contoso University from .NET Framework 4.8 to .NET 10, with uploads on Blob, MSMQ replaced by Service Bus, secrets in Key Vault and OpenTelemetry, running on the dev VM against the source database, and packaged as an image in a private ACR.
- Two runs by the owner show whether the sequence repeats. The hot spots, interventions and timings are in the spike report, and they're the input for the playbook and skills (B10).
- The result of each run is kept on a branch for B10 to build lifelines from.

## Before you start

1. B04 is closed. `scripts/Test-Datacenter.ps1` passes. B05 doesn't need to be closed, but if it's merged, the database is seeded.
2. `.local/settings.json` has `subscriptionId`, `location`, `memberIndex` and `suffix`.
3. 🧑 HUMAN: the owner confirms their GitHub account has a Copilot seat with agent mode enabled, and that they can sign in to GitHub and Azure on `vm-dev01`.

## Requirements

### Spike resources

1. `docs/spikes/B06-ghcp-golden-path/infra/main.bicep` deploys the Azure services the modernized app uses, with the same security settings as the archetype (PRD §6), into `rg-spike-b06`:

   | Resource | Name | Settings |
   |---|---|---|
   | Storage account | `stuni<suffix>b06` | LRS; Blob container `teaching-materials`; public network access off; shared key access off |
   | Service Bus namespace | `sbns-uni-<suffix>-b06` | Premium, 1 messaging unit; queue `notifications`; public network access off; local (SAS) auth off; no zone setting (zone-redundant automatically, backlog conventions) |
   | Container registry | `cruni<suffix>b06` | Premium; public network access off; admin user off; no zone setting (zone-redundant automatically, backlog conventions) |
   | Key Vault | `kv-uni-<suffix>-b06` | RBAC authorization; public network access off; soft delete on, purge protection off (so teardown can purge) |

2. Private endpoints for all four, in a new subnet `snet-pe-spike` (`10.10.n.128/27`) of `vnet-datacenter`, with the private DNS zones `privatelink.blob.core.windows.net`, `privatelink.servicebus.windows.net`, `privatelink.azurecr.io` and `privatelink.vaultcore.azure.net` in `rg-spike-b06`, linked to `vnet-datacenter`.
3. The owner's account gets Storage Blob Data Contributor, Azure Service Bus Data Sender and Receiver, AcrPush, and Key Vault Secrets Officer on the matching resources.
4. From `vm-dev01`, each service's hostname resolves to a private IP in `snet-pe-spike`, and TCP 443 connects (5671 too for Service Bus). Check this with a run command before handing over to the owner.

### Protocol for the owner

5. `docs/spikes/B06-ghcp-golden-path/protocol.md` is the step list the owner follows on `vm-dev01`, written for someone who hasn't used the app modernization extension before:
   1. Sign in to GitHub and Azure; clone this repo to `C:\src`; check out this item's working branch at the commit named in the protocol, and create the branch `spike/b06-run1` from it (run 2: `spike/b06-run2`, from the refined protocol's commit). `app/ContosoUniversity` must be unchanged from `main` at that commit.
   2. **C3 assess:** run the GitHub Copilot app modernization assessment on `app/ContosoUniversity` in VS Code agent mode. Save the report to the spike folder.
   3. **C6 upgrade:** plan and run the upgrade to .NET 10 and ASP.NET Core.
   4. **C6 predefined tasks,** in this order: database with managed identity (configured so the dev VM still uses SQL authentication to `10.10.n.4`, and managed identity is used only when configured), uploads to Blob, MSMQ to Service Bus, secrets to Key Vault. Blob, Service Bus and Key Vault use Entra auth with `DefaultAzureCredential`.
   5. **C6 gaps:** `Global.asax` and bundling to `Program.cs`, the `new NotificationService()` in `BaseController` to dependency injection, `Trace` to OpenTelemetry, and the `site.css` file-name case.
   6. **Package:** build the image with .NET SDK container publishing (no Docker) and push it to `cruni<suffix>b06` over the private endpoint.
   7. After each step: note the start and end time, the model and prompts used, what Copilot changed, anything the owner had to fix by hand, and whether the app still builds and runs. Commit after each step with a message naming the step.
6. The protocol includes a results sheet (`run1.md`, `run2.md`) with one row per step: time, model, prompts, interventions, build/run result and premium requests used, if visible.
7. **Models:** the protocol doesn't pin a model. It asks the owner to follow the kit's model guidance and record what they used: a balanced model (Sonnet- or Terra-class) for the assessment, the most capable model (Opus- or Sol-class) for planning, and an efficient model at maximum reasoning effort (Luna-class) to explore for plan execution. The assessment uses the extension's default model. Planning and execution start from the modernization dashboard, which uses whatever agent and model are selected in the Chat panel, so the protocol says which to select before each button (agent `modernize`). Record the exact model names, as the picker shows them, and the dates, because models change.
8. **Alternative:** the protocol has an optional section to repeat step 2 with Copilot CLI and note the differences.

### Runs

9. Push this item's working branch with the protocol, and put the commit SHA in the protocol for run 1. 🧑 HUMAN: the owner does run 1 following the protocol, fills in `run1.md` and pushes `spike/b06-run1`.
10. Between runs, update the protocol on the working branch with a refined sequence and prompts that avoid run 1's problems. Mark what changed, push, and record the new commit SHA for run 2.
11. 🧑 HUMAN: the owner does run 2 from a fresh branch off that commit, fills in `run2.md` and pushes `spike/b06-run2`.

### Check each run

12. For each run branch, check and record in the report:
    - It builds with `dotnet build` on the .NET 10 SDK, with no references left to `System.Web`, `System.Messaging` or MSMQ.
    - 🧑 HUMAN: on `vm-dev01`, the app runs locally against `10.10.n.4` and the home, Students, Courses, Instructors and Departments pages work; a teaching-material upload lands in the Blob container; an action that sends a notification puts a message on the `notifications` queue and the app reads it back.
    - The image exists in the registry: `az acr repository show-tags`.
    - No secrets in the diff: connection strings with passwords stay out of committed files (user secrets or Key Vault instead).

### Report

13. `docs/spikes/B06-ghcp-golden-path/README.md` follows the spike report format and covers:
    - the golden-path sequence, step by step, with the prompts that worked, as the input for B10;
    - hot spots and interventions per step, and which a custom skill or instruction could remove;
    - timings per step and in total, against the C3 (1 hour) and C6 (3 hours) time boxes;
    - how far run 2 matched run 1;
    - model observations per phase, dated;
    - Copilot CLI differences, if tried;
    - recommendations for B09 (what the app needs from the archetype: settings, roles, queue and container names) and B10 (skills, instructions, lifeline points).
14. Result: ✅ if run 2 reached a packaged image with every check passing and no step needing more than small manual fixes; ⚠️ if it got there with larger interventions that a skill can cover; ❌ if not.

### Teardown

15. Delete `rg-spike-b06` (purge the Key Vault) and `snet-pe-spike`. Keep `rg-datacenter` for B07. Keep the run branches.

## Deliverables

- `docs/spikes/B06-ghcp-golden-path/README.md`, `protocol.md`, `run1.md`, `run2.md`, the saved assessment reports and `infra/main.bicep`.
- Branches `spike/b06-run1` and `spike/b06-run2`, pushed and not merged.
- `versions.md` rows for the VS Code app modernization extension, the .NET 10 SDK and Copilot CLI versions used.

## Verify

```powershell
az bicep lint --file docs/spikes/B06-ghcp-golden-path/infra/main.bicep
git ls-remote origin "refs/heads/spike/b06-*"
az group exists -n rg-spike-b06
npm run check
```

- Lint is clean. Both run branches exist. `az group exists` prints `false` after teardown.

## Done when

- [ ] Both runs are recorded, and every check in requirement 12 is recorded per run.
- [ ] The report gives B10 a sequence, prompts and hot-spot list it can build on.
- [ ] Spike resources are deleted, and the datacenter is still deployed.

## Commit message

```text
docs: add the B06 GHCP golden-path spike report
```

## Stop and ask if

- The app modernization extension isn't available, or its predefined tasks differ from the list in requirement 5.
- Run 1 can't reach a building .NET 10 app within a working day.
- A private endpoint doesn't resolve or connect from `vm-dev01`.

## Notes and traps

- **Private DNS:** the datacenter VNet uses Azure DNS until B08 points it at the hub, so linking the zones to `vnet-datacenter` is what makes private endpoints resolve here. B09 uses the hub's central zones instead.
- **Service Bus Premium** is the only tier with private endpoints. It bills hourly from creation; deploy it just before run 1, and consider deleting and redeploying between runs if they're days apart.
- **Local auth off** means connection strings with keys don't work. If Copilot generates key-based code, that's a hot spot to record.
- **SDK container publishing** needs no Docker, but pushing to a registry with public access off only works from inside the VNet, which is why it runs on `vm-dev01`.
- **The source database** is shared by both runs. If the perf kit is installed, pages are slower, which is expected.
