# B06 comparison: GitHub Copilot upgrade vs GitHub Copilot modernization

The .NET Framework 4.8 → .NET 10 upgrade done twice from the same start commit (`da4e5f6`): once by the `modernize` agent as run 1's task 001, and once by the **Upgrade** agent from GitHub Copilot upgrade. The executor fills this in from `spike/b06-upgrade-compare` and the chat export, as for the run sheets. Protocol: [Comparison: GitHub Copilot upgrade](protocol.md#comparison-github-copilot-upgrade-after-run-1-before-run-2).

| Field | Value |
|---|---|
| Date | |
| Branch | `spike/b06-upgrade-compare` |
| Start commit | `da4e5f606983332001c94ce69b48634f9c1864b3` |
| GitHub Copilot upgrade (`ms-dotnettools.upgrade-agent`) | |
| GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) | |
| Agent, model and reasoning effort | Upgrade, GPT-6 Luna, maximum |

## Upgrade agent run

| Item | Result |
|---|---|
| Time (start to end) | |
| Prompts | |
| Interventions (manual fixes) | |
| `dotnet build` | |
| Runs against `10.10.n.4`: home, Students, Courses, Instructors, Departments | |
| What changed (files added, deleted, changed) | |

## Side by side

| Aspect | `modernize` agent (run 1, task 001, `0dccd8e`) | Upgrade agent (`spike/b06-upgrade-compare`) |
|---|---|---|
| How it was started | New chat after `/create-modernization-plan`; task 001 had no skill attached | |
| Time | | |
| Interventions | Uncommitted output stashed by the next task's branch switch, restored by hand (finding 29) | |
| Project file | SDK-style, `net10.0` | |
| `Program.cs` and configuration | `Program.cs` with `AddDbContext<SchoolContext>`, `appsettings.json` and `appsettings.Development.json`, `ConnectionStrings:DefaultConnection` required | |
| Removed | `Global.asax`, `Global.asax.cs`, `Web.config`, `Views/Web.config`, `packages.config` | |
| MSMQ | Replaced with a temporary in-process queue for task 004 (finding 34) | |
| Build | Passed (agent report) | |
| Runs against `10.10.n.4` | ✅ five pages, after task 002 | |
| Other differences | | |

## `modernize` with the upgrade extension installed

Whether the `modernize` agent behaves differently in run 2 with `ms-dotnettools.upgrade-agent` installed: does the plan include the upgrade without being told, and is task 001 handed to the Upgrade agent?

| Observation | Result |
|---|---|
| Plan includes the upgrade without rule 1 | |
| Task 001 handed to the Upgrade agent | |
| Other | |

## Recommendation

Which extension or extensions the kit's dev VM should install, for the owner to decide. B04's extension list isn't changed until then.
