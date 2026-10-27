# B18: Build the member and vending stages

| Field      | Value                                                                                                                              |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Issue      | #126                                                                                                                               |
| Milestone  | P6 Platform automation                                                                                                             |
| Type       | Both                                                                                                                               |
| Depends on | B17                                                                                                                                |
| Unblocks   | B19                                                                                                                                |
| Effort     | 3–5 days elapsed                                                                                                                   |
| Cost       | About $1.55/hour for the datacenter plus about $1.30/hour for the foundation while deployed (list prices, Azure Hybrid Benefit on) |
| Teardown   | B19 removes everything                                                                                                             |
| PRD        | §6 Platform pipeline                                                                                                               |

## Outcome

- `platform.yml` follows the event order: it deploys the member's datacenter, tests it and onboards Arc (pre-work, T-3); deploys ALZ-lite (day 1); then vends the member and tests connectivity. All from Actions.

## Before you start

1. B17 is closed (issue #125). The identity, `gh-lab` and the sandbox group exist. The foundation may already be deployed: the member stage doesn't depend on it, because the workload subscription isn't under the kit's groups until vending.
2. The owner approved this item's Azure deployment, naming the PR number.

## Requirements

1. The `member` stage runs for each member index in a job matrix (parallel, at most five at a time): `Deploy-Datacenter.ps1` with `-Repository` and `-ScriptsRef` set to the **public kit** (`KIT_REPOSITORY` and `KIT_REF`, which `Import-Kit.ps1` pins in an attendee's repo, because the kit is under `factory/` there and the repo may be private), then `Test-Datacenter.ps1`, then `Connect-DatacenterArc.ps1`, with a fresh OIDC login before each long step. It refuses to run when `vm-app01` is already an Arc machine, because a redeploy can't recover it. The `Test-Datacenter` output goes to the job summary.
2. The `vending` stage is one job that vends every member in the roster strictly one at a time (`scripts/Invoke-PipelineVending.ps1`, one approval for the stage). For each member it runs the guard, logs in again with a fresh OIDC token, checks that the datacenter exists, then runs `Deploy-Vending.ps1` (with the member object ID and budget email from the roster), restarts both VMs, runs `New-DatacenterExemptions.ps1` and `Test-Connectivity.ps1`. It stops at the first failure and says which member. A datacenter redeploy requires vending again; the summary says so.
3. A team has **one shared services subscription and one workload subscription per member**. The roster (`ROSTER_JSON`) lists every member (index, subscription, object ID, budget address), `Initialize-PlatformPipeline.ps1 -RosterPath` validates it (1 to 20 unique indexes, unique subscriptions, none equal to the shared one) and the guard allowlist holds the shared subscription plus every member's. `platform.yml` takes a `members` input (default: the `MEMBER_INDEXES` variable) and a `preflight` matrix runs `Test-Preflight` per member.
4. Check each script under the managed identity (Arc, exemptions, connectivity). Fix what breaks, and record what can't run unattended.
5. The guard runs in every session. IDs, the member's object ID and the budget address are masked.
6. `platform.yml` stage `all` runs what-if, foundation, member and vending in that order (the event order, see B22), with the reviewer gate on each. Run alone, the stages are independent: the strategy decides who runs which (see B21 and B22).

## Deliverables

- `.github/workflows/platform.yml` (the `member` and `vending` jobs), the session action's roster outputs, `scripts/Invoke-PipelineVending.ps1`, roster support in `Initialize-PlatformPipeline.ps1` and `Test-PipelineSetup.ps1`, `Import-Kit.ps1` pinning `KIT_REPOSITORY` and `KIT_REF`, script fixes the identity needs.
- Evidence in the PR body: run URLs, times, results of the tests, cost.

## Verify

- `Test-Datacenter` and `Test-Connectivity` pass from Actions.
- `actionlint`, PSScriptAnalyzer and `npm run check` pass.

## Done when

- [ ] The stages run end to end in the test lab.
- [ ] Anything that can't run under a managed identity is listed.

## Commit message

```text
feat: add the platform member and vending stages
```

## Stop and ask if

- A script needs a user sign-in to work.
- A tenant policy denies a deployment.

## Notes and traps

- Parallel vending writes to the single `afwp-hub` policy. It is untested with one workload subscription, so keep `max-parallel: 1`.
- Arc's portal assessment and the Graph grant stay manual.
