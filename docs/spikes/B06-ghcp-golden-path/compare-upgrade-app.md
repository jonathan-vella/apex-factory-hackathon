# B06 comparison in the GitHub Copilot app

The full Upgrade agent comparison repeated in the **GitHub Copilot app** instead of VS Code (requirement 11b, owner-approved 2026-09-29). Only the host changes: the same Upgrade agent (plugin `upgrade-agent@upgrade-agent-plugins` from [microsoft/upgrade-agent-plugins](https://github.com/microsoft/upgrade-agent-plugins)), the same refined seven-task prompt ([prompts/compare-upgrade-plan.md](prompts/compare-upgrade-plan.md)), models, kit rules, configuration keys and live checks as [compare-upgrade.md](compare-upgrade.md). The executor fills this in from `spike/b06-upgrade-app`, its commits and the saved conversations. Protocol: [Comparison: GitHub Copilot upgrade in the Copilot app](protocol.md#comparison-github-copilot-upgrade-in-the-copilot-app-after-the-vs-code-comparison-before-run-2).

| Field | Value |
|---|---|
| Date | 2026-09-30 |
| Branch | `spike/b06-upgrade-app` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| GitHub Copilot app | |
| `upgrade-agent` plugin | Marketplace version 1.1.596 (checked 2026-09-29); installed: |
| Other plugins | None (no modernization plugin) |
| Session type | **Worktree** session (the app's default), under `C:\Users\labadmin\.copilot\repos\copilot-worktrees\apex-factory-hackathon\<session-branch>`, not the planned branch session on `C:\src`; the owner continued in it, as the attendee default |
| Models | GPT-6 Sol at Medium to assess and plan, GPT-6 Luna at maximum to execute, switched in the model picker of **one** session |

## Questions this run answers

| Question | Answer |
|---|---|
| Does the plugin install from the README's deep link, from `/plugin`, or both? Is a restart needed? | |
| Does `start_task` run in the Copilot app? In VS Code it needed the Local harness for MCP sampling (report finding 51) | Pending: task 01 is next, with GPT-6 Luna at maximum |
| Is there an equivalent of the Upgrade dashboard, or is the run chat-only? | Yes: the Upgrade Agent Dashboard renders inside the app, with Overview, Assessment, Plan, Execution and Activity tabs ("Step 1 of 5"; "Baseline failing 0/1 projects built", expected for the .NET Framework 4.8 project) |
| Do the `dotnet-version-upgrade` routing, Guided flow and Manual commit strategy behave as in VS Code? | Routing: `dotnet-version-upgrade`, as in VS Code. Guided flow differs: the app paused at the **assessment** gate and again at the **plan** gate, while VS Code ran assessment and planning in one go. Commit strategy differs: the app's scenario uses **After Each Task** with branch sync **Auto (Merge)**, while VS Code used **Manual** |
| Does the app's session or branch handling clash with the agent's? | The app's default is a worktree session with its own branch, so the work isn't in `C:\src` and has to be pushed to `spike/b06-upgrade-app` from the worktree. The first commit on `spike/b06-upgrade-app` (`f0b2927`) holds only a 6-line chat note. Clashes with the agent: pending |
| How do you export a conversation? | |

## Stages

| Stage | Covered by the Upgrade agent? | Time | Model | Prompts | Interventions | Build / run | Live check |
|---|---|---|---|---|---|---|---|
| A.1 Set up | — | `f0b2927` (a chat note only; the stage 1 commit body kept placeholders for the app and plugin versions) | — | — | The session opened as a worktree, not a branch session on `C:\src` | — | — |
| A.2 Assess and plan (7 tasks, 9 rules) | ✅ `dotnet-version-upgrade`, in the app's worktree session (`6372965`) | About 5 h wall-clock (06:04–11:09 UTC, including the two Guided gates and any pauses) | GPT-6 Sol, Medium | The refined prompt fetched from origin; the owner approved the assessment gate, then the plan gate | **None**: the plan was approved as is | 0 application files changed; no `.vs` folder committed; the diff stays in `.github/upgrades/` and the chats, with no secrets | Rules: all met. Seven tasks in a strict chain; SQL Managed Instance only (Azure SQL Database excluded); Blob only (no Azure Files); `DefaultAzureCredential` and `Authentication=Active Directory Default`; one `UseAzureMonitor()`; Key Vault mandatory outside Development; SDK container publishing with no Dockerfile; `privatelink` names and Dockerfiles appear only as prohibitions. Task 01 again references `#skill:migrating-webapi-odata`, framed as a behavior-preservation gate; the owner accepted it, where the VS Code comparison had removed it |
| A.3.1 .NET 10 upgrade | First attempt **blocked** by the `#skill:migrating-webapi-odata` gate (unknown consumers of the notification JSON endpoints, no API contract tests). The retry did the upgrade, then the workflow's own reviewer split the task into 01.01 (upload path hardening, implemented) and 01.02 (the notification transport, needs an owner decision). **Paused by the owner; nothing committed yet** | Long; not yet measurable | GPT-6 Luna, maximum, same session as the plan | `start_task` for task 01, then retries | **2 so far**: answering the OData gate, and pausing the run to diagnose more than 50,000 changed files before any commit. Pending: the 01.02 decision. The agent also ran the kit's PowerShell preflight and tried `npm test`, which aren't part of the app | SDK-style `net10.0`, `wwwroot`, SDK container publishing, notification routes and JSON shape preserved, 0 warnings (agent's report). The reviewer flagged a non-durable in-process notification queue, and a path-traversal risk in the Courses upload, which it hardened | Pages against `10.10.n.4`: **failed**, because the app fell back to LocalDB: the SQL user secret wasn't set for the worktree's project |
| A.3.2 SQL Managed Instance | | | | | | | Development pages; Production with a SQL login refuses to start: |
| A.3.3 Blob | | | | | | | Upload lands in `teaching-materials` and shows through the app: |
| A.3.4 Service Bus | | | | | | | Send and receive (`/Notifications/GetNotifications`): |
| A.3.5 Key Vault | | | | | | | Connection string from Key Vault; refuses to start outside Development without `KeyVault:VaultUri` or with a SQL login: |
| A.3.6 OpenTelemetry | | | | | | | Starts without a connection string; requests, dependencies and logs in Application Insights: |
| A.3.7 CVE fixes | | | | | | | `dotnet list package --vulnerable`: |
| **Total** | | | | | | | |

## Three-way side by side

| Stage | `modernize` in VS Code (run 1) | Upgrade agent in VS Code (`spike/b06-upgrade-compare`) | Upgrade agent in the Copilot app (`spike/b06-upgrade-app`) |
|---|---|---|---|
| Set up and harness | VS Code; prompt files needed the Local harness, the dashboard the Copilot harness | Planning in the Copilot harness, tasks only in Local (MCP sampling) | One session from assessment through execution; no harness split; the default session is a worktree |
| Assess and plan | Custom assessment, then `/create-modernization-plan` with the kit rules; a finished plan can't be revised | Refined prompt met all 9 rules; revised its plan when asked | Refined prompt met all rules; two Guided gates (assessment, then plan); approved as is, with no correction |
| .NET 10 upgrade | Work stashed by the next task's branch switch, restored by hand | First time, no intervention | Blocked by the OData skill's gate, then split by the workflow's reviewer into path hardening and a transport decision; paused with more than 50,000 changed files; not yet committed |
| SQL Managed Instance | On an `appmod/*` branch | One `continue`; Entra-only enforced at startup | |
| Blob | Stale-tracker retry | First time, no intervention | |
| Service Bus | Receive bug, one hand fix | First time, no intervention | |
| Key Vault | Delegation blocked three ways; direct prompt worked | First time, no intervention; Key Vault only outside Development | |
| OpenTelemetry | Startup crash, one hand fix; edited `docs/prd.md` | No intervention; telemetry in Application Insights with Entra | |
| CVE fixes | Nothing to fix | | |
| Interventions in total | 2 code fixes, 2 git recoveries | | |

## Recommendation

Which extensions or plugins, and which host (VS Code or the Copilot app), the kit's dev VM should offer, for the owner to decide. B04's install list isn't changed until then.
