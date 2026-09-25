# B06 comparison: GitHub Copilot upgrade vs GitHub Copilot modernization

A full end-to-end run with the **Upgrade** agent from GitHub Copilot upgrade, from the same start commit as run 1 (`da4e5f6`): assess, plan, .NET 10 upgrade, SQL Managed Instance, Blob, Service Bus and Key Vault, with the same kit rules and configuration keys. It's compared stage by stage with run 1, which used the `modernize` agent. The executor fills this in from `spike/b06-upgrade-compare`, its commits and the chat exports, as for the run sheets. Protocol: [Comparison: GitHub Copilot upgrade](protocol.md#comparison-github-copilot-upgrade-after-run-1-before-run-2).

| Field | Value |
|---|---|
| Date | |
| Branch | `spike/b06-upgrade-compare` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| GitHub Copilot upgrade (`ms-dotnettools.upgrade-agent`) | |
| GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) | Disabled (Workspace) for the whole run (owner decision), so the Upgrade agent is tested on its own |
| Models | GPT-6 Sol at Medium to assess and plan, GPT-6 Luna at maximum to execute |

## First attempt (2026-09-25): invalid as a baseline

Stage 2 (`a6c358d`, `chats/compare-stage2.txt`) can't be compared with run 1. The branch was clean legacy in git (only the chat file differs from `da4e5f6`), but run 1's untracked and ignored files were still in the working tree on `vm-dev01`. So the Upgrade agent reported that "the current source already satisfies most tasks and builds successfully on .NET 10", and it edited run 1's plan folder `.github/modernize/contoso-university-dotnet10-azure` (`plan.md`, `tasks.json`, `assessment.md`) instead of creating its own. It also loaded run 1's `modernize-plan` skill. The comparison restarts from a pure legacy tree (protocol C.1).

Findings from the first attempt that still stand:

- **The Upgrade agent depends on GitHub Copilot modernization for Azure migrations.** It picked the scenario `azure-migrate`, whose workflow "delegates assessment and planning to the App Modernization migration session". With modernize disabled, "the prescribed App Modernization session tool was unavailable", and it fell back to the existing AppCAT report.
- **Leftover files steer the agents.** Untracked and ignored files from an earlier run (plans, skills, build output) survive `git switch` and change what the agents do.

## Stages

Where the Upgrade agent can't do a stage without GitHub Copilot modernization, the **Covered** column records that as a result, not a failure.

| Stage | Covered by the Upgrade agent? | Time | Model | Prompts | Interventions | Build / run | Live check |
|---|---|---|---|---|---|---|---|
| C.1 Set up | — | | — | — | | — | — |
| C.2 Assess and plan (7 kit rules) | | | | | | — | Rules table: |
| C.3.1 .NET 10 upgrade | | | | | | | Pages against `10.10.n.4`: |
| C.3.2 SQL Managed Instance (local SQL auth kept) | | | | | | | Students against `10.10.n.4`: |
| C.3.3 Blob | | | | | | | Upload lands in `teaching-materials`: |
| C.3.4 Service Bus | | | | | | | Send and receive (`/Notifications/GetNotifications`): |
| C.3.5 Key Vault | | | | | | | Runs with the connection string from Key Vault: |
| **Total** | | | | | | | |

## Side by side with run 1

| Stage | `modernize` agent (run 1, `spike/b06-run1`) | Upgrade agent (`spike/b06-upgrade-compare`) |
|---|---|---|
| Assess | Custom assessment on the dashboard, App Service Linux target; default assessment targeted Windows (findings 5, 15) | |
| Plan | `/create-modernization-plan` with the 7 kit rules met all rules first time; **Create Plan** had missed most (findings 20–27) | |
| .NET 10 upgrade | Task 001 without the upgrade agent, builds; output stashed by the next task's branch switch and restored by hand (findings 29, 30) | |
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
