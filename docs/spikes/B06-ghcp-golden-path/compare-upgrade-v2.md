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
| Models | **Claude Opus 5.5 at Medium** to assess and plan (owner decision, 2026-10-01; 11a used GPT-6 Sol at Medium, so stage 2 isn't like for like on the model), GPT-6 Luna at maximum to execute |
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
| Harness | **Local** for every stage |
| Head | `2bbe048` (stage 1) |

| Stage | Commit | Time | Model | Prompts | Interventions | Build / run | Live check |
|---|---|---|---|---|---|---|---|
| 1 Set up | `2bbe048` | | — | — | | — | — |
| 2 Assess and plan (7 tasks, 9 rules) | | | Claude Opus 5.5, Medium | Prompt plus addendum | | — | Rules table; `assessment.json` and `dependencies-health.json`: |
| 3.1 .NET 10 upgrade | | | GPT-6 Luna, maximum | | | | Pages against `10.10.n.4`: |
| 3.2 SQL Managed Instance | | | GPT-6 Luna, maximum | | | | Development pages; Production with a SQL login refuses to start: |
| 3.3 Blob | | | GPT-6 Luna, maximum | | | | Upload lands in `teaching-materials` and shows through the app: |
| 3.4 Service Bus | | | GPT-6 Luna, maximum | | | | Send and receive: |
| 3.5 Key Vault | | | GPT-6 Luna, maximum | | | | Key Vault read and both refusals to start: |
| 3.6 OpenTelemetry | | | GPT-6 Luna, maximum | | | | Starts without a connection string; telemetry in Application Insights: |
| 3.7 CVE fixes | | | GPT-6 Luna, maximum | | | | `dotnet list package --vulnerable`: |
| **Total** | | | | | | | |

## Harness result

| Question | Result |
|---|---|
| Does planning run in the Copilot harness with model access allowed? | Yes (v2, `b49ce4b`) |
| Does planning run in the Local harness? | (v3) |
| Does `start_task` run in the Copilot harness? | **No** (v2, `859d4ed`): couldn't parse `plan.md`, internal LLM client unavailable, also after a reload |
| Does `start_task` run in the Local harness? | (v3) |
| Finding 51 confirmed, or revised? | **Confirmed** on 1.1.612 |

## Against 11a

| Stage | 11a (`spike/b06-upgrade-compare`) | v2 (Copilot harness) | v3 (Local harness) |
|---|---|---|---|
| Harness for planning | Copilot | Copilot | Local |
| Harness for tasks | Local only, after `start_task` failed in Copilot | `start_task` failed in Copilot (`859d4ed`) | Local |
| Assessment | Tool-based | Tool-based, with `assessment.json` and `dependencies-health.json` | |
| Interventions | 1 `continue`, 0 code fixes | 0 (stage 2) | |
| Upgrade agent version | 1.1.596 | 1.1.612 | 1.1.612 |
| Planning model | GPT-6 Sol, Medium | Claude Opus 5.5, Medium | Claude Opus 5.5, Medium |
