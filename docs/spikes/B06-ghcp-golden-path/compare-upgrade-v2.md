# B06 comparison rerun: GitHub Copilot upgrade in VS Code (11a rerun)

A from-scratch rerun of the VS Code comparison ([compare-upgrade.md](compare-upgrade.md)), at the owner's request (2026-10-01), to retest finding 51: in 11a, `start_task` failed in the **Copilot** harness with "internal LLM client unavailable" and ran only in **Local**. It has two parts, both from `da4e5f6` with the same prompt, addendum and models:

- **v2, Copilot harness, stage 2 only** (`spike/b06-upgrade-compare-v2`, kept as evidence, owner decision 2026-10-01). Planning works in the Copilot harness with model access allowed; `start_task` doesn't (`859d4ed`).
- **v3, Local harness, full run** (`spike/b06-upgrade-compare-v3`). The owner restarted from scratch in the Local harness for every stage.

The executor fills this in from the run branches, their commits and the chat exports. Protocol: [11a rerun](protocol.md#11a-rerun-github-copilot-upgrade-in-vs-code).

| Field | Value |
|---|---|
| Date | 2026-10-01 |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| GitHub Copilot upgrade (`ms-dotnettools.upgrade-agent`) | **1.1.612** (11a: 1.1.596) |
| GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) | 1.24.0, Disabled (Workspace) |
| Models | **Claude Opus 5.5 at Medium** to assess and plan (owner decision, 2026-10-01; 11a used GPT-6 Sol at Medium, so stage 2 isn't like for like on the model), GPT-6 Luna at maximum to execute in v2 (not run); v3 executes with Claude Sonnet 5.5 at Medium |
| Prompt | `prompts/compare-upgrade-plan.md`, then `prompts/compare-upgrade-app-addendum.md` (11a used the prompt without the addendum) |
| Model access | Already set before stage 2: `chat.mcp.serverSampling` still had `"GitHub Copilot upgrade: Upgrade": { allowedDuringChat: true }` from 11a, so no change was needed |

## v2: Copilot harness, stage 2 only

Branch `spike/b06-upgrade-compare-v2`, head `859d4ed`. Kept as evidence; no task started.

| Stage | Commit | Harness | Model | Interventions | Result |
|---|---|---|---|---|---|
| 1 Set up | `443c963` | — | — | — | Pure legacy tree, pushed |
| 2 Assess and plan | `b49ce4b` | Copilot | Claude Opus 5.5, Medium | 0 | ✅ Tool-based assessment: `assessment.md`, `assessment.json`, `assessment.csv`, `dependencies-health.json` and the `assessment/` detail pages under `.github/upgrades/scenarios/dotnet-version-upgrade/`. A compliant seven-task plan with `plan.md`, `scenario-instructions.md` and `scenario.json`. Branch Sync saved as **Manual** (the addendum said off). Only `.github/upgrades/` changed; no secrets in the diff |

**Result:** with model access allowed, the Copilot harness runs the Upgrade agent's tool-based assessment and planning, including the dedicated .NET assessor that the Copilot app comparison never reached. **`start_task` (`859d4ed`):** in the same harness, with model access allowed, it couldn't parse `plan.md` (internal LLM client unavailable), also after a VS Code and MCP reload; no task started, and the `scenario.json` properties were cleared. **Finding 51 is confirmed on 1.1.612:** planning works in Copilot, execution needs Local. No more v2 evidence is needed.

## v3: Local harness, full run

| Field | Value |
|---|---|
| Branch | `spike/b06-upgrade-compare-v3` |
| Harness | **Local** for every stage; `start_task` worked first time on every task |
| Head | `54b5b45` (stage 3.7) |
| Scenario settings | Branch Sync Disabled, Manual commits |
| Execution model | **Claude Sonnet 5.5 at Medium** (owner decision, 2026-10-02), not GPT-6 Luna at maximum, so v3 isn't like for like with 11a on models |
| Package | SDK container publishing to the private registry, tag `compare-v3` (the registry now has `compare`, `compare-v3` and `run1`) |

Times are UTC+2 on 2026-10-02, from the owner and the commit times; task times include the owner's checks.

| Stage | Commit | Time | Model | Interventions | Live check |
|---|---|---|---|---|---|
| 1 Set up | `2bbe048` | — | — | 0 | — |
| 2 Assess and plan (7 tasks, 9 rules) | `d08dc9d` | 08:39–08:53, about 14 min | Claude Opus 5.5, Medium | 0 | ✅ Tool-based assessment (`assessment.json`, `dependencies-health.json`, `assessment.csv`); compliant seven-task plan; only `.github/upgrades/` changed, no secrets |
| 3.1 .NET 10 upgrade | `bfd8bf7` | 08:56–09:26, about 30 min | Claude Sonnet 5.5, Medium | 0 | ✅ The five pages return 200 once the user secrets are set (the project's `UserSecretsId` differed, so the owner copied 11a's secrets); styling the same as the legacy app (neither has Bootstrap CSS); the notification JSON contract preserved |
| 3.2 SQL Managed Instance | `bd0ecad` | about 6 min | Claude Sonnet 5.5, Medium | 0 | ✅ Production refuses a SQL login; an Entra connection string passes the guard |
| 3.3 Blob | `e9a1003` | about 12 min | Claude Sonnet 5.5, Medium | 0 | ✅ Upload, display, replace and delete against the real storage account; an invalid type and a file over 5 MB are rejected; no blob URLs reach the browser. It also guards the blob name and the course ownership, which 11a didn't |
| 3.4 Service Bus | `4b7fb02` | about 13 min | Claude Sonnet 5.5, Medium | 0 | ✅ Send on create, edit and delete; receive through `/Notifications/GetNotifications`; PascalCase JSON; `ReceiveAndDelete` with a 1-second wait, so no `TimeSpan.Zero` bug |
| 3.5 Key Vault | `e9d21d1` | about 16 min | Claude Sonnet 5.5, Medium | 0 | ✅ A: Development without a vault runs. B: Production without `KeyVault:VaultUri` refuses to start. C: the vault loads through its private endpoint and the SQL login from it is refused. A `LocalFirstSecretManager` keeps the Development user secret. The agent flagged that the spike vault's secret holds SQL credentials: expected for the spike, as in 11a's check C' |
| 3.6 OpenTelemetry | `c07f747` | about 12 min | Claude Sonnet 5.5, Medium | 0 | ✅ Starts without a connection string. Application Insights shows requests, SQL dependencies, traces, an exception and Entra token ingestion, and, after exercising Blob and Service Bus by hand, Azure blob dependencies (4, 0 failed). **No Service Bus dependency** (see below) |
| 3.7 CVE fixes | `54b5b45` | about 20 min | Claude Sonnet 5.5, Medium | 0 | ✅ Verified no-op: no vulnerable or deprecated packages; `Microsoft.Data.SqlClient` 6.1.6, `Microsoft.Identity.Client` 4.84.2 |
| **Total** | | **About 14 min to plan plus about 1 h 46 min for 7 tasks (08:56–10:42)** | | **0 interventions, 0 code fixes** | 7 of 7 tasks |

The executor's checks on `54b5b45`: no secrets, tenant, subscription or object IDs in the diff from `da4e5f6`; no `System.Web`, `System.Messaging` or `MessageQueue` in `app/`; no Dockerfile. When the agent finished, it offered Aspire, ARM64 and a report; the owner declined them as out of scope.

### v3 findings

- **Service Bus never shows as a dependency in Application Insights**, in v3 or in 11a. A 10-day query finds only SQL, Azure blob, `Microsoft.Storage` and `Microsoft.AAD` dependencies. The Azure Monitor distro doesn't trace Service Bus (AMQP) by default. Send and receive were proven in task 04, so this is an observability gap, not a functional one. Note for B07 and B11.
- **`--no-launch-profile` starts the app in Production.** For local runs, attendees must set `ASPNETCORE_ENVIRONMENT=Development`, or the Production guards refuse the on-premises SQL login.
- **The worktree's `UserSecretsId` can differ** from an earlier run's, so the user secrets have to be set again (or copied) for each new branch.

## Harness result

| Question | Result |
|---|---|
| Does planning run in the Copilot harness with model access allowed? | Yes (v2, `b49ce4b`) |
| Does planning run in the Local harness? | Yes (v3, `d08dc9d`) |
| Does `start_task` run in the Copilot harness? | **No** (v2, `859d4ed`): couldn't parse `plan.md`, internal LLM client unavailable, also after a reload |
| Does `start_task` run in the Local harness? | **Yes**, first time on all seven tasks (v3) |
| Finding 51 confirmed, or revised? | **Confirmed** on 1.1.612 |

**Conclusion (v2 and v3).** With the Upgrade extension in VS Code, planning runs in either harness, but tasks run only in **Local**. Local alone works end to end, so the recommendation is **Local for the whole run**. The Learn documentation doesn't mention harnesses.

## Against 11a

| Stage | 11a (`spike/b06-upgrade-compare`) | v2 (Copilot harness) | v3 (Local harness) |
|---|---|---|---|
| Harness for planning | Copilot | Copilot | Local |
| Harness for tasks | Local only, after `start_task` failed in Copilot | `start_task` failed in Copilot (`859d4ed`) | Local, first time on every task |
| Assessment | Tool-based | Tool-based, with `assessment.json` and `dependencies-health.json` | Tool-based, with `assessment.json` and `dependencies-health.json` |
| Tasks done | 7 of 7 | None | 7 of 7 |
| Interventions | 1 `continue`, 0 code fixes | 0 (stage 2) | 0, 0 code fixes |
| Task time | At least 4 h 18 min of measurable stages, with overnight pauses | — | About 1 h 46 min, in one sitting |
| Service Bus receive | 1-second wait | — | 1-second wait, `ReceiveAndDelete` |
| Blob guards | Type and size | — | Type, size, blob name and course ownership |
| Image tag | `compare` | — | `compare-v3` |
| Upgrade agent version | 1.1.596 | 1.1.612 | 1.1.612 |
| Planning model | GPT-6 Sol, Medium | Claude Opus 5.5, Medium | Claude Opus 5.5, Medium |
| Execution model | GPT-6 Luna, maximum | Not run | Claude Sonnet 5.5, Medium |
