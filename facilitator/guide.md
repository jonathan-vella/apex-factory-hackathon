# Facilitator guide

This guide is the run-of-show and decision reference for the event owner, coaches and team leads. The
attendee challenges define the work; the [scoring rubric](scoring-rubric.md) is the single source of truth
for points.

## Roles

| Role | Owns |
|---|---|
| Event owner | Copy and brand the kit, set dates and region, confirm each team's roster and member indexes, confirm access and logistics, book the Privileged Role Administrator for T-7, lock the roster, handle escalations, own cleanup and the final record |
| Coach | On duty during the two event days (not during pre-hackathon setup, where support is best-effort). Give the live portal ALZ and APEX demos, sign off challenge evidence, hand out and apply lifelines, trigger and reverse the curveballs |
| Team lead (called the platform lead in the workflow and scripts) | A colleague the team nominates and the **first point of contact** for teammates during pre-hackathon setup (Steps 1 to 4) and the event. Keeps the team's roster, assigns member indexes, deploys ALZ-lite once for the team in Step 2 (T-7), vends each member subscription in Step 4 (T-1, where the pipeline checks each member's datacenter and Arc status automatically), and coordinates policy exemptions and shared network changes. Also a member: does every member step and member challenge on their own workload subscription |
| Member | Complete the pre-hackathon setup (Steps 1, 3, and 4) and the challenges, review AI changes, keep evidence and run the app modernization work in their own repository |

## Timeline and gates

### T-30 to T-14: event owner

Attendees need the answers below before they can run preflight at T-14, so settle them first.

- Choose the event dates, team size (three to five members per team, the team lead included) and region (`swedencentral`; `germanywestcentral` is the fallback).
- Plan one Entra tenant per team, with one shared services subscription per team plus one workload subscription per member. The team lead is also a member, so a team of five needs six subscriptions. Every subscription must be paid and pass `Test-Preflight.ps1`; trial, Azure Pass and sponsorship subscriptions are not supported. Each member needs an unconditional Owner assignment on their workload subscription: preflight fails without it, and there is no Contributor fallback.
- Make sure each team's roster exists. The team lead keeps it, in a private place and never in this public kit or any repo or issue:

  | Name | GitHub handle | Team | Role | Member index | Workload subscription ID | Entra object ID | Budget email |
  |---|---|---|---|---|---|---|---|

  Each member shares the last four columns with the team lead privately at T-14 (members read them from their `factory/.local/settings.json` and `az ad signed-in-user show --query id -o tsv` once preflight is green). The team lead needs them for vending at T-1, and the pipeline's roster uses the same values.
- The team lead assigns each member an index from 1 to 20 (1 to 5 is the suggestion, the lead is 1) and tells them before T-14. `Initialize-Settings.ps1` asks for it and won't accept a value outside 1–20, and attendees are told to wait for the number rather than pick one. The index sets the member's address ranges (`10.10.n.0/24` for the datacenter, `10.20.n.0/24` for the spoke) and their peerings to the team's hub, so every member of a team, the team lead included, needs a different index. Don't confuse it with the six-character suffix that `Initialize-Settings.ps1` generates for resource names.
- Each team nominates one team lead. They need a shared services subscription and Owner at Tenant Root, which a Global Administrator grants after elevating access (see the [ALZ-lite guide](../site/src/content/docs/guides/alz-lite.md) and `infra/foundation/README.md`, "Permissions").
- Check that members can create private repos in the org. Each member works in one private repo of their own, created from `apex-accelerator`. Evidence is not collected in a shared repo.
- Give coaches read access to each member's private repo, so they can review evidence. Attendees keep their evidence, and their C5 and C6 work, in their own repos.
- Assign GitHub Copilot seats and check the org policies allow agent mode, MCP servers and Copilot CLI.
- Book a Privileged Role Administrator (or Global Administrator) for each team for T-7, right after the team lead deploys ALZ-lite. They run `scripts/Grant-SqlMiDirectoryRead.ps1` once per team (see `infra/foundation/README.md`, "Event prep: SQL MI directory identity"). It can't happen earlier, because ALZ-lite creates `id-sqlmi-directory`, and it must be done before C7. The grant is tenant-wide and read-only, and members can attach the identity to other resources during the event, so the tenant owner approves it first and names who deletes the identity afterwards (see [Accepted lab risks and adopter obligations](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/archetype/README.md#accepted-lab-risks-and-adopter-obligations)).
- Decide the SQL MI start/stop schedule. It runs Monday to Friday, 07:30 to 18:30, `W. Europe Standard Time`, and applies only after cutover removes the link. For another time zone or for event days outside that window, set `sqlMiScheduleTimeZoneId`, `sqlMiScheduleStartTime`, `sqlMiScheduleStopTime` or `sqlMiScheduleDays` (day names such as `'Monday'`) before attendees deploy. `archetype/infra/bicep/university/main.bicepparam` doesn't set them today, so they take the defaults in `main.bicep`: either change those defaults, or add for example `param sqlMiScheduleStartTime = '08:00'` to the `.bicepparam` file. Attendees import that folder with `Import-Archetype.ps1`, so make the change in your event copy and have them import from it (see "Pointing the scripts at an event copy" below). If they import from upstream, they get the upstream schedule, and each attendee has to make the same change in their own `infra/bicep/university` before `azd provision`. Tell coaches that after cutover the MI can be stopped outside that window.
- Decide who owns the APEX demo subscription and its cleanup (see the [APEX demo](apex-demo.md)).
- Get the tenant owner's approval for the Owner-at-Tenant-Root pipeline identity (the team lead's pipeline holds Owner at Tenant Root while it exists). Name the person who runs `scripts/Remove-PlatformPipeline.ps1` after the teardown stage, and the date (see [platform pipeline](platform-pipeline.md), "Accepted risk").
- Use a dedicated non-production tenant and dedicated, empty subscriptions. ALZ-lite and vending turn off paid Defender for Cloud plans subscription-wide, so don't point them at subscriptions that hold other workloads.
- Book the Privileged Role Administrator for T-7 with Reader on `rg-management` (or on the shared services subscription), so they can read the identity, and with PowerShell 7 and the Azure CLI installed. Name a backup person.
- If a member is swapped or added after T-14, also re-run `Initialize-PlatformPipeline.ps1 -RosterPath <roster file>` in the team lead's repo: the pipeline reads its members only from the roster secret it stores.
- Tell attendees that certifications follow the event: infra roles hold AZ-104, GH-300 and DP-300 within six months after it, and no exam is a gate for attending (see the [learning path](../site/src/content/docs/guides/learning-path.md)).

### Step 1 (T-14): team leads and members

- No coach is on duty during the pre-hackathon window; support is best-effort and the designated team lead is each member's first point of contact.
- Confirm each team has one shared-services subscription and each member has a separate workload subscription.
- Everyone creates their repo, imports the kit, sets up the pipeline, runs the `whatif` preflight ([Step 1: Repo and preflight](https://factory.apexops.pro/deploy/set-up-your-repo/)) and fixes every FAIL. Each member shares their workload subscription ID, member index, Entra object ID and email privately with the team lead, who registers `roster.json` with `Initialize-PlatformPipeline.ps1 -RosterPath .local/roster.json`.
- Confirm the team lead has the rights described in the [ALZ-lite guide](../site/src/content/docs/guides/alz-lite.md), including rights at Tenant Root to create management groups and move subscriptions. The team lead deploys ALZ-lite a week later, so this is the last point to fix it.
- Confirm the Privileged Role Administrator for each team is booked for T-7.
- Check member MFA, resource-provider registration, quota, Copilot policies and access to the APEX runtime. Do not put tenant, subscription or object IDs in this public kit.
- Confirm the attendees can use the approved Copilot features and extensions on the dev VM. Escalate organizational Copilot policy issues before the event.
- Confirm the draft roster and publish the agenda, room details and escalation channel. The roster stays open until kickoff, so you can still swap or drop a member who can't get ready.

### Step 2 (T-7): team lead and Privileged Role Administrator

- The team lead deploys ALZ-lite for the team: run 1 of the platform pipeline, the `foundation` stage in the lead's repo ([Step 2: Foundation and Graph grant](https://factory.apexops.pro/deploy/team-lead-steps/)). It takes about 15 to 25 minutes and creates `id-sqlmi-directory`. The firewall bills about $1.30 an hour from here until cleanup.
- Right after it, the Privileged Role Administrator runs `scripts/Grant-SqlMiDirectoryRead.ps1` for the team. Check it with `-WhatIf`: it prints that the three permissions are already granted.

### Step 3 (T-3): everyone (members and team lead)

- Every member, team lead included, runs [Step 3: Datacenter and workstation](https://factory.apexops.pro/deploy/member-steps/) in their own repo with the `whatif` and `member` stages: preflight, then the datacenter with Azure Hybrid Benefit on by default (a member without eligible licenses sets the `no-hybrid-benefit` input), then `Test-Datacenter.ps1` while both VMs are running, then Arc onboarding of `vm-app01`, all in one `member` run. After it they run the first Arc SQL migration assessment in the portal, set up `vm-dev01`, and commit their readiness evidence to `factory/evidence/readiness/`. The order matters: Arc onboarding turns off the run commands that `Test-Datacenter.ps1` uses for its in-VM checks, so the stage tests before Arc. Students don't run the deploy scripts by hand; a coach does only as a repair (see [deploy with scripts](../coach/deploy-with-scripts.md)).
- There is no pre-event coach sign-off gate: instead, the `vending` stage in Step 4 automatically checks that each member's `vnet-datacenter` exists and `vm-app01` is `Connected` in Azure Arc before vending their spoke. Each member notifies their team lead when their Step 3 checklist is complete.
- Keep the datacenter ready for the event. Idle VMs can be stopped before the event (Bastion Standard, disks and networking still incur charges), but start both before Step 4 (`vending` at T-1), which restarts them and runs probes inside them. During the event, never stop `vm-dev01`: it's each member's workstation.
- A `vm-dev01` deployed before the sparse-checkout change still has the full kit clone, with `coach/`, `facilitator/`, `docs/`, `site/` and `test/` in it, and the documentation and lint tooling at the repo root. Apply the "Slim an existing clone" block in `infra/datacenter/README.md` on that VM with the member. `Test-Datacenter.ps1` reports the full clone as a failed check until you do.
- Check the private-network path and the exact region and naming values before the event. No availability zones are pinned or enabled.

### Step 4 (T-1): everyone starts VMs, team lead vends

- Every member starts `vm-app01` and `vm-dev01`. Then the team lead runs [Step 4: Vending](https://factory.apexops.pro/deploy/vending/), the `vending` stage in the lead's repo. For each member in `roster.json`, `Invoke-PipelineVending.ps1` verifies that `vnet-datacenter` exists and `vm-app01` is `Connected` in Azure Arc, vends the spoke, restarts both VMs, records the datacenter exemptions and runs the connectivity probes. A coach repairs a failed run by hand only with the commands in [deploy with scripts](../coach/deploy-with-scripts.md).
- Vending comes after each member's Step 3 datacenter and `vm-dev01` setup on purpose. It changes the datacenter's DNS servers to the hub firewall, and nothing before it tests that. The hard dependencies are only these: ALZ-lite and each member's Arc-connected datacenter before vending, and `Test-Datacenter.ps1` before Arc. The datacenter still exists before the subscription moves under the Corp group, so the exemptions lesson stays.
- A restart ends a member's Bastion session, so tell members first. A member whose datacenter is redeployed after vending is vended again.
- Post "vended" with each member's name and the shared services subscription ID in the team channel so members can save `sharedSubscriptionId` with `Initialize-Settings.ps1 -SharedSubscriptionId`.

### Kickoff and event days

- Lock the roster at kickoff, after the T-3 review and the T-1 vending, and before scoring begins. Explain the evidence handoff. Don't announce lifelines: coaches decide when to use them.
- Follow the [two-day agenda](agenda.md). The foundation and MI work deliberately overlap other challenges. Time boxes are pacing: coaches flex on the day, and the minutes and points don't change.
- Staff at least one coach for every six attendees.
- Day 1 starts with a 30-minute PowerPoint introduction by the tech lead at 08:30, then C1 at 09:00 and C2 at 09:45: the foundation already exists, so each member uses C2 to test an AI coding agent against the repository baseline and ALZ-lite `Deny` policies in `rg-spoke`. On Day 2 at 08:30, check both VMs are running and the Graph grant is done (`Grant-SqlMiDirectoryRead.ps1 -WhatIf` prints "already granted"), then the members start the MI link.
- Record every score and bonus in the [scoreboard](scoreboard.md); do not change the base contract. Teams with the same team score share the rank. Each team's bonus is capped at 30 points and awarded in the order the bonuses appear in the [rubric](scoring-rubric.md) until the team reaches the cap.
- Give the [curveballs](curveballs.md) only at their scheduled triggers. Reverse the Day 1 policy after the exercise; use the [MI link spike](../docs/archive/spikes/B07-arc-mi-link/README.md) abort path for the Day 2 curveball. The staged Day 2 abort is part of the event and earns no bonus.

### T+2: event owner and team lead

- Collect the evidence and owner follow-ups, then run the cleanup steps in [cleanup.md](cleanup.md), starting with its "Before you delete anything" checklist. Each member runs the `teardown` stage in their own repo before the team lead runs it for the team. Members who are absent or haven't cleaned up by the owner's deadline are cleaned by the team lead's `teardown` run (see cleanup.md).
- A named admin runs `scripts/Remove-PlatformPipeline.ps1` right after the `teardown` stage, on the date agreed at T-30: the lead profile in the team lead's repo, and `-Profile Member` in each member's repo. The workflow never removes its own identity or roles.
- Confirm that the named kit resource groups and subscription-level artifacts are gone. The team cleanup preserves `rg-management`, `id-sqlmi-directory` and its Graph grant by default (the `include-management` input removes them). The event owner decides: delete them unless the tenant is reused for another event (see the cleanup page).
- Remove access that was only needed for the event: the team lead's Owner at Tenant Root, any Global Administrator elevation used to give it, and the Privileged Role Administrator's activation or Reader grant.
- Record costs and unresolved follow-ups for the event report.

### Verify after cleanup

- `rg-datacenter`, `rg-spoke` and `rg-university-<suffix>` are gone in every member subscription, and the shared `rg-hub` is gone.
- `rg-cicd`, the `id-factory-pipeline` identity and its role assignments are gone (in the shared services subscription for the lead profile, and in each member's workload subscription), and the `gh-lab` environment and the `ROSTER_JSON` secret are gone from the repo.
- `id-sqlmi-directory` and its Graph grant are gone, unless the tenant is reused.
- The elevated access in the list above has been removed.

## Room and tenant logistics

- Use a room with reliable internet, power at each seat, a projector for the coach demos, and space for teams to work without exposing one another's credentials or private evidence.
- Prepare one shared-services subscription per team and one workload subscription per member. Keep attendees in their assigned subscriptions; never share Azure or GitHub credentials.
- `labadmin` on both VMs and the `contosoapp` SQL login use a documented lab password (see `infra/datacenter/README.md`, "Credentials"). The `member` stage always uses the documented password, and `Get-PipelineEvidence.ps1` saves it in `.local/<subscription-id>/datacenter.json` for the later challenges. That is acceptable because the VMs have no public IPs and are reachable only through Bastion. If the event isn't a throwaway or other tenants' users can reach the subscriptions, a coach deploys the datacenter by hand with `-AdminPassword` and `-SqlAppPassword` (see [deploy with scripts](../coach/deploy-with-scripts.md)).
- Use Bastion Standard only. Do not pin availability zones or enable zone redundancy. Azure Hybrid Benefit is on by default and assumes eligible partner licences.
- Keep the web app's public HTTPS front end and Application Insights ingestion as the documented exceptions. Backends remain private and use their standard host names.
- Do not use the SQL Managed Instance free offer. The event path uses the paid General Purpose configuration in the archetype.
- The [cost estimate](cost-estimate.md) is a planning estimate, not an authorization to deploy.

## Pointing the scripts at an event copy

An event copy of this repository doesn't change what attendees run by default. `Import-Kit.ps1`, the datacenter script download and the clone on `vm-dev01` all fetch the upstream `jonathan-vella/apex-factory-hackathon` repository at `main`, and coaches fetch lifelines from the same place. Keep technical changes upstream, or point the scripts at your copy. The copy must be public: the VMs read `raw.githubusercontent.com` without signing in, and the imports run without signing in too. Tell attendees which flags to use:

- `scripts/Deploy-Datacenter.ps1 -Repository <owner>/<name>` makes the VMs download `infra/datacenter/scripts` and `db/perf-kit/sql` from your copy. `-ScriptsRef` picks a branch or commit; it defaults to `main`. The `member` stage sets both from the workflow's `KIT_REPOSITORY` and `KIT_REF`, which `Import-Kit.ps1` writes into the attendee's repo, so students need no flag. A coach repair by hand needs them.
- `scripts/Import-Kit.ps1 -KitRepository <owner>/<name>` imports the kit from your copy, and passes the same value on to `Import-Archetype.ps1`. `-Ref` picks a branch or commit.
- `archetype/Import-Archetype.ps1 -KitRepository <owner>/<name>` is the same flag for importing the archetype alone.
- `Deploy-Datacenter.ps1` has its own `-Repository`, which `Import-Kit.ps1` doesn't pass on, so a coach repair needs both.
- The kit clone on `vm-dev01` and the lifelines still come from upstream.

## Lifeline handout and scoring

Lifelines are coach-only. Students do not fetch branches or copy checkpoints themselves. Give a lifeline when a member has tried the documented hot-spot fixes and is blocked with the time box at risk; choose the earliest checkpoint that unblocks them. Save the member's work, fetch and apply the branch with them, and confirm the member can continue from the next task. The [lifeline index](../coach/lifelines.md) has the exact fetch steps. The clone on `vm-dev01` leaves out `coach/`, `facilitator/`, `docs/`, `site/` and `test/` (and the documentation and lint tooling at the repo root: see `infra/datacenter/README.md`) on newly deployed VMs, so members can't browse the answer keys there. Lifeline branches still work: they are fetched from `origin` and exist as git branches regardless of the sparse checkout.

Record the branch or image used in the member's scoreboard row. Apply the challenge-specific cap in the rubric; later challenges remain fully eligible. Do not cap a challenge merely because the member asked for help or used ordinary hints.

For sign-off, compare the submitted evidence with the matching rubric row, ask the member to explain the result, and record the awarded points and any partial-credit reason. Evidence must be attributable to the challenge and reproducible where practical. Do not put secrets or tenant, subscription or object IDs into this public repository.

## Escalation

| Blocker | First response | Escalate to |
|---|---|---|
| Quota, provider registration or region availability | Check the preflight output, region and member subscription; do not change the golden-path region silently | Team lead, then the event owner or CSP |
| Missing CSP or Tenant Root permissions | Confirm the role and scope; Owner on the workload subscription is required, with no fallback; vending is run by the team lead | Event owner and the partner's CSP administrator |
| Copilot feature or model blocked by policy | Verify the approved client and organization policy; do not bypass controls | Event owner and the organization's Copilot administrator |
| SQL MI cannot create the web app's database user | Confirm cutover is complete and the MI's primary identity is `id-sqlmi-directory` with its event-prep Graph grant | Team lead and the Privileged Role Administrator |
| Private DNS, firewall or connectivity failure | Capture the failing probe and resource name; check vending and the private endpoint DNS registration | Team lead |
| A challenge cannot finish within its time box | Preserve current work and evidence, then ask the coach to assess the next coach-only lifeline | Coach, then event owner |

Never work around a deny policy, make an unapproved public endpoint, or share an identity's credentials to get past a blocker.
