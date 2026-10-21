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

- `platform.yml` deploys the member's datacenter, tests it, onboards Arc, vends the member and tests connectivity, all from Actions.

## Before you start

1. B17 is closed (issue #125). The foundation is deployed under `mg-factory-ci`.
2. The owner approved this item's Azure deployment, naming the PR number.

## Requirements

1. `platform-member.yml`: `Deploy-Datacenter.ps1` with `-Repository ${{ github.repository }}` and `-ScriptsRef ${{ github.sha }}`, then `Test-Datacenter.ps1`, then `Connect-DatacenterArc.ps1`. No datacenter job runs after Arc on the same member.
2. `platform-vending.yml`: `Deploy-Vending.ps1` (with the member object ID and budget email from the roster, `max-parallel: 1`), a VM restart, `New-DatacenterExemptions.ps1`, then `Test-Connectivity.ps1`. A datacenter redeploy requires a vending re-run; the workflow says so.
3. Check each script under the managed identity (Arc, exemptions, connectivity). Fix what breaks, and record what can't run unattended.
4. The guard runs first in every job. IDs are masked in job summaries.
5. `platform.yml` stage `all` runs foundation, member and vending in order, with the reviewer gate on foundation and vending.

## Deliverables

- `.github/workflows/platform-member.yml`, `platform-vending.yml`, `platform.yml` changes, script fixes the identity needs.
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
