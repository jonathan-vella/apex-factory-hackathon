# B06 run 1 results

Filled in by the executor after run 1 is pushed, from `spike/b06-run1`: times from the commit timestamps (a step starts at the previous commit), models and prompts from the chat exports in `chats/`, what changed from the diff of each commit, interventions from the commit message bodies, versions from `run1-versions.txt`, and build/run results from the executor's checks. A model missing from the exports is marked *not recorded*; premium requests are *not visible* unless the owner reported them. Times are local, `HH:MM`. **Run 1 timings count from the commit `run1: reset for a fresh start in the Local harness`.** Everything before it (the Agent Host harness and the **Create Plan** button, from 07:38 UTC) is a false start: it's in the report's findings, not in the step times.

| Field | Value |
|---|---|
| Date | |
| Branch | `spike/b06-run1` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| Protocol version | v1 |
| VS Code | |
| GitHub Copilot Chat | |
| GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) | |
| C# Dev Kit | |
| .NET SDK (`dotnet --version`) | |
| Copilot CLI (optional section) | |

## Steps

| Step | Start | End | Model and agent | Prompts | What Copilot changed | Interventions (manual fixes) | Build / run | Premium requests |
|---|---|---|---|---|---|---|---|---|
| 1 Set up | | | — | — | — | | — | — |
| 2 C3 assess | | | | | | | | |
| 3 C6 upgrade to .NET 10 | | | | | | | | |
| 4.1 Database with managed identity | | | | | | | | |
| 4.2 Uploads to Blob | | | | | | | | |
| 4.3 MSMQ to Service Bus | | | | | | | | |
| 4.4 Secrets to Key Vault | | | | | | | | |
| 5 Gaps: Global.asax and bundling | | | | | | | | |
| 5 Gaps: NotificationService to DI | | | | | | | | |
| 5 Gaps: Trace to OpenTelemetry | | | | | | | | |
| 5 Gaps: `site.css` case | | | | | | | | |
| 6 Package | | | | | | | | |
| Optional: step 2 with Copilot CLI | | | | | | | | |
| **Total** | | | | | | | | |

## Checks on `vm-dev01`

| Check | Result |
|---|---|
| Home, Students, Courses, Instructors and Departments pages work against `10.10.n.4` | ✅ 2026-09-25, after task 002, on .NET 10 with SQL auth from user secrets. To re-check after the last task |
| A teaching-material upload lands in the `teaching-materials` container | ✅ 2026-09-25, after task 003: `course_1045_<guid>.png` (`image/png`, 1403 bytes) via **Courses** > **Edit**, over the private endpoint with `AzureCliCredential` |
| A notification goes onto the `notifications` queue and the app reads it back | ✅ with 1 intervention. After task 004, send worked (`activeMessageCount` 2) but receive failed (`TimeSpan.Zero` wait time). After the owner's fix (2-second wait, `ILogger`), `/Notifications/GetNotifications` returned `success: true` with 4 notifications (1 CREATE, 3 UPDATE) |

## Notes

Anything else: surprises, where the time went, what a skill or instruction could have avoided.
