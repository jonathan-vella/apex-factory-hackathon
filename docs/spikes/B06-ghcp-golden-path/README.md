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
3. The owner ran the [protocol](protocol.md) twice, recording [run1.md](run1.md) and [run2.md](run2.md), on the branches `spike/b06-run1` and `spike/b06-run2`.
4. The executor checked each run branch: `dotnet build` on the .NET 10 SDK, no `System.Web`, `System.Messaging` or MSMQ references, the image tag in the registry and no secrets in the diff.

## Timings

Pending.

## Findings

Run 1, step 1 (set up), found before any Copilot step:

1. **Managed identity trap on `vm-dev01`.** The VM has a system-assigned managed identity, and `DefaultAzureCredential` tries `ManagedIdentityCredential` before `AzureCliCredential`. The app would get the VM's token, which has no data roles, and fail with 403 on Blob, Service Bus and Key Vault. Fix: set the user environment variable `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` on `vm-dev01` only ([Credential chains in the Azure Identity library for .NET](https://learn.microsoft.com/dotnet/azure/sdk/authentication/credential-chains)); the deployed app still uses its managed identity. The owner kept the data roles on the user rather than giving them to the VM identity. In protocol v2, step 1.3.
2. **Sign-in through Bastion.** Browser sign-in inside the Bastion session is awkward, and passkeys and password managers don't work there. Fix: device code flows (`az login --use-device-code`, and `gh auth login --web` with the code entered at `github.com/login/device`), completed on the attendee's own device. Some tenants block device code flow with Conditional Access. In protocol v2, step 1.2.

The rest is pending run 1.

## Decisions

None yet.

## Evidence

- [assessment/](assessment/): the saved assessment reports per run.
- [pe-probe.md](pe-probe.md): the private-endpoint probe from `vm-dev01` and the deployed settings.
- [run1.md](run1.md) and [run2.md](run2.md): the owner's results sheets.

## Follow-ups

- **B11 attendee guides:** sign in on `vm-dev01` with device code flows (`az login --use-device-code`, `gh auth login --web` with the code at `github.com/login/device`), completed on the attendee's own device, and say that some tenants block device code flow with Conditional Access. After `az login`, the attendee picks their own workload subscription (the one that holds `rg-datacenter`) in the subscription picker and checks it with `az account show --query name -o tsv`; guides never hard-code a subscription.

The rest is pending the runs.
