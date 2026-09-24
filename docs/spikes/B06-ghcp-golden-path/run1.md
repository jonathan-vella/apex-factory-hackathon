# B06 run 1 results

Filled in by the owner during run 1 of the [protocol](protocol.md). One row per step. Times are local, `HH:MM`.

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
| Home, Students, Courses, Instructors and Departments pages work against `10.10.n.4` | |
| A teaching-material upload lands in the `teaching-materials` container | |
| A notification goes onto the `notifications` queue and the app reads it back | |

## Notes

Anything else: surprises, where the time went, what a skill or instruction could have avoided.
