# Readiness gate

> [!WARNING]
> Coach material. This page is the sign-off for the readiness check that every member does before the event. Attendees work it out from the [member steps](https://factory.apexops.pro/deploy/member-steps/#readiness-check).

The readiness check has no points. It is a go/no-go gate at T-1: only a coach-approved readiness record enters vending. Members do the work before the event, on their own time, against their own workload subscription, so there is no coach in the room and the evidence has to be unambiguous when you review it.

The team lead (called the platform lead in the workflow and scripts) runs the `vending` stage once for the whole team. Vending needs each member's datacenter and changes its DNS, so a datacenter without an approved record isn't vended. A member who finishes after T-1 is vended as soon as their record is approved: the team lead runs the `vending` stage for that member alone. The team lead is also a member and goes through the same gate.

## The gate

1. Review every member's readiness record at T-3, in the member's own repo (`factory/evidence/readiness/`). Use the checklist below.
2. Tell the team lead which members are approved. Don't approve a record you haven't checked against the checklist.
3. A member who isn't ready stays out of the T-1 `vending` run. The member fixes the gap, you approve the record again, and the team lead vends that member alone with `-f members=<index>`.
4. A datacenter redeployed after vending requires vending again (see Recovery).

## Sign-off checklist

Tick every line before you approve a record.

- Preflight is green. The output is in the Actions run summary (GUIDs show as `<id:abcd>`), so there is no preflight file: `Get-PipelineEvidence.ps1` saves only `test-datacenter.txt`. Accept a link to the successful `whatif` or `member` run in the member's repo, or a screenshot of the preflight step showing the GO verdict. A member who skipped a manual check (MFA, GitHub Copilot, GitHub repositories, APEX, Azure Hybrid Benefit) usually surfaces later in C2 or C5: ask them to re-run the `whatif` stage if C5 behaves oddly.
- `Test-Datacenter.ps1` PASS from before Arc onboarding: all green, including the perf kit's planted objects and data present on `vm-app01`'s SQL Server (C9 depends on them: if they're missing, the perf kit needs resetting before C9). It can't pass after Arc onboarding, so don't ask for a re-run. The `member` stage runs the test first and onboards Arc only if it passes, so a pipeline member can't hit the order mistake. The run summary, or `evidence/readiness/test-datacenter.txt` from `Get-PipelineEvidence.ps1`, counts as this output.
- Arc connected: the Arc resource for `vm-app01` shows Connected, with the SQL Server extension installed and the instance listed.
- Arc assessment output: a screenshot or export of the first Arc migration assessment. They don't need to have acted on it, because C3 is where that happens. If the assessment isn't available yet (Arc's own assessment feature is still initializing), accept the pre-Arc `Test-Datacenter.ps1` green output and have the member pull the assessment first thing in C3.
- Hybrid Benefit and cost check: the member confirms Azure Hybrid Benefit is on (or gives the reason it isn't) and says what state the VMs are in. A member without eligible licenses used `-f no-hybrid-benefit=true`, and `vm-app01` then bills about $0.75 an hour more (about $2.30 instead of $1.55 an hour while running).
- The credentials file: `Get-PipelineEvidence.ps1` writes `.local/<subscription-id>/datacenter.json` with the documented fixed lab credentials, because the runner deployed the datacenter. Later password lookups (the `vm-dev01` setup, C7 to C9) read it. If the file is missing, have them run the script again.
- Evidence in `evidence/readiness`: the member's own repo holds the files on `main`, in `factory/evidence/readiness/`. Evidence kept only on the member's laptop doesn't count: ask them to copy it into their repo and push it before your review, because the review gates vending at T-1.
- `vm-dev01` and Copilot validated: a screenshot of Copilot Chat answering in VS Code on `vm-dev01`, signed in to GitHub. If it's missing or Copilot is blocked, it's a blocker: C3 and C6 depend on it, so fix the access before the event.

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

- Ask each member to confirm Actions minutes are available for their private repo before the preflight (Settings, Billing and plans). With a failed payment or a zero spending limit, every run fails at once with no steps and no log, which looks like a kit fault and isn't.
- Running preflight once and not re-running the `whatif` stage after resource provider registration (which takes up to 15 minutes to propagate) leaves a false red.
- Trying a manual Arc onboarding through the portal "just to see" works but produces a differently named Arc resource that later scripts (`Test-Datacenter.ps1`, the migration assessment lookups) won't find. Redo it with the script if this happened.
- Turning Azure Hybrid Benefit off "to compare" and forgetting to turn it back on: it should stay on throughout.
- Leaving both VMs running between sessions isn't a correctness problem, but it bills for nothing, so remind members. Stopping `vm-dev01` during the event is the opposite mistake: it's the members' workstation.
- Arc **Connected** but no SQL Server instance after 5 minutes on an older copy of the kit: install the `WindowsAgent.SqlServer` extension from the portal (Azure Arc > Machines > `vm-app01` > Extensions). The current script installs it after 5 minutes (see [platform pipeline](../facilitator/platform-pipeline.md)).
- Arc onboarding before `Test-Datacenter.ps1` is only possible in a hand-run repair. The in-VM rows can't pass after Arc. Accept the in-VM FAIL, with the member's written explanation, if every Azure-side row (the ones that start with `azure:`: VM state, size and license type, Trusted Launch, disks, no public IPs, Bastion) is green and Arc shows Connected with the SQL instance. Redo only if an Azure-side row fails: that means the datacenter itself is wrong. The perf kit's planted data can't be checked after Arc, so look at it at the start of C9.
- Preflight and datacenter deployed, but Arc onboarding not finished: don't approve the record. The member finishes onboarding, and you approve it again. If it still isn't done at the event's start, the member finishes it in the first break of day one and is vended then.

## Recovery

Rerun the stage first: the stages are idempotent. Rerunning the `member` stage is safe before Arc onboarding: it redeploys the datacenter with the same parameters, and the stage refuses to redeploy over Arc. There is no `-Force` parameter. What happens next depends on where the member is:

- **Vended, not Arc-enabled:** rerun the `member` stage, then the team lead runs the `vending` stage for that member again (`-f members=<index>`; it restarts both of their VMs and records their exemptions again, because redeploying drops the DNS and route settings vending applied; see [C2](c02-secure-ai-ready-foundation.md#reset)).
- **Arc-enabled:** there's no in-place reset. The member deletes `rg-datacenter` in the portal (which also deletes `vm-dev01`, so they repeat the `vm-dev01` setup), then reruns the `member` stage. If the member was already vended, the team lead runs the `vending` stage for them again too.
- **A run that can't be repaired in time:** a coach runs the scripts by hand, from the commands on the [deploy with scripts](deploy-with-scripts.md#member) page. Never rerun Arc, and never redeploy the datacenter after Arc.
