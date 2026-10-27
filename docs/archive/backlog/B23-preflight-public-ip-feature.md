# B23: Preflight checks the public IP feature on new subscriptions

| Field | Value |
|---|---|
| Issue | #136 |
| Milestone | P6 Platform automation |
| Type | Agent |
| Depends on | — |
| Unblocks | — |
| Effort | 1 day elapsed |
| Cost | None |
| Teardown | None |
| PRD | §8 Risks |

## Outcome

`Test-Preflight.ps1` finds a missing `Microsoft.Network/AllowBringYourOwnPublicIpAddress` feature before a deployment fails on it, and `-Fix` registers it.

## Why

A new subscription in the test lab failed ALZ-lite with `SubscriptionNotRegisteredForFeature` when it created `pip-afw-hub`. The owner's older subscription already had the feature. Attendees' new partner subscriptions can hit the same wall at the Day 1 or T-7 deploy, and the datacenter's NAT and Bastion public IPs need it too.

## Requirements

1. Add a row to `Test-Preflight.ps1` for each subscription it checks: the feature is `Registered`, or FAIL with the fix.
2. `-Fix` registers the feature, then re-registers `Microsoft.Network` so it propagates, and waits like the provider registration does.
3. Add scenarios to `test/Test-Preflight.Tests.ps1` (registered, not registered, registration pending) using the fake Azure CLI.
4. Add a troubleshooting entry (`SubscriptionNotRegisteredForFeature`) and mention it in the preflight section of the C0 page.

## Deliverables

- `scripts/Test-Preflight.ps1`, `test/Test-Preflight.Tests.ps1`, `site/src/content/docs/reference/troubleshooting.md`, the C0 page.

## Verify

- `./test/Test-Preflight.Tests.ps1`, PSScriptAnalyzer and `npm run check` pass.

## Done when

- [ ] A subscription without the feature gets a FAIL and a working `-Fix`.

## Commit message

```text
feat: check the public IP feature in preflight
```

## Stop and ask if

- Registering the feature needs approval in a tenant (it is normally automatic).

## Notes and traps

- The feature is per subscription: check the workload and the shared subscription.
