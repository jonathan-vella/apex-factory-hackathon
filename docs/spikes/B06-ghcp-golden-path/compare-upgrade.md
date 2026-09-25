# B06 comparison: GitHub Copilot upgrade vs GitHub Copilot modernization

A full end-to-end run with the **Upgrade** agent from GitHub Copilot upgrade, from the same start commit as run 1 (`da4e5f6`): assess, plan, .NET 10 upgrade, SQL Managed Instance, Blob, Service Bus and Key Vault, with the same kit rules and configuration keys. It's compared stage by stage with run 1, which used the `modernize` agent. The executor fills this in from `spike/b06-upgrade-compare`, its commits and the chat exports, as for the run sheets. Protocol: [Comparison: GitHub Copilot upgrade](protocol.md#comparison-github-copilot-upgrade-after-run-1-before-run-2).

| Field | Value |
|---|---|
| Date | |
| Branch | `spike/b06-upgrade-compare` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| GitHub Copilot upgrade (`ms-dotnettools.upgrade-agent`) | |
| GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) | Disabled (Workspace) / kept enabled: |
| Models | GPT-6 Sol at Medium to assess and plan, GPT-6 Luna at maximum to execute |

## Stages

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
