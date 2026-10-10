# Facilitator guide

This guide is the run-of-show and decision reference for the event owner, coaches and platform lead. The
attendee challenges define the work; the [scoring rubric](scoring-rubric.md) is the single source of truth
for points.

## Roles

| Role | Owns |
|---|---|
| Event owner | Copy and brand the kit, set dates and region, build the roster and assign member indexes, confirm access and logistics, lock the roster, handle escalations, own cleanup and the final record |
| Coach | Give the live portal ALZ and APEX demos, review each member's C0 output at T-3, sign off evidence, hand out and apply lifelines, trigger and reverse the curveballs |
| Platform lead | Deploy ALZ-lite once for the team, vend each member subscription, coordinate policy exemptions and shared network changes. Also a student: does every member challenge on their own workload subscription |
| Member | Complete the individual challenges, review AI changes, keep evidence and run the app modernization work in their own repository |

## Timeline and gates

### T-30 to T-14: event owner

Attendees need the answers below before they can run preflight at T-14, so settle them first.

- Choose the event dates, team size (three to five members per team) and region (`swedencentral`; `germanywestcentral` is the fallback).
- Plan one Entra tenant per team, with one shared services subscription per team plus one workload subscription per member. The platform lead is also a member, so a team of five needs six subscriptions.
- Build the roster, kept in your private event channel and never in this public kit:

  | Name | GitHub handle | Team | Role | Member index | Workload subscription ID | Entra object ID | Budget email |
  |---|---|---|---|---|---|---|---|

  The platform lead collects the last four columns for every member in C2 (vending needs each member's subscription ID, index, object ID and email).
- Assign each member an index from 1 to 20 and tell them before T-14. `Initialize-Settings.ps1` asks for it and won't accept a value outside 1–20, and attendees are told to wait for the number rather than pick one. The index sets the member's address ranges (`10.10.n.0/24` for the datacenter, `10.20.n.0/24` for the spoke) and their peerings to the team's hub, so give every member of a team, the platform lead included, a different index. Don't confuse it with the six-character suffix that `Initialize-Settings.ps1` generates for resource names.
- Pick one platform lead per team. They need a shared services subscription and Owner at Tenant Root, which a Global Administrator grants after elevating access (see the [ALZ-lite guide](../site/src/content/docs/guides/alz-lite.md) and `infra/foundation/README.md`, "Permissions").
- Name one teammate per team to create the private team repo from `templates/team/` in the partner's GitHub org and add every teammate with Write access (steps in [C1](../site/src/content/docs/challenges/c01-define-the-opportunity.md)). Check that members can create private repos in the org.
- Give coaches read access to each member's private repo and to the team repo, so they can review evidence. Attendees keep their C5 and C6 work in their own repos.
- Assign GitHub Copilot seats and check the org policies allow agent mode, MCP servers and Copilot CLI.
- Book a Privileged Role Administrator (or Global Administrator) for each team for Day 1 around 10:15, right after ALZ-lite is deployed. They run `scripts/Grant-SqlMiDirectoryRead.ps1` once per team (see `infra/foundation/README.md`, "Event prep: SQL MI directory identity"). It can't happen earlier, because ALZ-lite creates `id-sqlmi-directory`, and C7 needs the grant.
- Decide the SQL MI start/stop schedule. It runs Monday to Friday, 07:30 to 18:30, `W. Europe Standard Time`, and applies only after cutover removes the link. For another time zone or for event days outside that window, change the `sqlMiSchedule*` parameters in `archetype/infra/bicep/university/main.bicep` before attendees deploy. Tell coaches that after cutover the MI can be stopped outside that window.
- Decide who owns the APEX demo subscription and its cleanup (see the [APEX demo](apex-demo.md)).

### T-14: event owner and platform lead

- Confirm each team has one shared-services subscription and each member has a separate workload subscription.
- Confirm the platform lead has the rights described in the [ALZ-lite guide](../site/src/content/docs/guides/alz-lite.md), including rights at Tenant Root to create management groups and move subscriptions.
- Confirm the Privileged Role Administrator for each team is booked for day one.
- Check member MFA, resource-provider registration, quota, Copilot policies and access to the APEX runtime. Do not put tenant, subscription or object IDs in this public kit.
- Confirm the attendees can use the approved Copilot features and extensions on the dev VM. Escalate organizational Copilot policy issues before the event.
- Confirm the draft roster and publish the agenda, room details and escalation channel. The roster stays open until kickoff, so you can still swap or drop a member who can't get ready.

### T-3: platform lead and members

- Run the member preflight, deploy the datacenter with Azure Hybrid Benefit on by default, confirm the legacy app with `scripts/Test-Datacenter.ps1` while both VMs are running, then onboard `vm-app01` to Arc with `scripts/Connect-DatacenterArc.ps1` and run the first Arc SQL migration assessment. The order matters: Arc onboarding turns off the run commands that `Test-Datacenter.ps1` uses for its in-VM checks.
- Have a coach review every member's C0 output (see the [C0 answer key](../coach/c00-ready-to-hack.md)). A member who isn't ready at the kickoff roster lock stays on the roster with partial C0 credit unless the event owner swaps or drops them first.
- Keep the datacenter ready for the event. Idle VMs can be stopped before the event (Bastion Standard, disks and networking still incur charges), but start both before day one. During the event, never stop `vm-dev01`: it's each member's workstation.
- Check the private-network path and the exact region and naming values before the event. No availability zones are pinned or enabled.

### Kickoff and event days

- Lock the roster at kickoff, after the T-3 review, and before scoring begins. Explain the evidence handoff. Don't announce lifelines: coaches decide when to use them.
- Follow the [two-day agenda](agenda.md). The foundation and MI work deliberately overlap other challenges.
- On Day 1 the platform lead starts ALZ-lite at 09:00. On Day 2 at 08:30, check both VMs are running and the Graph grant is done (`Grant-SqlMiDirectoryRead.ps1 -WhatIf` prints "already granted"), then the members start the MI link.
- Record every score and bonus in the [scoreboard](scoreboard.md); do not change the base contract.
- Give the [curveballs](curveballs.md) only at their scheduled triggers. Reverse the Day 1 policy after the exercise; use the [MI link spike](../docs/spikes/B07-arc-mi-link/README.md) abort path for the Day 2 curveball.

### T+2: event owner and platform lead

- Collect the evidence and owner follow-ups, then run the cleanup steps in [cleanup.md](cleanup.md), starting with its "Before you delete anything" checklist. Clean each member scope before the shared team scope.
- Confirm that the named kit resource groups and subscription-level artifacts are gone. The team cleanup intentionally preserves `rg-management`, `id-sqlmi-directory` and its Graph grant; the cleanup page says how to remove them.
- Record costs and unresolved follow-ups for the event report.

## Room and tenant logistics

- Use a room with reliable internet, power at each seat, a projector for the coach demos, and space for teams to work without exposing one another's credentials or private evidence.
- Prepare one shared-services subscription per team and one workload subscription per member. Keep attendees in their assigned subscriptions; never share Azure or GitHub credentials.
- `labadmin` on both VMs and the `contosoapp` SQL login use a documented lab password (see `infra/datacenter/README.md`, "Credentials"). That is acceptable because the VMs have no public IPs and are reachable only through Bastion. If the event isn't a throwaway or other tenants' users can reach the subscriptions, have members pass `-AdminPassword` and `-SqlAppPassword` to `Deploy-Datacenter.ps1`.
- Use Bastion Standard only. Do not pin availability zones or enable zone redundancy. Azure Hybrid Benefit is on by default and assumes eligible partner licences.
- Keep the web app's public HTTPS front end and Application Insights ingestion as the documented exceptions. Backends remain private and use their standard host names.
- Do not use the SQL Managed Instance free offer. The event path uses the paid General Purpose configuration in the archetype.
- The [cost estimate](cost-estimate.md) is a planning estimate, not an authorization to deploy.
- An event copy of this repository doesn't change what attendees run. `Import-Kit.ps1`, the datacenter script download and the clone on `vm-dev01` all fetch the upstream `jonathan-vella/apex-factory-hackathon` repository at `main`, and coaches fetch lifelines from the same place. Keep technical changes upstream, or agree with attendees which copy they use.

## Lifeline handout and scoring

Lifelines are coach-only. Students do not fetch branches or copy checkpoints themselves. Give a lifeline when a member has tried the documented hot-spot fixes and is blocked with the time box at risk; choose the earliest checkpoint that unblocks them. Save the member's work, fetch and apply the branch with them, and confirm the member can continue from the next task. The [lifeline index](../coach/lifelines.md) has the exact fetch steps.

Record the branch or image used in the member's scoreboard row. Apply the challenge-specific cap in the rubric; later challenges remain fully eligible. Do not cap a challenge merely because the member asked for help or used ordinary hints.

For sign-off, compare the submitted evidence with the matching rubric row, ask the member to explain the result, and record the awarded points and any partial-credit reason. Evidence must be attributable to the challenge and reproducible where practical. Do not put secrets or tenant, subscription or object IDs into this public repository.

## Escalation

| Blocker | First response | Escalate to |
|---|---|---|
| Quota, provider registration or region availability | Check the preflight output, region and member subscription; do not change the golden-path region silently | Platform lead, then the event owner or CSP |
| Missing CSP or Tenant Root permissions | Confirm the role and scope; vending is run by the platform lead | Event owner and the partner's CSP administrator |
| Copilot feature or model blocked by policy | Verify the approved client and organization policy; do not bypass controls | Event owner and the organization's Copilot administrator |
| SQL MI cannot create the web app's database user | Confirm cutover is complete and the MI's primary identity is `id-sqlmi-directory` with its event-prep Graph grant | Platform lead and the Privileged Role Administrator |
| Private DNS, firewall or connectivity failure | Capture the failing probe and resource name; check vending and the private endpoint DNS registration | Platform lead |
| A challenge cannot finish within its time box | Preserve current work and evidence, then ask the coach to assess the next coach-only lifeline | Coach, then event owner |

Never work around a deny policy, make an unapproved public endpoint, or share an identity's credentials to get past a blocker.
