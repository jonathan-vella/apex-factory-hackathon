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

1. The `member` stage: `Deploy-Datacenter.ps1` with `-Repository ${{ github.repository }}` and `-ScriptsRef ${{ github.sha }}`, then `Test-Datacenter.ps1`, then `Connect-DatacenterArc.ps1`, with a fresh OIDC login before each long step. It refuses to run when `vm-app01` is already an Arc machine, because a redeploy can't recover it.
2. The `vending` stage: `Deploy-Vending.ps1` (with the member object ID and budget email from the roster; one member at a time), a VM restart, `New-DatacenterExemptions.ps1`, then `Test-Connectivity.ps1`. A datacenter redeploy requires a vending re-run; the summary says so.
3. Check each script under the managed identity (Arc, exemptions, connectivity). Fix what breaks, and record what can't run unattended.
4. The guard runs in every session. IDs, the member's object ID and the budget address are masked.
5. `platform.yml` stage `all` runs what-if, member, foundation and vending in that order, with the reviewer gate on each.

## Deliverables

- `.github/workflows/platform.yml` (the `member` and `vending` jobs), the session action's roster outputs, script fixes the identity needs.
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
