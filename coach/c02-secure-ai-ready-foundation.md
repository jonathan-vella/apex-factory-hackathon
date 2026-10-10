# C2 answer key: Secure, AI-ready foundation

> [!WARNING]
> Coach material. This page has the answers to C2. Attendees run the team's landing zone themselves with the kit scripts.

This is the first challenge where the platform lead needs elevated rights (Owner at Tenant Root scope) that most members don't have — confirm the right person is driving before the 120-minute clock starts.

## Expected evidence

- `Deploy-AlzLite.ps1` output: management groups (`mg-factory` under Tenant Root, with `mg-factory-platform` and `mg-factory-corp`), the hub (`vnet-hub`, `afw-hub`, `afwp-hub` in `rg-hub`), the central Log Analytics workspace, and the core policies assigned at `mg-factory-corp`.
- `Grant-SqlMiDirectoryRead.ps1` output: the three Graph permissions granted to `id-sqlmi-directory`. Without it C7's `CREATE USER ... FROM EXTERNAL PROVIDER` fails, and only a Privileged Role Administrator can run it, so check it was done on day one.
- `Deploy-Vending.ps1` output for every member's workload subscription: spoke VNet, subnets, peering to the hub, UDRs pointing at the firewall, DNS pointing at the hub's resolvers, RBAC and a budget.
- The exemptions table from `New-DatacenterExemptions.ps1`, with an owner, a reason and an expiry per exemption (the datacenter predates the policy move, so it needs exemptions, not fixes).
- `Test-Connectivity.ps1`: PASS on every applicable check, run from inside the datacenter.

## Model answer

Values come from each person's `.local/settings.json` (`$s`); the platform lead takes the other members' IDs from them.

1. Platform lead: `./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location`.
2. Platform lead with a Privileged Role Administrator, once per team: `./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId`.
3. Platform lead, once per member (including themselves): `./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId <member-subscription-id> -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <n> -MemberPrincipalId <member-object-id> -BudgetEmail <member-email> -Location $s.location`.
4. Every member, against their own workload subscription: `./scripts/New-DatacenterExemptions.ps1 -SubscriptionId $s.subscriptionId -Owner '<name>'` — exemptions should name a real reason ("deployed before ALZ-lite; pending retirement after the event") and a real expiry (the event's end date is fine for a lab).
5. Every member, after restarting both VMs: `./scripts/Test-Connectivity.ps1 -SubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex`. It runs from the dev container and probes inside the VMs.

## Common mistakes

- Running vending before ALZ-lite finishes propagating (management group moves can lag a few minutes) — vending then can't find the hub by name. Wait and retry rather than debugging a "missing resource."
- A member with their own elevated rights running `Deploy-AlzLite.ps1` a second time "to be sure" — this is the platform lead's job, once, for the whole team. Running it twice doesn't break anything but wastes time; redirect them to vending for their own subscription instead.
- Skipping exemptions because "the datacenter already works" — the point is to record the exception deliberately, not to silence the alert. A dismissed policy finding with no exemption record is a gap in C10's AI-readiness register.
- Not restarting `vm-app01`/`vm-dev01` after vending changes DNS — connectivity tests then fail for a reason unrelated to the actual foundation (see the troubleshooting hint on the challenge page).

## Partial credit

- ALZ-lite and vending complete, but exemptions missing owner/expiry: partial credit, fix before C10's checklist.
- Connectivity tests mostly pass with one explained, coach-acknowledged FAIL (for example, a probe that depends on a resource not yet deployed until C5): accept as complete, with the FAIL noted.

## Bonus

Running the negative tests from the B08 report (public storage denied, NIC with public IP denied, private endpoint auto-registers in central DNS) is worth up to 5 bonus points if the team records the actual denial messages, not just "it worked."

## Reset

There is no `-Force` parameter on these scripts. `Deploy-AlzLite.ps1` and `Deploy-Vending.ps1` are idempotent: run them again with the same parameters to converge a failed or partial deployment, then re-run exemptions and connectivity. Re-running `Deploy-Datacenter.ps1` after vending drops the DNS and route settings vending applied, so if a member's datacenter must be redeployed, vend that member again afterwards.
