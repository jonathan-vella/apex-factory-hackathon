# C2 answer key: Secure, AI-ready foundation

> [!WARNING]
> Coach material. This page has the answers to C2. Attendees run the team's landing zone themselves with the kit scripts.

This is a "verify and explain" challenge. The platform lead deployed ALZ-lite at T-7 and vended every member at T-1, so nothing deploys on Day 1. The platform lead needed elevated rights (Owner at Tenant Root scope) for that work, which most members don't have: confirm at T-14 that the right person is driving, and at T-7 that the Privileged Role Administrator is booked. Your job on Day 1 is to ask the questions below and check that the team can answer them in their own words, not read from the output.

## Expected evidence

- `Deploy-AlzLite.ps1` output from T-7 (or the pipeline's `foundation` stage summary): management groups (`mg-factory` under Tenant Root, with `mg-factory-platform` and `mg-factory-corp`), the hub (`vnet-hub`, `afw-hub`, `afwp-hub` in `rg-hub`), the central Log Analytics workspace, and the core policies assigned at `mg-factory-corp`.
- `Grant-SqlMiDirectoryRead.ps1` output from T-7: the three Graph permissions granted to `id-sqlmi-directory`, and the `-WhatIf` check from task 4 that says they are already granted. Without the grant C7's `CREATE USER ... FROM EXTERNAL PROVIDER` fails, and only a Privileged Role Administrator can run it.
- `Deploy-Vending.ps1` output from T-1 for every member's workload subscription: spoke VNet, subnets, peering to the hub, UDRs pointing at the firewall, DNS pointing at the hub firewall (which acts as the DNS proxy), RBAC and a budget. The output names subscription IDs, so check the copy in the member's own repo (`factory/evidence/c02/`) is redacted.
- The exemptions table, with an owner, a reason and an expiry per exemption (the datacenter predates the policy move, so it needs exemptions, not fixes). The owner is a person, or `GitHub Actions pipeline` if the team used the pipeline: in that case check the C4 deferred-work register names a person. An empty list on Day 1 usually means the policies hadn't taken effect when vending ran (up to 30 minutes): ask the member to create them as task 6 says.
- `Test-Connectivity.ps1` from task 7: PASS on every applicable check, run by the member from their own dev container (it probes inside the VMs through Azure).

## Questions to ask

Ask the questions at fixed points, because members are in C3 from 10:15 (the agenda doesn't change). The members' questions go in a 10 minute slot at 11:15, when C3 ends, the members have done tasks 6 and 7, and C4 doesn't start until 11:45. Ask each question of a different person. Let the platform lead answer only what no one else can; the lead's walk-through of tasks 3 to 5 happens earlier, from 10:15. Answers in the team's own words are enough; the model answers are short on purpose.

1. Which core policies only audit, which deny, and which add a missing setting? (Audit: allowed locations and resource location matching the resource group. Deny: a public IP on a NIC, and public network access on Storage, Key Vault, Service Bus, the container registry and SQL MI. DeployIfNotExists: private DNS zone registration for Blob, Service Bus, the container registry and Key Vault, and diagnostics to the central workspace.)
2. What would the Deny on public network access stop in C5, and what would the member do instead? (A public backend: it uses a private endpoint in `snet-pe`.)
3. Why does the hub firewall answer DNS? (DNS proxy: the VMs resolve the private names of Azure services through the central private DNS zones.)
4. Why does the datacenter have exemptions and not fixes? Who owns them, and what happens at expiry? (It was deployed before the subscription moved under `mg-factory-corp`; it's an on-premises simulation that migrates in C7. The owner records the deferred work, and it goes into C4's register.)
5. Why did vending come after the datacenter and after `vm-dev01` setup? (Vending connects the datacenter, so it has to exist; vending changes its DNS to the firewall, which `vm-dev01` setup doesn't test.)
6. What would a full portal ALZ have that ALZ-lite leaves out? (The comparison table in the ALZ-lite guide: more management groups, more landing zone archetypes, the full policy initiative set, paid Defender plans, ExpressRoute or VPN gateways.)
7. Why does C7 need the Graph grant, and who can make it? (SQL MI uses `id-sqlmi-directory` to look up Entra principals for `CREATE USER ... FROM EXTERNAL PROVIDER`; a Privileged Role Administrator or Global Administrator.)

## Model answer

Values come from each person's `.local/settings.json` (`$s`); the platform lead takes the other members' IDs from the roster the event owner captured at T-14. Before the event:

1. T-7, platform lead: `./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location`.
2. T-7, a Privileged Role Administrator, once per team: `./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId`.
3. T-1, platform lead, once per member (including themselves), after the coach's C0 review: `./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId <member-subscription-id> -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <n> -MemberPrincipalId <member-object-id> -BudgetEmail <member-email> -Location $s.location`.
4. T-1, platform lead, for each member: restart both VMs with `az vm restart -g rg-datacenter -n vm-dev01 --subscription <member-subscription-id>` and the same with `-n vm-app01` (tell the member first: a restart ends their Bastion session), then `./scripts/New-DatacenterExemptions.ps1 -SubscriptionId <member-subscription-id> -Owner '<name>'` — exemptions should name a real reason ("deployed before ALZ-lite; pending retirement after the event") and a real expiry (the event's end date is fine for a lab) — then `./scripts/Test-Connectivity.ps1 -SubscriptionId <member-subscription-id> -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <n>`. The pipeline's `vending` stage does the same in one run. Students' preferred path is [Deploy with GitHub Actions](https://factory.apexops.pro/guides/deploy-with-actions/); the scripts stay supported.

On Day 1:

5. Every member, against their own workload subscription: list the exemptions (task 6) and re-run `./scripts/Test-Connectivity.ps1 -SubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex`. It runs from the dev container and probes inside the VMs.

## Common mistakes

- Vending before ALZ-lite finished propagating (management group moves can lag a few minutes) — vending then can't find the hub by name. Wait and retry rather than debugging a "missing resource."
- Vending a member before their datacenter exists or before the coach's C0 review: vending can't connect a datacenter that isn't there, and a datacenter redeployed after vending loses the DNS and route settings, so that member is vended again.
- A member with their own elevated rights running `Deploy-AlzLite.ps1` a second time "to be sure" — this is the platform lead's job, once, for the whole team. Running it twice doesn't break anything but wastes time.
- Skipping exemptions because "the datacenter already works" — the point is to record the exception deliberately, not to silence the alert. A dismissed policy finding with no exemption record is a gap in C10's AI-readiness register.
- Not restarting `vm-app01`/`vm-dev01` after vending changes DNS — connectivity tests then fail for a reason unrelated to the actual foundation (see the troubleshooting hint on the challenge page).
- Reading out the T-7 and T-1 output without being able to explain it. The evidence only counts when the team can answer the questions above.

## Partial credit

- ALZ-lite and vending evidence complete, but exemptions missing owner/expiry: partial credit, fix before C10's checklist.
- Evidence complete, but the platform lead alone answers the policy questions and the members can't explain the exemptions: partial credit on the matching row, then ask the members again after C3.
- Connectivity tests mostly pass with one explained, coach-acknowledged FAIL (for example, a probe that depends on a resource not yet deployed until C5): accept as complete, with the FAIL noted.

## Bonus

Running the negative tests from the foundation's validation record (`infra/foundation/validation.md`: a public-network container registry denied, a NIC with a public IP denied, a private endpoint auto-registers in central DNS) is worth up to 5 bonus points if the team records the actual denial messages, not just "it worked." The public storage account test isn't a reliable one: in a tenant with a "disable public network access" Modify policy the account is created private instead of denied.

## Reset

There is no `-Force` parameter on these scripts. `Deploy-AlzLite.ps1` and `Deploy-Vending.ps1` are idempotent: run them again with the same parameters to converge a failed or partial deployment, then re-run exemptions and connectivity. Re-running `Deploy-Datacenter.ps1` after vending drops the DNS and route settings vending applied, so if a member's datacenter must be redeployed, vend that member again afterwards.
