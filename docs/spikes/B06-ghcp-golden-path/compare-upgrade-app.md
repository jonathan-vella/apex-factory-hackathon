# B06 comparison in the GitHub Copilot app

The full Upgrade agent comparison repeated in the **GitHub Copilot app** instead of VS Code (requirement 11b, owner-approved 2026-09-29). The same Upgrade agent (plugin `upgrade-agent@upgrade-agent-plugins` from [microsoft/upgrade-agent-plugins](https://github.com/microsoft/upgrade-agent-plugins)), the same refined seven-task prompt ([prompts/compare-upgrade-plan.md](prompts/compare-upgrade-plan.md)), kit rules, configuration keys and live checks as [compare-upgrade.md](compare-upgrade.md). The executor fills this in from the run branch, its commits and the saved conversations. Protocol: [Comparison: GitHub Copilot upgrade in the Copilot app](protocol.md#comparison-github-copilot-upgrade-in-the-copilot-app-after-the-vs-code-comparison-before-run-2).

**Attempt 1 was abandoned and the run restarted (owner decision, 2026-09-30).** Attempt 2 adds an owner-decisions addendum to the prompt ([prompts/compare-upgrade-app-addendum.md](prompts/compare-upgrade-app-addendum.md)) and uses **different models** (owner-approved deviation): Claude Opus 5.5 to assess and plan, Claude Sonnet 5.5 to execute. The VS Code comparison used GPT-6 Sol and GPT-6 Luna, so **the app-versus-VS Code comparison isn't like for like on models, on the prompt, or (after the reinstall) on the plugin version**.

**Paused (owner decision, 2026-10-01: "drop the github copilot app for now").** The redo of attempt 2's stage 2 stopped because the Upgrade MCP server exposed no tools after the clean reinstall: `get_state` and `initialize_scenario` were still missing after the first turn (plugin 1.1.612), so the prompt's tools guard stopped the run before any assessment or plan. `spike/b06-upgrade-app-v2` stays at `37a22b6`. The tables below stay incomplete. The Copilot app with the `upgrade-agent` plugin **isn't a recommendation for attendees at this point**. The VS Code comparison ([compare-upgrade.md](compare-upgrade.md)) and run 2 are unaffected.

## Attempt 2

| Field | Value |
|---|---|
| Date | 2026-09-30 to 2026-10-01; paused 2026-10-01 |
| Branch | `spike/b06-upgrade-app-v2` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| GitHub Copilot app | |
| `upgrade-agent` plugin | **1.1.612** after the clean reinstall (the VS Code comparison used 1.1.596, so the versions differ) |
| Other plugins | None (no modernization plugin) |
| Session type | |
| Scenario settings | Target `net10.0`, Guided, current branch, commit strategy Manual, branch sync off (from the prompt); confirmed: |
| Models | Claude Opus 5.5 to assess and plan, Claude Sonnet 5.5 to execute, switched in the model picker of one session |
| Prompt | `compare-upgrade-plan.md` (refined, plus the owner-directed Upgrade-tool fixes of 2026-10-01), then `compare-upgrade-app-addendum.md` |
| Restart point | `37a22b6` (the void first stage 2 removed) |

### First stage 2: void (2026-09-30 to 2026-10-01)

The first stage 2 of attempt 2 ran **without the .NET analysis tools**: `generate_dotnet_upgrade_assessment` wasn't available, so the generic Assessor wrote `assessment.md` by hand. There was no `assessment.json` or `dependencies-health.json`, the dashboard's **Assessment** tab was empty, and the properties in `scenario.json` were empty. It also ran straight through the assessment gate. The owner voided it: commits `b347103..a2572e3` were removed in `37a22b6`, the app and the plugin were reinstalled from clean (plugin **1.1.612**), and stage 2 is redone.

**Cause: unknown.** The plugin (1.1.612) has two MCP servers. `Microsoft.GitHubCopilot.Upgrade.Mcp` provides the 8 core workflow tools (`get_state` to `open_dashboard`). The .NET analysis tools, including `generate_dotnet_upgrade_assessment`, come from a separate extension server, `Microsoft.GitHubCopilot.Upgrade.DotNet.Mcp`, which `upgrade/dotnet/upgrade-extension.json` starts with `dnx --yes --ignore-failed-sources` and a 300-second start-up timeout. In that session the extension server never exposed its tools, and the first retry reported `StateManager not initialized`. A failed download is ruled out: both packages are in the NuGet cache on `vm-dev01`, in versions 1.1.539, 1.1.596 and 1.1.612. Without the analysis tools the agent fell back to the generic Assessor instead of stopping. Separately, in 1.1.612 the `azure-migrate` scenario only hands off to `start_app_mod_migration_session`, which needs the modernization extension, so `dotnet-version-upgrade` is the only workable scenario for this run.

**Fixes (owner-directed, 2026-10-01).** The prompt now requires the Upgrade workflow tools and the dedicated .NET assessor and stops if either is missing, pauses at the assessment gate, answers the pre-initialization confirmation, and lists the dashboard data among the required artifacts; it's pure ASCII. The addendum says the backend checks are expected to run inside the VNet. Protocol A.1 step 7 checks that both packages are listed in the NuGet cache before the prompt is sent, and A.2 step 5 requires the dedicated assessor's `assessment.json`. Neither check is a diagnosis: the cause is still unknown.

### Learn documentation against plugin 1.1.612

**Owner decision:** requirement 11b uses only the Upgrade agent in the GitHub Copilot app, as in [Upgrade a .NET app with GitHub Copilot upgrade](https://learn.microsoft.com/en-us/dotnet/core/porting/github-copilot-upgrade/dotnet-how-to-upgrade-with-github-copilot). Where Learn (the overview and the how-to, both updated 2026-09-25) and the installed plugin disagree, the run follows the plugin:

| Topic | Learn | Plugin 1.1.612 | Effect on this run |
|---|---|---|---|
| Artifact folder | `.github/upgrades/{scenarioId}` | `.github/upgrades/scenarios/{scenarioId}` | The prompt and protocol use the plugin's path |
| Confirmed options | Saved to `upgrade-options.md` | The `dotnet-version-upgrade` scenario's `planning.md`: "Do not write an options file. There is no upgrade-options.md." | Don't expect or check for `upgrade-options.md` |
| Azure migration | The overview points Azure migration to the modernization agent | `azure-migrate` only hands off to `start_app_mod_migration_session`, which needs the modernization extension | **Owner decision**, as in 11a: all seven tasks, including the Azure ones, run through the Upgrade agent in `dotnet-version-upgrade` |
| Starting in the app | Choose **Upgrade** in the agent picker | `upgrade.agent.md` notes the Upgrade tools can be dropped on a session's first turn while the MCP server starts | The first redo session stopped at the prompt's new tools guard: `get_state` and `initialize_scenario` were unavailable on the first turn |

### Questions this run answers

| Question | Attempt 1 | Attempt 2 |
|---|---|---|
| Does the plugin install from the README's deep link, from `/plugin`, or both? Is a restart needed? | Not recorded | |
| Does `start_task` run in the Copilot app? In VS Code it needed the Local harness for MCP sampling (report finding 51) | Yes, in the same session; no harness split | |
| Is there an equivalent of the Upgrade dashboard, or is the run chat-only? | Yes: the dashboard renders in the app (Overview, Assessment, Plan, Execution and Activity tabs) | |
| Do the `dotnet-version-upgrade` routing, Guided flow and commit strategy behave as in VS Code? | Routing yes. Guided flow paused at the assessment and plan gates (VS Code ran both in one go). Commit strategy defaulted to **After Each Task** with branch sync **Auto (Merge)**, not Manual | |
| Does the app's session or branch handling clash with the agent's? | The default session is a worktree under `.copilot\repos\copilot-worktrees\`, not `C:\src`; the work has to be pushed from there | |
| How do you export a conversation? | Not recorded (a short note was committed instead) | |
| Do the .NET analysis tools load? | Not recorded | First stage 2: **no**, silently; the generic Assessor wrote `assessment.md` by hand and the run was voided. Redo after the clean reinstall: **no tools at all**, not even `get_state` or `initialize_scenario` after the first turn; paused |

### Stages

| Stage | Covered by the Upgrade agent? | Time | Model | Prompts | Interventions | Build / run | Live check |
|---|---|---|---|---|---|---|---|
| A.1 Set up | — | | — | — | | — | — |
| A.2 Assess and plan (7 tasks, 9 rules) | | | Claude Opus 5.5 | Refined prompt plus addendum | | — | Rules table: |
| A.3.1 .NET 10 upgrade | | | Claude Sonnet 5.5 | | | | Pages against `10.10.n.4`: |
| A.3.2 SQL Managed Instance | | | Claude Sonnet 5.5 | | | | Development pages; Production with a SQL login refuses to start: |
| A.3.3 Blob | | | Claude Sonnet 5.5 | | | | Upload lands in `teaching-materials` and shows through the app: |
| A.3.4 Service Bus | | | Claude Sonnet 5.5 | | | | Send and receive (`/Notifications/GetNotifications`): |
| A.3.5 Key Vault | | | Claude Sonnet 5.5 | | | | Connection string from Key Vault; refuses to start outside Development without `KeyVault:VaultUri` or with a SQL login: |
| A.3.6 OpenTelemetry | | | Claude Sonnet 5.5 | | | | Starts without a connection string; requests, dependencies and logs in Application Insights: |
| A.3.7 CVE fixes | | | Claude Sonnet 5.5 | | | | `dotnet list package --vulnerable`: |
| **Total** | | | | | | | |

## Attempt 1 (2026-09-30): abandoned

Branch `spike/b06-upgrade-app`, stopped at `6372965` (the stage 2 plan). Models GPT-6 Sol at Medium and GPT-6 Luna at maximum, the refined prompt without an addendum, the app's default worktree session. The owner abandoned it during task 01 and restarted from scratch. What it showed:

- **The OData skill's gate stopped task 01.** The plan kept `#skill:migrating-webapi-odata`, and its compatibility gate returned STOP before any code change: the notification JSON endpoints had an unknown consumer inventory and no API contract tests. The VS Code comparison had removed the skill from its plan.
- **Different scenario defaults from VS Code.** Commit strategy **After Each Task** with branch sync **Auto (Merge)**, instead of Manual.
- **An unplanned task split.** After the retry, the workflow's own reviewer split task 01 into 01.01 (upload path hardening, implemented) and 01.02 (the notification transport, left for the owner).
- **A process-local queue.** The reviewer flagged the interim in-process notification queue as non-durable, and the agent asked whether to move Service Bus into task 01.
- **LocalDB fallback in validation.** The SQL user secret wasn't set for the worktree's project, so the page checks fell back to LocalDB and failed.
- **Out-of-scope checks.** The agent ran the kit's PowerShell preflight and tried `npm test`.
- **About 50,000 local file changes, never pushed**, and a long runtime before the owner paused it.
- **Interventions:** answering the OData gate, and the pause.

The attempt 2 addendum answers each of these up front.

| Stage | Result |
|---|---|
| A.1 Set up | `f0b2927` (a chat note only; the stage 1 commit body kept placeholders for the app and plugin versions); The session opened as a worktree, not a branch session on `C:\src` |
| A.2 Assess and plan (7 tasks, 9 rules) | ✅ `dotnet-version-upgrade`, in the app's worktree session (`6372965`); About 5 h wall-clock (06:04–11:09 UTC, including the two Guided gates and any pauses); GPT-6 Sol, Medium; The refined prompt fetched from origin; the owner approved the assessment gate, then the plan gate; **None**: the plan was approved as is; 0 application files changed; no `.vs` folder committed; the diff stays in `.github/upgrades/` and the chats, with no secrets; Rules: all met. Seven tasks in a strict chain; SQL Managed Instance only (Azure SQL Database excluded); Blob only (no Azure Files); `DefaultAzureCredential` and `Authentication=Active Directory Default`; one `UseAzureMonitor()`; Key Vault mandatory outside Development; SDK container publishing with no Dockerfile; `privatelink` names and Dockerfiles appear only as prohibitions. Task 01 again references `#skill:migrating-webapi-odata`, framed as a behavior-preservation gate; the owner accepted it, where the VS Code comparison had removed it |
| A.3.1 .NET 10 upgrade | First attempt **blocked** by the `#skill:migrating-webapi-odata` gate (unknown consumers of the notification JSON endpoints, no API contract tests). The retry did the upgrade, then the workflow's own reviewer split the task into 01.01 (upload path hardening, implemented) and 01.02 (the notification transport, needs an owner decision). **Paused by the owner; nothing committed yet**; Long; not yet measurable; GPT-6 Luna, maximum, same session as the plan; `start_task` for task 01, then retries; **2 so far**: answering the OData gate, and pausing the run to diagnose more than 50,000 changed files before any commit. Pending: the 01.02 decision. The agent also ran the kit's PowerShell preflight and tried `npm test`, which aren't part of the app; SDK-style `net10.0`, `wwwroot`, SDK container publishing, notification routes and JSON shape preserved, 0 warnings (agent's report). The reviewer flagged a non-durable in-process notification queue, and a path-traversal risk in the Courses upload, which it hardened; Pages against `10.10.n.4`: **failed**, because the app fell back to LocalDB: the SQL user secret wasn't set for the worktree's project |

## Three-way side by side

The Copilot app column is attempt 2. It isn't like for like with the VS Code comparison on models (Claude Opus 5.5 and Sonnet 5.5 against GPT-6 Sol and Luna) or on the prompt (the addendum).

| Stage | `modernize` in VS Code (run 1) | Upgrade agent in VS Code (`spike/b06-upgrade-compare`) | Upgrade agent in the Copilot app (attempt 2, `spike/b06-upgrade-app-v2`) |
|---|---|---|---|
| Set up and harness | VS Code; prompt files needed the Local harness, the dashboard the Copilot harness | Planning in the Copilot harness, tasks only in Local (MCP sampling) | |
| Assess and plan | Custom assessment, then `/create-modernization-plan` with the kit rules; a finished plan can't be revised | Refined prompt met all 9 rules; revised its plan when asked | |
| .NET 10 upgrade | Work stashed by the next task's branch switch, restored by hand | First time, no intervention | |
| SQL Managed Instance | On an `appmod/*` branch | One `continue`; Entra-only enforced at startup | |
| Blob | Stale-tracker retry | First time, no intervention | |
| Service Bus | Receive bug, one hand fix | First time, no intervention | |
| Key Vault | Delegation blocked three ways; direct prompt worked | First time, no intervention; Key Vault only outside Development | |
| OpenTelemetry | Startup crash, one hand fix; edited `docs/prd.md` | No intervention; telemetry in Application Insights with Entra | |
| CVE fixes | Nothing to fix | Verified no-op | |
| Interventions in total | 2 code fixes, 2 git recoveries | 1 `continue`, 0 code fixes | |
| Models | GPT-6 Sol and Luna (older prompt) | GPT-6 Sol and Luna | Claude Opus 5.5 and Sonnet 5.5 |

## Recommendation

**Not at this point.** The comparison is paused (owner decision, 2026-10-01) because the Upgrade MCP server exposed no tools in the Copilot app after a clean reinstall, so it gives no evidence for offering the GitHub Copilot app on the dev VM. Which extensions or plugins and which host the dev VM offers is decided from the VS Code comparison and run 2; the owner decides, and B04's install list isn't changed until then.
