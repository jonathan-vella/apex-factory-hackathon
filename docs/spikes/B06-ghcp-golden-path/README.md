# B06 spike: GHCP golden path on the dev VM

| Field | Value |
|---|---|
| Date | In progress (started 2026-09-24) |
| Result | Pending: set after run 2 |
| Region | swedencentral |
| Versions | .NET 10 SDK `10.0.401`; GitHub Copilot modernization `1.24.26091501` (marketplace, 2026-09-24); GitHub Copilot upgrade `1.1.539` (marketplace, 2026-09-24); VS Code `1.139.0` on `vm-dev01`. Versions used in each run are in [run1.md](run1.md) and [run2.md](run2.md) |

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

Pending.

## Decisions

None yet.

## Evidence

- [assessment/](assessment/): the saved assessment reports per run.
- [run1.md](run1.md) and [run2.md](run2.md): the owner's results sheets.

## Follow-ups

Pending.
