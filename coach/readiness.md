# Readiness verification (coach)

> [!WARNING]
> Coach and team-lead reference. No coach is on duty during the pre-hackathon window; support before day one is best-effort and attendees contact their designated team lead first. Attendees follow the numbered steps in [Step 3: Datacenter and workstation](https://factory.apexops.pro/deploy/member-steps/#readiness-checklist) and [Step 4: Vending](https://factory.apexops.pro/deploy/vending/).

The readiness setup has no points. Before day one, each member runs [Step 1](https://factory.apexops.pro/deploy/set-up-your-repo/) (T-14) and [Step 3](https://factory.apexops.pro/deploy/member-steps/) (T-3) in their own repository against their own workload subscription. At T-1 ([Step 4](https://factory.apexops.pro/deploy/vending/)), the team lead runs the `vending` stage once for the whole team: `Invoke-PipelineVending.ps1` automatically checks that each member's `vnet-datacenter` exists and `vm-app01` is `Connected` in Azure Arc before vending their spoke.

If a coach is reviewing readiness evidence at kickoff on day one (or helping a team lead troubleshoot a member before T-1), use the checklist below.

## How readiness is verified

1. **Automated check in Step 4 (`vending` at T-1):** for each member in `roster.json`, `Invoke-PipelineVending.ps1` verifies that `vnet-datacenter` exists in `rg-datacenter` and that the Azure Arc machine `vm-app01` has `properties.status == 'Connected'`. Because the `member` stage only runs `Connect-DatacenterArc.ps1` after `Test-Datacenter.ps1` passes all 46 checks, an Arc `Connected` status proves the datacenter deployed and passed the pre-Arc validation.
2. **Evidence in `factory/evidence/readiness/`:** each member commits their readiness artifacts to `main` in their own repository during Step 3.
3. **Vending failures:** if phase 1 stops at the first unready member, earlier members are vended but not restarted, exempted or probed, and later members are not vended. Fix the cause and rerun `vending` for all members; it is safe to repeat. If phase 2 fails while restarting VMs, fix the cause and rerun for all members. If phase 3 names members whose exemptions or connectivity probes failed, rerun only for those named indexes.
4. **Datacenter redeploy:** a datacenter redeployed after vending requires vending again (see Recovery).

## Readiness checklist

Use this list when spot-checking `factory/evidence/readiness/` in a member's repository at kickoff or when helping a team lead unblock a member.

- Preflight is green. The output is in the Actions run summary (GUIDs show as `<id:abcd>`), so there is no preflight file: `Get-PipelineEvidence.ps1` saves only `test-datacenter.txt`. Check the successful `whatif` or `member` run in the member's repo, or a screenshot of the preflight step showing the GO verdict. A member who skipped a manual check (MFA, GitHub Copilot, GitHub repositories, APEX, Azure Hybrid Benefit) usually surfaces later in C2 or C5: ask them to re-run the `whatif` stage if C5 behaves oddly.
- `Test-Datacenter.ps1` PASS from before Arc onboarding: all green, including the perf kit's planted objects and data present on `vm-app01`'s SQL Server (C9 depends on them: if they're missing, the perf kit needs resetting before C9). It can't pass after Arc onboarding, so don't ask for a re-run. The `member` stage runs the test first and onboards Arc only if it passes, so a pipeline member can't hit the order mistake. The run summary, or `evidence/readiness/test-datacenter.txt` from `Get-PipelineEvidence.ps1`, counts as this output.
- Arc connected: the Arc resource for `vm-app01` shows Connected (`Invoke-PipelineVending.ps1` checks this automatically), with the SQL Server extension installed and the instance listed.
- Arc assessment output: a screenshot or export of the first Arc migration assessment. They don't need to have acted on it, because C3 is where that happens. If the assessment isn't available yet (Arc's own assessment feature is still initializing), accept the pre-Arc `Test-Datacenter.ps1` green output and have the member pull the assessment first thing in C3.
- Hybrid Benefit and cost check: the member confirms Azure Hybrid Benefit is on (or gives the reason it isn't), confirms per-user Windows 11 multitenant hosting rights for `vm-dev01`, and says what state the VMs are in. A member without eligible Windows Server licenses used `-f no-hybrid-benefit=true`; `vm-app01` then bills about $0.37 an hour more (about $1.92 instead of $1.55 an hour while running; estimate checked 2026-10-08).
- The credentials file: `Get-PipelineEvidence.ps1` writes `.local/<subscription-id>/datacenter.json` with the documented fixed lab credentials, because the runner deployed the datacenter. Later password lookups (the `vm-dev01` setup, C7 to C9) read it. If the file is missing, have them run the script again.
- Evidence in `evidence/readiness`: the member's own repo holds the files on `main`, in `factory/evidence/readiness/`.
- `vm-dev01` and Copilot validated: a screenshot of Copilot Chat answering in VS Code on `vm-dev01`, signed in to GitHub. If it's missing or Copilot is blocked, it's a blocker: C3 and C6 depend on it, so fix the access before C3.

## How members get there

Members run the readiness check from GitHub Actions in their own repo. Each stage approves once and runs the kit's scripts with the member's `.local/settings.json` values. The steps are on the [member steps](https://factory.apexops.pro/deploy/member-steps/) page. The team lead does the same in the lead's repo, with `-f members=<lead's index>`.

1. `gh workflow run platform.yml -f stage=whatif`: the preflight, with `-Fix` (the lead's run also does the ALZ-lite what-if). The member reviews the manual-check list it prints and confirms each one.
2. `gh workflow run platform.yml -f stage=member -f members=<index>`: deploys the datacenter, runs `Test-Datacenter.ps1` with both VMs running, and only if that passes onboards `vm-app01` to Azure Arc. The test comes before Arc because after Arc, run commands on `vm-app01` stop working and the in-VM checks fail. There is no portal fallback for Arc, by design.
3. `./scripts/Get-PipelineEvidence.ps1` downloads the `Test-Datacenter.ps1` output into `evidence/readiness/` and writes the credentials file. The member commits the evidence file.
4. In the Arc resource's SQL Server blade, the member starts (or reviews) the migration assessment.
5. The member connects to `vm-dev01` through Bastion, opens VS Code, signs in to GitHub and sends a message in Copilot Chat.
6. Before the event, the member may stop both VMs (`vm-app01`, `vm-dev01`) when not working, and must start them again before the `vending` stage at T-1, because vending restarts both and the probes run inside them. During the event, never stop `vm-dev01`.

The manual path, for repairs only, is on the [deploy with scripts](deploy-with-scripts.md) page. Students never run it.

## Hints

- Ask each member to confirm the partner GitHub organization has included Actions compute available and a payment method for additional private-repo usage. The repository owner is billed; check **Billing & Licensing**, the budget and payment method before preflight.
- Running preflight once and not re-running the `whatif` stage after resource provider registration (which takes up to 15 minutes to propagate) leaves a false red.
- Trying a manual Arc onboarding through the portal "just to see" works but produces a differently named Arc resource that later scripts (`Test-Datacenter.ps1`, the migration assessment lookups) won't find. Redo it with the script if this happened.
- Turning Azure Hybrid Benefit off during the event: it should stay on throughout. A member without eligible Windows Server licenses must set `no-hybrid-benefit=true` on the initial `member` stage, before Arc onboarding.
- Leaving both VMs running between sessions isn't a correctness problem, but it bills for nothing, so remind members. Stopping `vm-dev01` during the event is the opposite mistake: it's the members' workstation.
- Arc **Connected** but no SQL Server instance after 5 minutes on an older copy of the kit: install the `WindowsAgent.SqlServer` extension from the portal (Azure Arc > Machines > `vm-app01` > Extensions). The current script installs it after 5 minutes (see [platform pipeline](../facilitator/platform-pipeline.md)).
- Arc onboarding before `Test-Datacenter.ps1` is only possible in a hand-run repair. The in-VM rows can't pass after Arc. Accept the in-VM FAIL, with the member's written explanation, if every Azure-side row (the ones that start with `azure:`: VM state, size and license type, Trusted Launch, disks, no public IPs, Bastion) is green and Arc shows Connected with the SQL instance. Redo only if an Azure-side row fails: that means the datacenter itself is wrong. The perf kit's planted data can't be checked after Arc, so look at it at the start of C9.
- Preflight and datacenter deployed, but Arc onboarding not finished: `vending` refuses to vend that member until `vm-app01` shows `Connected` in Azure Arc. Once the member finishes onboarding, the team lead reruns `vending` for all members; it is safe to repeat.

## Recovery

Rerunning the `member` stage is safe before Arc onboarding: it redeploys the datacenter with the same parameters, and the stage refuses to redeploy over Arc. There is no `-Force` parameter. After Arc onboarding, use the recovery below.

- **Arc-enabled, before C5:** there is no in-place reset. To recover, run `teardown`, then `member`. In the member's own repo (member profile), run:

  ```bash
  gh workflow run platform.yml -f stage=teardown
  gh workflow run platform.yml -f stage=member
  ```

  In the team lead's repo, run the same stages with the member's index:

  ```bash
  gh workflow run platform.yml -f stage=teardown -f members=<your index>
  gh workflow run platform.yml -f stage=member -f members=<your index>
  ```

  Member teardown removes `rg-datacenter`, `rg-spoke` and the archetype, including the SQL Managed Instance. Repeat Step 3 and the `vm-dev01` setup. If the member does not hold eligible Windows Server licenses, add `-f no-hybrid-benefit=true` to the `member` command. If the member was already vended, the team lead runs `vending` for that index afterward. Before T+2, never run a full, unfiltered teardown in the team lead's repo; pass `-f members=<your index>` or ask the event owner for a coach repair. After C5, do not use this recovery; ask the event owner for a coach repair.
- **A run that can't be repaired in time:** a coach runs the scripts by hand, from the commands on the [deploy with scripts](deploy-with-scripts.md#member) page. Never rerun Arc, and never redeploy the datacenter after Arc.
