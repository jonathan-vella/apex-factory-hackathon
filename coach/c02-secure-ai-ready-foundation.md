# C2 answer key: Secure, AI-ready foundation

> [!WARNING]
> Coach material. This page has the answers to C2. The team lead runs the team's landing zone from GitHub Actions; the kit scripts are only for a coach's repair.

This is a "verify and explain" challenge. The team lead deployed ALZ-lite at T-7 and vended every member at T-1, so nothing deploys on Day 1. The team lead needed elevated rights (Owner at Tenant Root scope) for that work, which most members don't have: confirm at T-14 that the right person is driving, and at T-7 that the Privileged Role Administrator is booked. Your job on Day 1 is to ask the questions below and check that the team can answer them in their own words, not read from the output.

## Expected evidence

- Evidence of the `foundation` stage from T-7 (the run summary, GUIDs redacted as `<id:abcd>`, counts as the `Deploy-AlzLite.ps1` output): management groups (`mg-factory` under Tenant Root, with `mg-factory-platform` and `mg-factory-corp`), the hub (`vnet-hub`, `afw-hub`, `afwp-hub` in `rg-hub`), the central Log Analytics workspace, and the core policies assigned at `mg-factory-corp`.
- `Grant-SqlMiDirectoryRead.ps1` output from T-7: the three Graph permissions granted to `id-sqlmi-directory`, and the `-WhatIf` check from task 4 that says they are already granted. Without the grant C7's `CREATE USER ... FROM EXTERNAL PROVIDER` fails, and only a Privileged Role Administrator can run it. No pipeline runs it.
- Evidence of the `vending` stage from T-1 for every member's workload subscription (the run summary counts as the `Deploy-Vending.ps1`, exemptions and `Test-Connectivity.ps1` output): spoke VNet, subnets, peering to the hub, UDRs pointing at the firewall, DNS pointing at the hub firewall (which acts as the DNS proxy), RBAC and a budget. The run log redacts GUIDs, but check the copy in the member's own repo (`factory/evidence/c02/`) names none. Vending keeps a member's existing direct Owner assignment; it only adds one when the member has none.
- The exemptions table, with an owner, a reason and an expiry per exemption (the datacenter predates the policy move, so it needs exemptions, not fixes). The owner is a person, or `GitHub Actions pipeline` for the `vending` stage's exemptions: in that case check the C4 deferred-work register names a person. An empty list on Day 1 usually means the policies hadn't taken effect when vending ran (up to 30 minutes): ask the member to create them as task 6 says.
- `Test-Connectivity.ps1` from task 7: PASS on every applicable check, run by the member from their own dev container (it probes inside the VMs through Azure).

## Questions to ask

Ask the questions at fixed points, because members are in C3 from 10:15 (the agenda doesn't change). The members' questions go in a 10 minute slot at 11:15, when C3 ends, the members have done tasks 6 and 7, and C4 doesn't start until 11:45. Ask each question of a different person. Let the team lead answer only what no one else can; the lead's walk-through of tasks 3 to 5 happens earlier, from 10:15. Answers in the team's own words are enough; the model answers are short on purpose.

1. Which core policies only audit, which deny, and which add a missing setting? (Audit: allowed locations and resource location matching the resource group. Deny: a public IP on a NIC, and public network access on Storage, Key Vault, Service Bus, the container registry and SQL MI. DeployIfNotExists: private DNS zone registration for Blob, Service Bus, the container registry and Key Vault, and diagnostics to the central workspace.)
2. What would the Deny on public network access stop in C5, and what would the member do instead? (A public backend: it uses a private endpoint in `snet-pe`.)
3. Why does the hub firewall answer DNS? (DNS proxy: the VMs resolve the private names of Azure services through the central private DNS zones.)
4. Why does the datacenter have exemptions and not fixes? Who owns them, and what happens at expiry? (It was deployed before the subscription moved under `mg-factory-corp`; it's an on-premises simulation that migrates in C7. The owner records the deferred work, and it goes into C4's register.)
5. Why did vending come after the datacenter and after `vm-dev01` setup? (Vending connects the datacenter, so it has to exist; vending changes its DNS to the firewall, which `vm-dev01` setup doesn't test.)
6. What would a full portal ALZ have that ALZ-lite leaves out? (The comparison table in the ALZ-lite guide: more management groups, more landing zone archetypes, the full policy initiative set, paid Defender plans, ExpressRoute or VPN gateways.)
7. Why does C7 need the Graph grant, and who can make it? (SQL MI uses `id-sqlmi-directory` to look up Entra principals for `CREATE USER ... FROM EXTERNAL PROVIDER`; a Privileged Role Administrator or Global Administrator.)

## Model answer

Before the event, in the team lead's repo (each stage needs an approval once):

1. T-7, team lead: `gh workflow run platform.yml -f stage=foundation` (ALZ-lite, about 15 to 25 minutes). `-f stage=whatif` previews it.
2. T-7, a Privileged Role Administrator, once per team, outside the pipeline: `./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId`. Values come from each person's `.local/settings.json` (`$s`).
3. T-1, team lead, after the coach approves the readiness records (see the [readiness gate](readiness.md)): `gh workflow run platform.yml -f stage=vending`. It vends every member in the roster, one after another (yourself included), restarts both VMs of every member (tell members first: a restart ends their Bastion session), records the exemptions with a real reason ("deployed before ALZ-lite; pending retirement after the event") and a real expiry, and runs the connectivity probes. Add `-f members=<n>,<n>` to vend only some members, for example one whose datacenter was redeployed.

On Day 1:

4. Every member, against their own workload subscription: list the exemptions (task 6) and re-run `./scripts/Test-Connectivity.ps1 -SubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex`. It runs from the dev container and probes inside the VMs. This is a challenge task, so students run it themselves.

### Repair (coaches only)

Use this only when a stage run can't be repaired in time (rerun the stage first: the stages are idempotent). A coach runs the same scripts by hand, in this order. Students don't run them:

```powershell
./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location
./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId <member-subscription-id> -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <n> -MemberPrincipalId <member-object-id> -BudgetEmail <member-email> -Location $s.location
az vm restart -g rg-datacenter -n vm-dev01 --subscription <member-subscription-id>
az vm restart -g rg-datacenter -n vm-app01 --subscription <member-subscription-id>
./scripts/New-DatacenterExemptions.ps1 -SubscriptionId <member-subscription-id> -Owner '<name>'
./scripts/Test-Connectivity.ps1 -SubscriptionId <member-subscription-id> -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <n>
```

- Run `Deploy-Vending.ps1`, the restarts, the exemptions and the connectivity test once per member, after ALZ-lite and after that member's datacenter and approved readiness record. Take the other members' values from the roster the team lead keeps privately (captured at T-14).
- Never rerun Arc, and never redeploy a datacenter after Arc. A datacenter redeployed after vending requires vending again.

## Common mistakes

- Vending before ALZ-lite finished propagating (management group moves can lag a few minutes) — vending then can't find the hub by name. Wait and retry rather than debugging a "missing resource."
- Vending a member before their datacenter exists or before the coach approves their readiness record: vending can't connect a datacenter that isn't there, and a datacenter redeployed after vending loses the DNS and route settings, so that member is vended again.
- A member with their own elevated rights running the `foundation` stage a second time "to be sure" — this is the team lead's job, once, for the whole team. Running it twice doesn't break anything but wastes time.
- Skipping exemptions because "the datacenter already works" — the point is to record the exception deliberately, not to silence the alert. A dismissed policy finding with no exemption record is a gap in C10's AI-readiness register.
- Not restarting `vm-app01`/`vm-dev01` after vending changes DNS — connectivity tests then fail for a reason unrelated to the actual foundation (see the troubleshooting hint on the challenge page).
- Reading out the T-7 and T-1 output without being able to explain it. The evidence only counts when the team can answer the questions above.

## Partial credit

- ALZ-lite and vending evidence complete, but exemptions missing owner/expiry: partial credit, fix before C10's checklist.
- Evidence complete, but the team lead alone answers the policy questions and the members can't explain the exemptions: partial credit on the matching row, then ask the members again after C3.
- Connectivity tests mostly pass with one explained, coach-acknowledged FAIL (for example, a probe that depends on a resource not yet deployed until C5): accept as complete, with the FAIL noted.

## Bonus

Running the negative tests from the foundation's validation record (`infra/foundation/validation.md`: a public-network container registry denied, a NIC with a public IP denied, a private endpoint auto-registers in central DNS) is worth up to 5 bonus points if the team records the actual denial messages, not just "it worked." The public storage account test isn't a reliable one: in a tenant with a "disable public network access" Modify policy the account is created private instead of denied.

## Reset

Rerun the failed stage with the same inputs: the `foundation` and `vending` stages are idempotent and converge a failed or partial deployment. Then check the exemptions and connectivity again (the `vending` stage re-records both). Redeploying a datacenter after vending drops the DNS and route settings vending applied, so if a member's datacenter must be redeployed (the `member` stage, before Arc only), run the `vending` stage for that member again afterwards. The scripts in the Repair block have no `-Force` parameter either.
