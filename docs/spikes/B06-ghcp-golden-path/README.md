# B06 spike: GHCP golden path on the dev VM

| Field | Value |
|---|---|
| Date | In progress (started 2026-09-24) |
| Result | Pending: set after run 2 |
| Region | swedencentral |
| Versions | .NET 10 SDK `10.0.401`; GitHub Copilot modernization `1.24.26091501` (marketplace, 2026-09-24); VS Code `1.139.0` on `vm-dev01`. Versions used in each run are in [run1.md](run1.md) and [run2.md](run2.md) |

## Question

Is there a repeatable sequence of GitHub Copilot steps and prompts that takes Contoso University from .NET Framework 4.8 to .NET 10, with uploads on Blob, MSMQ replaced by Service Bus, secrets in Key Vault and OpenTelemetry, running on `vm-dev01` against the source database and packaged as an image in a private ACR, within the C3 (1 hour) and C6 (3 hours) time boxes?

## What we did

1. Deployed the spike services private-only into `rg-spike-b06` with [infra/main.bicep](infra/main.bicep): Storage `stuni<suffix>b06` (container `teaching-materials`), Service Bus Premium `sbns-uni-<suffix>-b06` (queue `notifications`), ACR Premium `cruni<suffix>b06` and Key Vault `kv-uni-<suffix>-b06`. Private endpoints are in `snet-pe-spike` (`10.10.n.128/27`) of `vnet-datacenter`, created by [infra/modules/subnet.bicep](infra/modules/subnet.bicep), and the four private DNS zones in `rg-spike-b06` are linked to `vnet-datacenter`. The owner has Storage Blob Data Contributor, Azure Service Bus Data Sender and Receiver, AcrPush and Key Vault Secrets Officer.
2. Checked from `vm-dev01` with a run command that every hostname resolves to `snet-pe-spike` and that TCP 443 (and 5671 for Service Bus) connects.
3. The owner ran the [protocol](protocol.md) twice, on the branches `spike/b06-run1` and `spike/b06-run2`, committing after each step with manual fixes in the commit body, a chat export per step in `chats/` and the tool versions in `runN-versions.txt`. The executor filled in [run1.md](run1.md) and [run2.md](run2.md) from those: times from the commit timestamps, models and prompts from the exports, changes from the diff of each commit.
4. The executor checked each run branch: `dotnet build` on the .NET 10 SDK, no `System.Web`, `System.Messaging` or MSMQ references, the image tag in the registry and no secrets in the diff.

## Timings

Pending.

## Findings

Run 1, steps 1 (set up) and 2 (assess):

1. **Managed identity trap on `vm-dev01`.** The VM has a system-assigned managed identity, and `DefaultAzureCredential` tries `ManagedIdentityCredential` before `AzureCliCredential`. The app would get the VM's token, which has no data roles, and fail with 403 on Blob, Service Bus and Key Vault. Fix: set the user environment variable `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` on `vm-dev01` only ([Credential chains in the Azure Identity library for .NET](https://learn.microsoft.com/dotnet/azure/sdk/authentication/credential-chains)); the deployed app still uses its managed identity. The owner kept the data roles on the user rather than giving them to the VM identity. In protocol v2, step 1.3.
2. **No git identity for a fresh VM user.** The first commit fails with `Author identity unknown`. Fix: right after `gh auth login`, set `user.name` and a GitHub no-reply `user.email` from `gh api user`, and run `gh auth setup-git` so `git push` uses the gh sign-in. In protocol v2, step 1.2.
3. **Sign-in through Bastion.** Browser sign-in inside the Bastion session is awkward, and passkeys and password managers don't work there. Fix: device code flows (`az login --use-device-code`, and `gh auth login --web` with the code entered at `github.com/login/device`), completed on the attendee's own device. Some tenants block device code flow with Conditional Access. In protocol v2, step 1.2.
4. **The assessment dashboard has no chat and no model picker.** Step 2 ran from the dashboard, so there's no chat export and the model is the extension's default. In protocol v2, recording only asks for chat exports where the owner prompted in Copilot Chat.
5. **The report targets App Service for Windows by default.** The target dropdown defaults to **Azure App Service (Windows)**; the kit targets App Service for Linux (containers) (PRD §2, B09). It has to be switched before **Create Plan**, or the plan targets Windows. The owner re-planned with Linux. In protocol v2, step 2.3; a candidate for a B10 instruction.
6. **Create Plan covers only Cloud Readiness.** **Create Plan (6)** planned the six Cloud Readiness issues: static content, SQL connection, Windows authentication (Mandatory), connection strings, local IO and MSMQ (Mandatory). It did **not** include the .NET 10 upgrade: run 1's first plan (`.github/modernize/ContosoUniversity-20260925073922/plan.md`, commit `7904c1b`) says "No … runtime/framework upgrade", so the upgrade has to be requested explicitly. That's a hot spot for protocol v2 and the B10 playbook. The plan also included **Windows AD to Microsoft Entra ID**; its open questions were Blob or Files and SQL Database or Managed Instance, which the kit answers (Blob, Managed Instance); and its integration verification defaulted to mock mode because no Azure environment was given. The owner sent a correction reply: upgrade first, remove Entra ID, Blob, Managed Instance with local SQL auth kept, order database, Blob, Service Bus, Key Vault, `DefaultAzureCredential` with no keys, App Service for Linux containers, no provisioning. In protocol v2, steps 2.5, 3.2 and 3.3.
7. **False "Windows authentication detected" (Mandatory).** The app has no user sign-in (`BaseController` uses `"System"`, and `FilterConfig` has no `AuthorizeAttribute`). The finding comes only from `<IISExpressWindowsAuthentication>enabled</IISExpressWindowsAuthentication>` (with anonymous authentication disabled) in `ContosoUniversity.csproj` and `Integrated Security=True` in the LocalDB connection string in `Web.config`. It's not applicable, but the first plan included an Entra ID migration for it. The owner removed it. A B10 instruction should say so. In protocol v2, deselect it before **Create Plan** (step 2.4) or remove it in the correction reply (step 3.2).
8. **Planning model:** the plan ran with the `modernize` agent, GPT-6 Sol at reasoning effort Medium (2026-09-25).
9. **"Projects: 1 error"** in the C# Dev Kit status bar on the legacy .NET Framework project before the upgrade is expected.
10. **Create Plan abandoned for the prompt files.** Run 1's first **Create Plan** attempt and its correction chat were stopped. The owner copied `.github/prompts` from the working branch onto `spike/b06-run1` and continued with `/modernize-plan` and `/modernize-execute`, so run 1 also uses the pinned agent and models. Reasoning effort is set in the model picker: Medium for GPT-6 Sol, maximum for GPT-6 Luna.
11. **`reasoning-effort` breaks prompt files.** A `reasoning-effort:` line in the prompt-file frontmatter stopped both prompt files from working in VS Code on `vm-dev01`. The owner removed it (`spike/b06-run1` commit `4508c6d`), and reasoning effort is set in the model picker instead: Sol Medium, Luna maximum.
12. **Slash command didn't run the prompt file.** Typing `/modernize-plan` in chat didn't work; opening the prompt file and selecting **▶ Run Prompt** (or **Chat: Run Prompt**) did. Protocol v2 makes **Run Prompt** the primary way, with the slash command as the alternative.

The rest is pending run 1.

Note: the owner's hand-run assessment from 2026-09-24 was lost with the old clone before run 1, so it isn't in [assessment/](assessment/). Run 1 started from a fresh clone.

## Decisions

- **Pinned agent and model for run 2 (owner-approved, 2026-09-25).** Two VS Code prompt files, `.github/prompts/modernize-plan.prompt.md` (agent `modernize`, model `GPT-6 Sol (copilot)`) and `.github/prompts/modernize-execute.prompt.md` (agent `modernize`, model `GPT-6 Luna (copilot)`), replace **Create Plan** and the correction reply. This changes [B06](../../backlog/B06-spike-ghcp.md) requirement 7, which no longer leaves the model unpinned for plan and execution. It conflicts with PRD §2 **Copilot models** ("No model is pinned"), which the PRD owner has to reconcile: see Follow-ups. The model uses the list form with the picker's full name. `reasoning-effort` isn't a supported prompt-file field, as [Use prompt files in VS Code](https://code.visualstudio.com/docs/agent-customization/prompt-files) implies by not listing it (checked 2026-09-25), so reasoning effort is set in the model picker: Sol Medium, Luna maximum.

## Evidence

- [assessment/](assessment/): the saved assessment reports per run.
- [pe-probe.md](pe-probe.md): the private-endpoint probe from `vm-dev01` and the deployed settings.
- [run1.md](run1.md) and [run2.md](run2.md): the results sheets, filled in by the executor from the run branches.
- `chats/` and `runN-versions.txt` on the run branches: the chat exports per step (checked for secrets) and the tool versions.

## Follow-ups

- **B10: ship the prompt files as agent skills.** VS Code says prompt files are deprecated for Agent Host sessions and aren't loaded there. They still work with the Local agent, which will be removed in a future release, and VS Code offers a migration to agent skills ([Use prompt files in VS Code](https://code.visualstudio.com/docs/agent-customization/prompt-files)). B10 should ship `modernize-plan` and `modernize-execute` as skills.
- **PRD §2 Copilot models:** it says no model is pinned, but the spike's prompt files pin one per phase. Decide whether the kit pins models in its prompt files or skills (B10) and update the PRD row.
- **B11 attendee guides:** sign in on `vm-dev01` with device code flows (`az login --use-device-code`, `gh auth login --web` with the code at `github.com/login/device`), completed on the attendee's own device, and say that some tenants block device code flow with Conditional Access. After `az login`, the attendee picks their own workload subscription (the one that holds `rg-datacenter`) in the subscription picker and checks it with `az account show --query name -o tsv`; guides never hard-code a subscription. Right after `gh auth login`, set the git identity from the GitHub account with the no-reply email (`<id>+<login>@users.noreply.github.com`) and run `gh auth setup-git`, because a fresh VM user has no git identity and the first commit fails with `Author identity unknown`.

The rest is pending the runs.
