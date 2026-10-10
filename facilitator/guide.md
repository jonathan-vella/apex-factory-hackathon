# Facilitator guide

This guide is the run-of-show and decision reference for the event owner, coaches and platform lead. The
attendee challenges define the work; the [scoring rubric](scoring-rubric.md) is the single source of truth
for points.

## Roles

| Role | Owns |
|---|---|
| Event owner | Copy and brand the kit, set dates and region, confirm access and logistics, lock the roster, handle escalations, own cleanup and the final record |
| Coach | Give the live portal ALZ and APEX demos, sign off evidence, hand out and apply lifelines, trigger and reverse the curveballs |
| Platform lead | Deploy ALZ-lite once for the team, vend each member subscription, coordinate policy exemptions and shared network changes |
| Member | Complete the individual challenges, review AI changes, keep evidence and run the app modernization work in their own repository |

## Timeline and gates

### T-14: event owner and platform lead

- Choose the event dates, team size and region (`swedencentral`; `germanywestcentral` is the fallback).
- Confirm each team has one shared-services subscription and each member has a separate workload subscription.
- Confirm the platform lead has the rights described in the [ALZ-lite guide](../site/src/content/docs/guides/alz-lite.md), including rights at Tenant Root to create management groups and move subscriptions.
- Line up a Privileged Role Administrator for each team who will be reachable on day one. In C2, right after the platform lead deploys ALZ-lite, they run `scripts/Grant-SqlMiDirectoryRead.ps1` once per team to grant `id-sqlmi-directory` its Microsoft Graph read permissions (see `infra/foundation/README.md`, “Event prep: SQL MI directory identity”). It can't happen earlier, because ALZ-lite creates the identity, and C7 needs it.
- Check member MFA, resource-provider registration, quota, Copilot policies and access to the APEX runtime. Do not put tenant, subscription or object IDs in this public kit.
- Confirm the attendees can use the approved Copilot features and extensions on the dev VM. Escalate organizational Copilot policy issues before the event.
- Freeze the kickoff roster and publish the agenda, room details and escalation channel.

### T-3: platform lead and members

- Run the member preflight, deploy the datacenter with Azure Hybrid Benefit on by default, confirm the legacy app with `scripts/Test-Datacenter.ps1` while both VMs are running, then onboard `vm-app01` to Arc with `scripts/Connect-DatacenterArc.ps1` and run the first Arc SQL migration assessment. The order matters: Arc onboarding turns off the run commands that `Test-Datacenter.ps1` uses for its in-VM checks.
- Keep the datacenter ready for the event. Idle VMs can be stopped before the event (Bastion Standard, disks and networking still incur charges), but start both before day one. During the event, never stop `vm-dev01`: it's each member's workstation.
- Check the private-network path and the exact region and naming values before the event. No availability zones are pinned or enabled.

### Kickoff and event days

- Lock the roster before scoring begins. Explain the evidence handoff and the lifeline process.
- Follow the [two-day agenda](agenda.md). The foundation and MI work deliberately overlap other challenges.
- Record every score and bonus in the [scoreboard](scoreboard.md); do not change the base contract.
- Give the [curveballs](curveballs.md) only at their scheduled triggers. Reverse the Day 1 policy after the exercise; use the B07 abort path for the Day 2 curveball.

### T+2: event owner and platform lead

- Collect the evidence and owner follow-ups, then run the cleanup steps in [cleanup.md](cleanup.md). Clean each member scope before the shared team scope.
- Confirm that the named kit resource groups and subscription-level artifacts are gone. The team cleanup intentionally preserves `rg-management`, `id-sqlmi-directory` and its Graph grant.
- Record costs and unresolved follow-ups for the event report.

## Room and tenant logistics

- Use a room with reliable internet, power at each seat, a projector for the coach demos, and space for teams to work without exposing one another's credentials or private evidence.
- Prepare one shared-services subscription per team and one workload subscription per member. Keep attendees in their assigned subscriptions; never share credentials.
- Use Bastion Standard only. Do not pin availability zones or enable zone redundancy. Azure Hybrid Benefit is on by default and assumes eligible partner licences.
- Keep the web app's public HTTPS front end and Application Insights ingestion as the documented exceptions. Backends remain private and use their standard host names.
- Do not use the SQL Managed Instance free offer. The event path uses the paid General Purpose configuration in the archetype.
- The kit deploys no infrastructure during B12. The cost estimate is a planning estimate, not an authorization to deploy.

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
