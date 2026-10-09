# C2 answer key: Secure, AI-ready foundation

> [!WARNING]
> Coach material. This page has the answers to C2. Attendees run the team's landing zone themselves with the kit scripts.

This is the first challenge where the platform lead needs elevated rights (Owner at Tenant Root scope) that most members don't have — confirm the right person is driving before the 120-minute clock starts.

## Expected evidence

- `Deploy-AlzLite.ps1` output: management groups (`mg-factory`, `mg-factory-corp`, `mg-factory-landing-zones` or equivalent), the hub (`vnet-hub`, `afw-hub`, `afwp-hub` in `rg-hub`), the central Log Analytics workspace, and the core policies assigned at `mg-factory-corp`.
- `Deploy-Vending.ps1` output for every member's workload subscription: spoke VNet, subnets, peering to the hub, UDRs pointing at the firewall, DNS pointing at the hub's resolvers, RBAC and a budget.
- The exemptions table from `New-DatacenterExemptions.ps1`, with an owner, a reason and an expiry per exemption (the datacenter predates the policy move, so it needs exemptions, not fixes).
- `Test-Connectivity.ps1`: PASS on every applicable check, run from inside the datacenter.

## Model answer

1. Platform lead: `./scripts/Deploy-AlzLite.ps1`.
2. Platform lead, once per member: `./scripts/Deploy-Vending.ps1 -MemberIndex <n>`.
3. Platform lead or member: `./scripts/New-DatacenterExemptions.ps1 -MemberIndex <n>` — exemptions should name a real reason ("deployed before ALZ-lite; pending retirement after the event") and a real expiry (the event's end date is fine for a lab).
4. Member, from `vm-dev01` or `vm-app01`: `./scripts/Test-Connectivity.ps1`.

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

`./scripts/Deploy-AlzLite.ps1 -Force` and `./scripts/Deploy-Vending.ps1 -MemberIndex <n> -Force` redeploy cleanly; re-run exemptions and connectivity afterward.
