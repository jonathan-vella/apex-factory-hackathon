# B06 comparison: GitHub Copilot upgrade vs GitHub Copilot modernization

A full end-to-end run with the **Upgrade** agent from GitHub Copilot upgrade, from the same start commit as run 1 (`da4e5f6`): assess, plan, .NET 10 upgrade, SQL Managed Instance, Blob, Service Bus and Key Vault, with the same kit tasks, rules and configuration keys as run 2 (the refined seven-task prompt). It's compared stage by stage with run 1, which used the `modernize` agent. The executor fills this in from `spike/b06-upgrade-compare`, its commits and the chat exports, as for the run sheets. Protocol: [Comparison: GitHub Copilot upgrade](protocol.md#comparison-github-copilot-upgrade-after-run-1-before-run-2).

| Field | Value |
|---|---|
| Date | 2026-09-28 |
| Branch | `spike/b06-upgrade-compare` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| GitHub Copilot upgrade (`ms-dotnettools.upgrade-agent`) | Upgrade agent 1.1.596 (as it reports itself) |
| GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) | Disabled (Workspace) for the whole run (owner decision), so the Upgrade agent is tested on its own |
| Models | GPT-6 Sol at Medium to assess and plan, GPT-6 Luna at maximum to execute |

## First attempt (2026-09-25): invalid as a baseline

Stage 2 (`a6c358d`; its chat is kept as [chats/compare-attempt1-stage2.txt](chats/compare-attempt1-stage2.txt), because the comparison branch is reset to `8a4a938` for the restart) can't be compared with run 1. The branch was clean legacy in git (only the chat file differs from `da4e5f6`), but run 1's untracked and ignored files were still in the working tree on `vm-dev01`. So the Upgrade agent reported that "the current source already satisfies most tasks and builds successfully on .NET 10", and it edited run 1's plan folder `.github/modernize/contoso-university-dotnet10-azure` (`plan.md`, `tasks.json`, `assessment.md`) instead of creating its own. It also loaded run 1's `modernize-plan` skill. The comparison restarts from a pure legacy tree (protocol C.1). Before the `git clean`, the owner moved the attempt's ignored `.github/upgrades` folder out of the repo, to `C:\src\b06-archive\compare-attempt1-upgrades` on `vm-dev01`.

Findings from the first attempt that still stand:

- **The Upgrade agent depends on GitHub Copilot modernization for Azure migrations.** It picked the scenario `azure-migrate`, whose workflow "delegates assessment and planning to the App Modernization migration session". With modernize disabled, "the prescribed App Modernization session tool was unavailable", and it fell back to the existing AppCAT report.
- **Leftover files steer the agents.** Untracked and ignored files from an earlier run (plans, skills, build output) survive `git switch` and change what the agents do.

## Stage 2, refined prompt (2026-09-28, `114e511`)

The Upgrade agent produced a compliant seven-task plan with the refined prompt: the `dotnet-version-upgrade` scenario, Guided flow, the current branch and the **Manual** commit strategy, from Upgrade agent 1.1.596. All 9 rule rows are met, it changed no application files, and it found CVE-2024-0056 in `Microsoft.Data.SqlClient` 2.1.4 for task 7. The diff from stage 1 touches only `.github/upgrades/` and the chat exports, with no secrets or IDs.

- **It revises its own plan when asked.** In Guided mode the owner corrected two details in the same chat: "zero warnings" became "no errors; record new warnings", and the irrelevant `#skill:migrating-webapi-odata` came out of task 1. That's the opposite of `modernize`, which refused to revise a finished plan (report finding 26).
- **Manual commit strategy:** the Upgrade agent doesn't commit, so the attendee commits after each task. That's more predictable than `modernize`'s mix of tool commits, `appmod/*` branches and uncommitted work (findings 29, 31, 33, 35).
- **Corrections committed:** `81f9dc0` changes "zero warnings" to "record new warnings" in eight places and removes the OData skill; the correction chat is `chats/compare-stage2-addendum.txt` on the comparison branch.
- **Noted, not corrected:** the plan calls App Service "private", although the web front end may be public. It has no code impact.

## Second attempt (2026-09-28): clean, but the old prompt

Stage 2 on a pure legacy tree (`1ae9076`; the chat is renamed `chats/compare-stage2-sixtask.txt` on the comparison branch) used the **old six-task prompt**, because the owner's local copy was stale. It's discarded as the baseline, and stage 2 is redone with the refined seven-task prompt fetched from origin (protocol C.2). The Upgrade agent itself behaved well, which is worth keeping:

- It used the `dotnet-version-upgrade` scenario. Its artifacts are under `.github/upgrades/scenarios/dotnet-version-upgrade/`: `assessment.md`, `.json` and `.csv`, per-project and NuGet reports, `dependencies-health.json`, `plan.md`, `scenario-instructions.md` and `scenario.json`.
- It changed no application files, produced exactly the six-task chain it was asked for, and filled in the compliance table correctly.
- It kept blocked validations apart from impossible tasks correctly.
- Upgrade options it chose: All-at-Once, in-place rewrite, resolve inline, fix inline, direct ASP.NET Core migration, document binding redirects before removing them, and skip test coverage.
- It flagged `Microsoft.Data.SqlClient` as vulnerable without a CVE ID. Check it again in the refined run's task 7.

## How the Upgrade dashboard was made to work (owner's discovery, 2026-09-25)

- **Routing.** Left to itself, the Upgrade agent chose the `azure-migrate` scenario, which delegates assessment and planning to GitHub Copilot modernization's App Modernization session (`start_app_mod_migration_session`). With modernize disabled, that failed. Forcing the `dotnet-version-upgrade` scenario with an explicit prompt ([prompts/compare-upgrade-plan.md](prompts/compare-upgrade-plan.md)) gives the stateful workflow under `.github/upgrades/dotnet-version-upgrade/` that the Upgrade dashboard opens, with the kit's six tasks and rules.
- **Harness.** The Upgrade dashboard's planning works in the **Copilot** harness, but task execution (`start_task`) needs **Local**, where VS Code provides the MCP server's model through sampling. That's the opposite of run 1's prompt files, which loaded only in **Local** (report findings 14 and 16). So the harness has to be chosen per tool, and the kit's guides must say which.

## Stages

Where the Upgrade agent can't do a stage without GitHub Copilot modernization, the **Covered** column records that as a result, not a failure.

| Stage | Covered by the Upgrade agent? | Time | Model | Prompts | Interventions | Build / run | Live check |
|---|---|---|---|---|---|---|---|
| C.1 Set up | — | | — | — | | — | — |
| C.2 Assess and plan (7 tasks, 9 rules) | ✅ `dotnet-version-upgrade`, Guided flow, current branch, Manual commit strategy (`114e511`) | | GPT-6 Sol, Medium | The refined prompt, then one correction reply in the same chat | 1 plan correction: "zero warnings" to "no errors; record new warnings", and the irrelevant `#skill:migrating-webapi-odata` removed from task 1 | 0 application files changed | Rules table: all 9 rows met. Task 7 has a real finding: CVE-2024-0056 in `Microsoft.Data.SqlClient` 2.1.4 |
| C.3.1 .NET 10 upgrade | ✅ in the **Local** harness (`c1ebad4`). The first attempts in the Copilot harness were blocked before any change (no MCP sampling) | | GPT-6 Luna, maximum | `start_task` for task 01 | None reported | SDK-style `Microsoft.NET.Sdk.Web`, `net10.0`, `Program.cs`; `packages.config` and `Global.asax` removed; static files under `wwwroot`; SDK container properties (`aspnet:10.0`, `contoso-university`, port 8080) and no `Dockerfile`; the workflow generated `tasks.md`; `UserSecretsId` `ContosoUniversity-Configuration`. The diff touches only `app/`, `.github/upgrades/` and the chats, with no secrets | Ran against `10.10.1.4` in Development: 2 of the 5 pages tested and loaded; the other 3 **untested** |
| C.3.2 SQL Managed Instance (local SQL auth kept) | | | | | | | Students against `10.10.n.4`: |
| C.3.3 Blob | | | | | | | Upload lands in `teaching-materials`: |
| C.3.4 Service Bus | | | | | | | Send and receive (`/Notifications/GetNotifications`): |
| C.3.5 Key Vault | | | | | | | Connection string from Key Vault; refuses to start outside Development without `KeyVault:VaultUri` or with a SQL login: |
| C.3.6 OpenTelemetry | | | | | | | Starts without a connection string; requests, dependencies and logs in Application Insights: |
| C.3.7 CVE fixes | | | | | | | `dotnet list package --vulnerable`: |
| **Total** | | | | | | | |

## Side by side with run 1

| Stage | `modernize` agent (run 1, `spike/b06-run1`) | Upgrade agent (`spike/b06-upgrade-compare`) |
|---|---|---|
| Assess | Custom assessment on the dashboard, App Service Linux target; default assessment targeted Windows (findings 5, 15) | |
| Plan | `/create-modernization-plan` with the 7 kit rules met all rules first time; **Create Plan** had missed most, and a finished plan can't be revised (findings 20–27) | The refined seven-task prompt met all 9 rules; the agent revised two details in the same chat when asked; Manual commit strategy (`114e511`) |
| .NET 10 upgrade | Task 001 without the upgrade agent, builds; output stashed by the next task's branch switch and restored by hand (findings 29, 30) | Task 01 in the Local harness after two blocked starts in Copilot; no intervention; SDK container properties already in the project (`c1ebad4`) |
| SQL Managed Instance | Task 002 on an `appmod/*` branch, local SQL auth kept; five pages work (findings 31, 32) | |
| Blob | Task 003 after a stale-tracker retry, uncommitted; upload passed (finding 33) | |
| Service Bus | Task 004; send worked, receive broken (`TimeSpan.Zero`), one manual fix, then round trip passed (findings 35, 36) | |
| Key Vault | Task 005: delegation blocked three ways, run with the default Agent (findings 37–39) | |
| Execution reliability | Delegation blocked 3 of 5 tasks | |
| Interventions in total | | |

## `modernize` with the upgrade extension installed

For run 2, with `ms-dotnettools.upgrade-agent` installed: does the `modernize` agent behave differently?

| Observation | Result |
|---|---|
| Plan includes the upgrade without rule 1 | |
| The upgrade task is handed to the Upgrade agent | |
| Other | |

## Recommendation

Which extension or extensions the kit's dev VM should install, for the owner to decide. B04's extension list isn't changed until then.
