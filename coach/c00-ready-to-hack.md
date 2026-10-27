# C0 answer key: Ready to hack

> [!WARNING]
> Coach material. This page has the answers to C0. Attendees work it out from the scripts and the pre-work instructions.

C0 is pre-work: members do it before the event, on their own time, against their own workload subscription. There's no coach in the room for this one, so the evidence needs to be unambiguous when you review it at T-3. Review every member's C0 output before the platform lead vends at T-1: vending needs each member's datacenter and changes its DNS, so a datacenter that isn't reviewed isn't vended. A member who finishes after T-3 is vended as soon as their review is done.

## Expected evidence

- Preflight output: every automated check green. A member who skipped a manual check (MFA, GitHub Copilot, GitHub repositories, APEX, Azure Hybrid Benefit) usually surfaces later in C2 or C5 — ask them to re-run the `whatif` stage if C5 behaves oddly. The preflight output is in the Actions run summary (GUIDs show as `<id:abcd>`), so there is no preflight file: `Get-PipelineEvidence.ps1` saves only `test-datacenter.txt`. Accept a link to the successful `whatif` or `member` run in their repo (or a screenshot of the preflight step showing the GO verdict).
- `Test-Datacenter.ps1` output from before Arc onboarding: all green, including the perf kit's planted objects and data present on `vm-app01`'s SQL Server (this is what C9 depends on later — if it's missing now, the perf kit needs resetting before C9). It can't pass after Arc onboarding, so don't ask for a re-run. The `member` stage runs the test first and onboards Arc only if it passes, so a pipeline member can't hit the order mistake. The run summary, or `evidence/c00/test-datacenter.txt` from `Get-PipelineEvidence.ps1`, counts as this output.
- The credentials file: `Get-PipelineEvidence.ps1` also writes `.local/<subscription-id>/datacenter.json` with the documented fixed lab credentials, because the runner deployed the datacenter. Later password lookups (C0 task 7, C7 to C9) read it. If a member's file is missing, have them run the script again.
- The Arc resource for `vm-app01` showing Connected, with the SQL Server extension installed and the instance listed.
- A screenshot or export of the first Arc migration assessment. They don't need to have acted on it — C3 is where that happens.
- A note that Azure Hybrid Benefit is on (or why not), confirmed by the member, and the VM power state (2 of the member's 10 C0 points with the preflight output).
- A screenshot of Copilot Chat answering in VS Code on `vm-dev01`, signed in to GitHub. It has no points row of its own. If it's missing or Copilot is blocked, it's a T-3 readiness blocker: C3 and C6 depend on it, so fix the access before the event.

## Model answer

Students run C0 from GitHub Actions in their own repo ([Deploy with GitHub Actions](https://factory.apexops.pro/guides/deploy-with-actions/)). Each stage approves once and runs the kit's scripts with the member's `.local/settings.json` values. The platform lead runs their own C0 in the lead's repo with `-f stage=member -f members=<lead's index>`; the student pages show `members=1`, which is right only if the lead is member 1.

1. `gh workflow run platform.yml -f stage=whatif`: the preflight, with `-Fix` (the lead's run also does the ALZ-lite what-if). Review the manual-check list it prints and confirm each one.
2. `gh workflow run platform.yml -f stage=member -f members=<index>`: deploys the datacenter, runs `Test-Datacenter.ps1` with both VMs running, and only if that passes onboards `vm-app01` to Azure Arc. The test comes before Arc because after Arc, run commands on `vm-app01` stop working and the in-VM checks fail. There is no portal fallback for Arc, by design (owner decision 2026-10-02).
3. A member without eligible Windows Server licenses (with Software Assurance) adds `-f no-hybrid-benefit=true` to the `member` run: the stage deploys and tests `vm-app01` without Azure Hybrid Benefit, and `vm-app01` bills about $0.75 an hour more (about $2.30 instead of $1.55 an hour while running).
4. `./scripts/Get-PipelineEvidence.ps1` downloads the `Test-Datacenter.ps1` output into `evidence/c00/` and writes the credentials file (see Expected evidence). The member commits the evidence file.
5. In the Arc resource's SQL Server blade, start (or review) the migration assessment.
6. The member connects to `vm-dev01` through Bastion, opens VS Code, signs in to GitHub and sends a message in Copilot Chat.
7. Before the event, the member may stop both VMs (`vm-app01`, `vm-dev01`) when not working, and must start them again before the platform lead runs the `vending` stage at T-1, because vending restarts both and the probes run inside them. During the event, never stop `vm-dev01`.

### Repair (coaches only)

Use this only when a run can't be repaired in time (rerun the stage first: the stages are idempotent). A coach runs the same scripts by hand from the member's `factory/` folder, with `$s` from their `.local/settings.json`. Students don't run these:

```powershell
./scripts/Test-Preflight.ps1 -WorkloadSubscriptionId $s.subscriptionId -Location $s.location -Fix   # the lead adds -SharedSubscriptionId $s.sharedSubscriptionId
./scripts/Deploy-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
./scripts/Test-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex
./scripts/Connect-DatacenterArc.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
```

- Add `-NoHybridBenefit` to `Deploy-Datacenter.ps1` and to `Test-Datacenter.ps1` for a member without eligible licenses, or the license row fails because the test expects `Windows_Server`.
- Never rerun Arc, and never redeploy the datacenter after Arc. Run the test before Arc, and don't ask for a re-run of it after.
- A datacenter redeployed after vending requires vending again (see Reset).
- A hand-run deploy writes `.local/<subscription-id>/datacenter.json` itself, so `Get-PipelineEvidence.ps1` isn't needed.

## Common mistakes

- Running preflight once and not re-running the `whatif` stage after resource provider registration (which takes up to 15 minutes to propagate) — leaves a false red.
- Trying a manual Arc onboarding through the portal "just to see" — this works but produces a differently-named Arc resource that later scripts (`Test-Datacenter.ps1`, the migration assessment lookups) won't find. Redo with the script if this happened.
- Turning Azure Hybrid Benefit off "to compare" and forgetting to turn it back on — it should stay on throughout.
- Leaving both VMs running between pre-work sessions — not a correctness problem, but worth a reminder since it's billing for nothing. Stopping `vm-dev01` during the event is the opposite mistake: it's the members' workstation.
- Evidence kept only on the member's laptop: ask them to copy it into `factory/evidence/c00/` in their own repo and push it to `main` before your T-3 review, because the review gates vending at T-1.
- Running Arc onboarding before `Test-Datacenter.ps1` (only possible in a hand-run repair). See the partial credit below.
- Arc **Connected** but no SQL Server instance after 5 minutes on an older copy of the kit: install the `WindowsAgent.SqlServer` extension from the portal (Azure Arc > Machines > `vm-app01` > Extensions). The current script installs it after 5 minutes (see [platform pipeline](../facilitator/platform-pipeline.md)).

## Partial credit

- A member without eligible licenses who ran the `member` stage with `no-hybrid-benefit`, with your agreement: score normally. The 2-point preflight row needs their stated reason and your agreement instead of "on", and the datacenter test must be green in that run (the stage tests without Hybrid Benefit too).
- Arc onboarding ran before `Test-Datacenter.ps1`: the in-VM rows can't pass after Arc, and the 3-point row allows "a coach-approved failure is explained" ([scoring rubric](../facilitator/scoring-rubric.md#c0--ready-to-hack), [automation map](../facilitator/automation-map.md)). Accept the in-VM FAIL, with the member's written explanation, if every Azure-side row (the ones that start with `azure:`: VM state, size and license type, Trusted Launch, disks, no public IPs, Bastion) is green and Arc shows Connected with the SQL instance. Redo only if an Azure-side row fails: that means the datacenter itself is wrong. The perf kit's planted data can't be checked after Arc, so look at it at the start of C9.
- Preflight and datacenter deployed, but Arc onboarding incomplete by the event's start: partial credit, and the member should prioritize finishing onboarding in the first break of day one rather than falling behind in C0 forever.
- No access to the first migration assessment (for example, Arc's own assessment feature is still initializing): accept the pre-Arc `Test-Datacenter.ps1` green output as sufficient evidence, and have the member pull the assessment first thing in C3.

## Reset

Rerunning the `member` stage is safe before Arc onboarding: it redeploys the datacenter with the same parameters, and the stage refuses to redeploy over Arc. There is no `-Force` parameter. What happens next depends on where the member is:

- **Vended, not Arc-enabled:** rerun the `member` stage, then the platform lead runs the `vending` stage for that member again (`-f members=<index>`; it restarts both of their VMs and records their exemptions again, because redeploying drops the DNS and route settings vending applied; see [C2](c02-secure-ai-ready-foundation.md#reset)).
- **Arc-enabled:** there's no in-place reset. The member deletes `rg-datacenter` in the portal (which also deletes `vm-dev01`, so they repeat the C0 task 7 setup), then reruns the `member` stage. If the member was already vended, the platform lead runs the `vending` stage for them again too.
