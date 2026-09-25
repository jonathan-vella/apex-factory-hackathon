# B06 run 1 results

Filled in by the executor from `spike/b06-run1`: times from the commit timestamps (a step starts at the previous commit), models and prompts from the chat texts in `chats/` and the owner's reports, what changed from the diff of each commit, interventions from the commit bodies and the owner's reports, versions from `run1-versions.txt`, and build and run results from the executor's checks and the owner's live checks. A model the owner didn't report is marked *not recorded*; premium requests are *not visible*. Times are local (UTC+2), `HH:MM`. **Run 1's step times count from the reset commit `1a88898` (11:03).** Everything before it, 09:38 to 11:03, was a false start (the Agent Host harness, the default assessment and **Create Plan**, prompt files): it's in the report's findings 4–14, not in the step times.

| Field | Value |
|---|---|
| Date | 2026-09-25 |
| Branch | `spike/b06-run1`, head `0c35abc` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| Protocol version | v1, changed during the run into v2 |
| VS Code | 1.139.0 |
| GitHub Copilot Chat | not recorded |
| GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) | 1.24.0 |
| C# Dev Kit | 3.40.210 |
| .NET SDK (`dotnet --version`) | 10.0.401 (executor's build check on `vm-dev01`; not in `run1-versions.txt`) |
| Copilot CLI (optional section) | not tried |

## Steps

| Step | Start | End | Model and agent | Prompts | What Copilot changed | Interventions (manual fixes) | Build / run | Premium requests |
|---|---|---|---|---|---|---|---|---|
| 1 Set up | — | 09:38 | — | — | — | Fresh clone; the 2026-09-24 manual assessment was lost | — | — |
| False start | 09:38 | 11:03 | Extension default; `modernize` with GPT-6 Sol | Default assessment, **Create Plan**, correction reply, prompt files, skills (`chats/run1-step3-plan.txt`) | Plans that missed the upgrade and kept both alternatives; discarded | Reset (`1a88898`) | — | not visible |
| 2 C3 assess | 11:03 | 11:32 | Extension default, not selectable (dashboard, Local harness) | Custom assessment, target App Service for Linux (containers); other options not recorded | Assessment report (`assessment/run1/`) | None | — | not visible |
| 3 Plan | 11:32 | 11:43 | `modernize`, GPT-6 Sol, Medium | `/create-modernization-plan` with the 7 kit rules (`chats/run1-step3-plan-v2.txt`) | `tasks.json` 001–006 in one chain; all 7 rules met first time; the **Create Plan** output discarded (`f467e72`) | None | — | not visible |
| 3 Task 001: .NET 10 upgrade | 11:43 | 12:42 | `modernize`, GPT-6 Luna, maximum | `Execute the modernization plan in .github/modernize/contoso-university-dotnet10-azure, starting with task 001.` after two blocked attempts in the planning chat | SDK-style `net10.0` project, `Program.cs`, `appsettings*.json`; `Global.asax`, `App_Start`, `Web.config`, `packages.config` deleted; MSMQ swapped for a temporary in-process queue (64 files) | Task output stashed by the next task's branch switch; restored by hand (git) | Build passed (agent) | not visible |
| 4.1 Task 002: SQL Managed Instance | 12:42 | 12:56 | `modernize`, GPT-6 Luna, maximum | `Execute task 002 of the plan in …` (new chat) | Checked-in LocalDB connection string removed; `README.md`, `SETUP_TESTING_GUIDE.md` updated; local SQL auth kept (committed by the tool on an `appmod/*` branch) | None | Release build passed; five pages ✅ against `10.10.1.4` | not visible |
| 4.2 Task 003: Blob | 12:56 | 13:33 | `modernize`, GPT-6 Luna, maximum | `Execute task 003 …`, then **Retry** after a stale tracker | `BlobServiceClient` with `DefaultAzureCredential`, `Storage:*` keys, images streamed from a private container (12 files); not committed by the tool | None | Release build 0 warnings; upload ✅ | not visible |
| 4.3 Task 004: Service Bus | 13:33 | 16:19 | `modernize`, GPT-6 Luna, maximum; fix with the default Agent, GPT-6 Luna | `Execute task 004 …`; fix prompt (2-second wait, `ILogger`) | `ServiceBusClient` with `DefaultAzureCredential`, `ServiceBus:*` keys (10 files, tool commit); fix in `NotificationService` and `NotificationsController` | **1**: receive called `ReceiveMessagesAsync` with `TimeSpan.Zero` and always failed | Build passed; send ✅, receive ❌, then ✅ after the fix | not visible |
| 4.4 Task 005: Key Vault | 16:19 | 17:34 | `modernize`, GPT-6 Luna, maximum | Direct: `Implement task 005-transform-keyvault-configuration from tasks.json … work directly: don't delegate, don't initialize a scenario, don't re-plan` after three blocked attempts | `Azure.Extensions.AspNetCore.Configuration.Secrets`, conditional `AddAzureKeyVault` (3 files). The commit body says "default Agent"; the owner confirmed `modernize` | None | 0 warnings, 0 errors; Key Vault ✅ | not visible |
| 3 Task 006: CVE fixes | 17:34 | about 17:52 | `modernize`, GPT-6 Luna, maximum | Direct prompt, as for task 005 | Nothing: no vulnerable packages. The NuGet safe-version planner crashed (tool bug) | None | Build clean | not visible |
| 5 Gaps: Global.asax and bundling | — | — | — | — | Done in task 001 | None | ✅ | — |
| 5 Gaps: NotificationService to DI | — | — | — | — | Done in tasks 001 and 004 (factory registration in `Program.cs`) | None | ✅ | — |
| 5 Gaps: Trace to OpenTelemetry | about 17:52 | 18:23 | `modernize`, GPT-6 Luna, maximum; fix model not recorded | Predefined task **Migrate Logging or Observability to OpenTelemetry on Azure**; fix prompt (Azure Monitor only when a connection string is set) | Azure Monitor OpenTelemetry, `ILogger` for `Trace` and `Debug` (11 files, tool commit on `appmod/*`); also edited `docs/prd.md` | **2**: the app crashed at startup without `APPLICATIONINSIGHTS_CONNECTION_STRING`. Also reverted the `docs/prd.md` edit (`71f9d4a`) | ❌ startup, then ✅ after the fix | not visible |
| 5 Gaps: `site.css` case | — | — | — | — | Consistent after task 001 (`wwwroot/Content/Site.css`, `~/Content/Site.css`) | None | ✅ | — |
| 6 Package | 18:23 | about 18:26 | — (commands, protocol step 6) | — | Image `contoso-university:run1` in `cruni<suffix>b06` (no repo changes) | None | Tag ✅ | — |
| Optional: step 2 with Copilot CLI | — | — | — | — | Not tried | — | — | — |
| **Total** | 11:03 | about 18:26 | | | | **2** code fixes; plus 2 git recoveries (stash restore, `docs/prd.md` revert) | | not visible |

Run 1 took about 7 h 23 min from the reset, or 8 h 48 min from the first commit. Against the event time boxes: C3 (1 hour) took 29 minutes after the reset, and C6 (3 hours) took about 6 h 54 min of wall-clock time. That includes the blocked execution attempts, the two fixes, the live checks and any breaks, which the commits don't separate.

## Checks on `vm-dev01`

| Check | Result |
|---|---|
| `dotnet build` on the .NET 10 SDK | ✅ Executor, 2026-09-25, a clean clone of `0c35abc` in `C:\LabTools\b06-check` (deleted afterwards): SDK 10.0.401, `dotnet build -c Release`, 0 warnings, 0 errors |
| No references to `System.Web`, `System.Messaging` or MSMQ | ✅ Executor: `git grep` on `app/ContosoUniversity` at `0c35abc` finds none |
| The image exists in the registry | ✅ The owner's `az acr repository show-tags` on `vm-dev01`: `run1`. The executor's control-plane check: `cruni<suffix>b06` has 127 MB stored (data-plane calls are blocked outside the VNet) |
| No secrets in the diff | ✅ Executor: the added lines from `da4e5f6` to `0c35abc` hold no subscription or tenant IDs, passwords, keys, SAS tokens or GitHub tokens. The only GUID is the project's `UserSecretsId`, a local folder ID. `appsettings.json` has no connection strings |
| Home, Students, Courses, Instructors and Departments pages work against `10.10.n.4` | ✅ 2026-09-25, after task 002, on .NET 10 with SQL auth from user secrets; Home and Students again after step 5 |
| A teaching-material upload lands in the `teaching-materials` container | ✅ 2026-09-25, after task 003: `course_1045_<guid>.png` (`image/png`, 1403 bytes) via **Courses** > **Edit**, over the private endpoint with `AzureCliCredential` |
| The app reads its connection string from Key Vault (`KeyVault:VaultUri`, user secret removed) | ✅ 2026-09-25, after task 005 |
| The app starts without `APPLICATIONINSIGHTS_CONNECTION_STRING` after the OpenTelemetry task | ❌ 2026-09-25, after step 5.3: crashes at startup ("A connection string was not found", `Program.cs` line 100), because Azure Monitor is registered unconditionally. ✅ after the owner's fix (intervention 2, `0c35abc`): Azure Monitor only when a connection string is set, console exporters otherwise; the app starts and the pages work |
| A notification goes onto the `notifications` queue and the app reads it back | ✅ with 1 intervention. After task 004, send worked (`activeMessageCount` 2) but receive failed (`TimeSpan.Zero` wait time). After the owner's fix (2-second wait, `ILogger`), `/Notifications/GetNotifications` returned `success: true` with 4 notifications (1 CREATE, 3 UPDATE) |

## Notes

- **Where the time went:** the false start (85 minutes) and the execution routine. The `modernize` agent's plan and execution delegation blocked tasks 001, 003 and 005 (sub-agent depth, stale trackers, its own handoff record, a lost scenario, a phantom "another agent"). Direct per-task prompts worked every time.
- **What a skill or instruction could have avoided:** the default assessment's Windows target, **Create Plan**'s missing upgrade and double alternatives, the Service Bus receive bug and the unconditional Azure Monitor registration. Both code bugs passed the agent's own validation, because it never starts the app.
- The chat texts for tasks 001–006 and step 5 weren't exported; prompts come from the owner's reports.
