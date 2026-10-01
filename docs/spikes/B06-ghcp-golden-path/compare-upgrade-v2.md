# B06 comparison rerun: GitHub Copilot upgrade in VS Code (11a rerun)

A from-scratch rerun of the VS Code comparison ([compare-upgrade.md](compare-upgrade.md)), at the owner's request (2026-10-01), to retest finding 51: in 11a, `start_task` failed in the **Copilot** harness with "internal LLM client unavailable" and ran only in **Local**. Here **Configure Model Access** is set before stage 2, and planning and tasks both stay in the Copilot harness. The executor fills this in from the run branch, its commits and the chat exports. Protocol: [11a rerun](protocol.md#11a-rerun-github-copilot-upgrade-in-vs-code).

| Field | Value |
|---|---|
| Date | 2026-10-01 (set-up) |
| Branch | `spike/b06-upgrade-compare-v2` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| GitHub Copilot upgrade (`ms-dotnettools.upgrade-agent`) | **1.1.612** (11a: 1.1.596) |
| GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) | 1.24.0, Disabled (Workspace) |
| Models | **Claude Opus 5.5 at Medium** to assess and plan (owner decision, 2026-10-01; 11a used GPT-6 Sol at Medium, so stage 2 isn't like for like on the model), GPT-6 Luna at maximum to execute |
| Prompt | `prompts/compare-upgrade-plan.md`, then `prompts/compare-upgrade-app-addendum.md` (11a used the prompt without the addendum) |
| Model access | Already set before stage 2: `chat.mcp.serverSampling` still had `"GitHub Copilot upgrade: Upgrade": { allowedDuringChat: true }` from 11a, so no change was needed |
| Head | `443c963` (stage 1 set up, pushed) |

## Harness result

| Question | Result |
|---|---|
| Does `start_task` run in the Copilot harness with model access configured first? | |
| Exact error, if it failed | |
| Harness each task ran in | |
| Finding 51 confirmed, or revised? | |

## Stages

| Stage | Harness | Time | Model | Prompts | Interventions | Build / run | Live check |
|---|---|---|---|---|---|---|---|
| 1 Set up (`443c963`) | — | | — | — | | — | — |
| 2 Assess and plan (7 tasks, 9 rules) | Copilot | | Claude Opus 5.5, Medium | Prompt plus addendum | | — | Rules table: |
| 3.1 .NET 10 upgrade | | | GPT-6 Luna, maximum | | | | Pages against `10.10.n.4`: |
| 3.2 SQL Managed Instance | | | GPT-6 Luna, maximum | | | | Development pages; Production with a SQL login refuses to start: |
| 3.3 Blob | | | GPT-6 Luna, maximum | | | | Upload lands in `teaching-materials` and shows through the app: |
| 3.4 Service Bus | | | GPT-6 Luna, maximum | | | | Send and receive: |
| 3.5 Key Vault | | | GPT-6 Luna, maximum | | | | Key Vault read and both refusals to start: |
| 3.6 OpenTelemetry | | | GPT-6 Luna, maximum | | | | Starts without a connection string; telemetry in Application Insights: |
| 3.7 CVE fixes | | | GPT-6 Luna, maximum | | | | `dotnet list package --vulnerable`: |
| **Total** | | | | | | | |

## Against 11a

| Stage | 11a (`spike/b06-upgrade-compare`) | Rerun (`spike/b06-upgrade-compare-v2`) |
|---|---|---|
| Harness for tasks | Local only, after `start_task` failed in Copilot | |
| Interventions | 1 `continue`, 0 code fixes | |
| Upgrade agent version | 1.1.596 | 1.1.612 |
| Planning model | GPT-6 Sol, Medium | Claude Opus 5.5, Medium |
