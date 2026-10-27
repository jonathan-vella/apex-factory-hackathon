# B19: Build the teardown stage and the identity finalizer

| Field      | Value                                           |
| ---------- | ----------------------------------------------- |
| Issue      | #127                                            |
| Milestone  | P6 Platform automation                          |
| Type       | Both                                            |
| Depends on | B18                                             |
| Unblocks   | B20                                             |
| Effort     | 2–3 days elapsed                                |
| Cost       | Ends the hourly cost of B17 and B18             |
| Teardown   | This item is the teardown                       |
| PRD        | §6 Platform pipeline; §8 pipeline identity risk |

## Outcome

- `platform.yml` stage `teardown` removes the test lab's resources, and the admin finalizer removes the pipeline identity. Nothing is left except the empty subscriptions.

## Before you start

1. B18 is closed (issue #126). The owner approved the teardown, naming the PR number.

## Requirements

1. A `teardown` stage in `platform.yml` (gated): `Remove-FactoryEnvironment.ps1 -Scope Member` for every member in the roster, one after another, then `-Scope Team`, run by the pipeline identity while it still holds its roles. A member's own pipeline (B21) can tear down that member's datacenter and identity the same way. The order is fixed: every member first, then the team.
2. The CI lab also removes `rg-management` and `id-sqlmi-directory`, which the team teardown keeps on purpose for a normal lab. Add an explicit option for this, off by default.
3. The admin then runs `Remove-PlatformPipeline.ps1` (a separate principal): roles, credential, identity, `rg-cicd`, environment variables, secret and environment. It verifies each is gone. The identity can't reliably remove its own roles, so the workflow never tries.
4. Return the subscriptions to Tenant Root and delete the sandbox group (the admin does it, with a query to confirm).
5. Verify with queries (resource groups, role assignments, policy assignments, exemptions, budgets, management groups, identity, credential, environment) and put the results in the PR.

## Deliverables

- The `teardown` stage in `platform.yml` (there is no separate `platform-teardown.yml`: every job lives in `platform.yml`); changes to `scripts/Remove-FactoryEnvironment.ps1` (option) and `scripts/Remove-PlatformPipeline.ps1`; evidence in the PR body.

## Verify

- Each artifact query returns nothing. `actionlint`, PSScriptAnalyzer and `npm run check` pass.

## Done when

- [ ] Nothing is left in the test lab except the subscriptions.
- [ ] The finalizer verified its own result.

## Commit message

```text
feat: add the platform teardown stage and identity finalizer
```

## Stop and ask if

- Something would be deleted that the pipeline didn't create.

## Notes and traps

- Don't remove the identity's roles before the teardown run finishes.
- The Graph grant is manual and may need to be removed by hand.
