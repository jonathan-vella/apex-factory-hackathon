# B06 comparison in the GitHub Copilot app

The full Upgrade agent comparison repeated in the **GitHub Copilot app** instead of VS Code (requirement 11b, owner-approved 2026-09-29). Only the host changes: the same Upgrade agent (plugin `upgrade-agent@upgrade-agent-plugins` from [microsoft/upgrade-agent-plugins](https://github.com/microsoft/upgrade-agent-plugins)), the same refined seven-task prompt ([prompts/compare-upgrade-plan.md](prompts/compare-upgrade-plan.md)), models, kit rules, configuration keys and live checks as [compare-upgrade.md](compare-upgrade.md). The executor fills this in from `spike/b06-upgrade-app`, its commits and the saved conversations. Protocol: [Comparison: GitHub Copilot upgrade in the Copilot app](protocol.md#comparison-github-copilot-upgrade-in-the-copilot-app-after-the-vs-code-comparison-before-run-2).

| Field | Value |
|---|---|
| Date | |
| Branch | `spike/b06-upgrade-app` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| GitHub Copilot app | |
| `upgrade-agent` plugin | Marketplace version 1.1.596 (checked 2026-09-29); installed: |
| Other plugins | None (no modernization plugin) |
| Session type | Branch session on `C:\src\apex-factory-hackathon` (no worktree) |
| Models | GPT-6 Sol at Medium to assess and plan, GPT-6 Luna at maximum to execute |

## Questions this run answers

| Question | Answer |
|---|---|
| Does the plugin install from the README's deep link, from `/plugin`, or both? Is a restart needed? | |
| Does `start_task` run in the Copilot app? In VS Code it needed the Local harness for MCP sampling (report finding 51) | |
| Is there an equivalent of the Upgrade dashboard, or is the run chat-only? | |
| Do the `dotnet-version-upgrade` routing, Guided flow and Manual commit strategy behave as in VS Code? | |
| Does the app's session or branch handling clash with the agent's? | |
| How do you export a conversation? | |

## Stages

| Stage | Covered by the Upgrade agent? | Time | Model | Prompts | Interventions | Build / run | Live check |
|---|---|---|---|---|---|---|---|
| A.1 Set up | — | | — | — | | — | — |
| A.2 Assess and plan (7 tasks, 9 rules) | | | | | | — | Rules table: |
| A.3.1 .NET 10 upgrade | | | | | | | Pages against `10.10.n.4`: |
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
| Set up and harness | VS Code; prompt files needed the Local harness, the dashboard the Copilot harness | Planning in the Copilot harness, tasks only in Local (MCP sampling) | |
| Assess and plan | Custom assessment, then `/create-modernization-plan` with the kit rules; a finished plan can't be revised | Refined prompt met all 9 rules; revised its plan when asked | |
| .NET 10 upgrade | Work stashed by the next task's branch switch, restored by hand | First time, no intervention | |
| SQL Managed Instance | On an `appmod/*` branch | One `continue`; Entra-only enforced at startup | |
| Blob | Stale-tracker retry | First time, no intervention | |
| Service Bus | Receive bug, one hand fix | First time, no intervention | |
| Key Vault | Delegation blocked three ways; direct prompt worked | First time, no intervention; Key Vault only outside Development | |
| OpenTelemetry | Startup crash, one hand fix; edited `docs/prd.md` | | |
| CVE fixes | Nothing to fix | | |
| Interventions in total | 2 code fixes, 2 git recoveries | | |

## Recommendation

Which extensions or plugins, and which host (VS Code or the Copilot app), the kit's dev VM should offer, for the owner to decide. B04's install list isn't changed until then.
