# Automation map

What the kit automates, what people still do, and where attendees tend to stall. Read it with the [run of show](../facilitator/agenda.md). "Automated" means the infrastructure and the checks. Every deployment is a script or command the attendee starts, nothing deploys on its own, and agents never change Azure.

## How to read the table

- **Script** is a kit script or the `azd` flow. It does the same thing each time.
- **Agent** is GitHub Copilot with an agent or skill. The result varies between runs, so a person reviews it.
- **Person** is a decision, a portal step or a judgement. No script does it.
- **Checked live** means a person ran it end to end on the current kit. Anything else is marked.

## By phase

| Phase | Script | Agent | Person | Checked live |
|---|---|---|---|---|
| Pre-reqs | `Import-Kit.ps1`, `Initialize-Settings.ps1`, `Test-Preflight.ps1` | none | Create the repo from the template, open the dev container, sign in (`az`, `azd`, `gh`), coach assigns the member index | Yes |
| C0 | `Deploy-Datacenter.ps1`, `Test-Datacenter.ps1` (46 checks), `Connect-DatacenterArc.ps1` | none | Run them in order, at T-3, in the member's own repo: **the test goes before Arc**, because run commands stop working after Arc. Run the first Arc assessment in the portal. Set up `vm-dev01`. A coach reviews every member's output before vending | Yes |
| C1 | One `cp` creates the evidence folders | none | The team writes the canvas on one screen. Every member commits a copy | Pages only |
| C2 | `Deploy-AlzLite.ps1` (T-7), `Deploy-Vending.ps1`, `New-DatacenterExemptions.ps1` and `Test-Connectivity.ps1` (T-1, and the probes again on Day 1) | none | The platform lead deploys ALZ-lite at T-7 and vends every member, one after another, at T-1. **A Privileged Role Administrator grants the SQL MI identity its Graph read at T-7, once per team.** On Day 1 the team verifies and explains it, and the coach asks the policy questions | Yes (the scripts). The new event order hasn't been rehearsed |
| C3 | none | Upgrade agent assessment and plan | Review both assessments, triage every finding, reason about the trace flags by hand | Yes, on Local VS Code |
| C4 | none | none | The team writes the ADRs and the deferred-work register | n/a |
| C5 | `/apex-adapt-archetype` (checks, `azd env`, preflight, preview), `azd provision` with post-deploy tests | `08-As-Built` | The member decides to deploy and runs `azd provision`. Confirm the result | Yes |
| C6 | `sdk-container-publish` | Seven Upgrade agent tasks | Switch to `vm-dev01`. Review each task. Run the gap searches. Push the image. Check the App Service configuration | Yes, on Local VS Code |
| C7 | `Prepare-MiLinkSource.ps1` (inside a Bastion session) | none | Create the MI link in the portal, wait for seeding, validate the replica in SSMS, stop the writers, cut over in the portal (not the CLI), write the secret and database user, repoint the web app, remove the trace flags, write the runbook | Link: yes (B07, B10) |
| C8 | `Test-Acceptance.ps1` (security checker) | none | Smoke, upload and notification checks in the browser. Light load run. Record the results | Partly: the front-end checks passed in B10 |
| C9 | `Start-Workload.ps1`, `Reset-PerfKit.ps1` | Fix suggestions | Read Query Store, fix the five planted issues, record before and after | Data and workload: yes. The fixes on a real MI: not yet (B13) |
| C10 | none | none | Package one asset, complete the acceptance and AI-readiness documents, prepare the showcase | n/a |
| Cleanup | `Remove-FactoryEnvironment.ps1` (member and team scope) | none | After the event, delete the shared identity and its Graph grants, then verify nothing billable is left | Member scope: yes (B10). Team scope: not yet (B13) |

## The platform pipeline (preferred)

The platform pipeline runs the same scripts from GitHub Actions instead of a terminal. It is the preferred path, and the scripts above stay supported: a team that never sets it up loses nothing. Students have a [page for each path](https://factory.apexops.pro/guides/deploy-with-actions/) (see also [Deploy with scripts](https://factory.apexops.pro/guides/deploy-with-scripts/)), each with a platform lead and a member section.

| Piece | What it is |
|---|---|
| `.github/workflows/platform.yml` | The one workflow, with a `stage` input: `whatif`, `member`, `foundation`, `vending`, `teardown` or `all`. Each stage runs in the `gh-lab` environment and needs an approval (`teardown` needs two: members, then the team) |
| `scripts/Initialize-PlatformPipeline.ps1` | Sets the pipeline up once per repo: the managed identity, its federated credential, its roles and the `gh-lab` environment. `-Profile Member` is for a member's own repo (preflight, datacenter, test and Arc); the default platform lead profile is for the lead's repo (ALZ-lite and vending for the roster) |
| `scripts/Invoke-PipelineVending.ps1` | Vends each member in order, restarts both VMs, records the exemptions and runs the connectivity probes |
| `scripts/Assert-PipelineGuard.ps1`, `Test-PipelineSetup.ps1`, `Test-PipelinePermissions.ps1`, `Get-PipelineEvidence.ps1`, `Remove-PlatformPipeline.ps1` | The fail-closed guard, setup and permission checks, the C0 evidence download and the identity removal |

In the new order, the platform lead's repo runs the `foundation` stage at T-7 (run 1) and the `vending` stage at T-1 (run 2). Members can run the `whatif` and `member` stages in their own repos for C0 at T-3. The [platform pipeline page](platform-pipeline.md) holds the coach details: the accepted risk, the gates, who can run what, the manual steps that remain and what was tested. After the event, the `teardown` stage and then `Remove-PlatformPipeline.ps1` remove everything (see [cleanup](cleanup.md)).

## Where attendees stall

- **The Graph grant (C2).** Only a Privileged Role Administrator can make it. Book that person for T-7, right after ALZ-lite, not for the day.
- **Vending is serial (C2).** One platform lead vends everyone at T-1, and it comes after the coach's C0 review. A member whose datacenter isn't reviewed waits, and a datacenter redeployed after vending must be vended again.
- **Arc order (C0).** Running the Arc script before `Test-Datacenter.ps1` leaves the in-VM checks unable to pass. The fix is to keep the earlier output.
- **MI link seeding (C7).** The wait is long and nothing speeds it up. Start the link before the member finishes C6. Cutover is a portal action, and the CLI command fails.
- **Writers after cutover (C7).** The source stays writable, so any write after the last lag reading is lost.
- **Agent runs vary (C3, C5, C6).** The same task can give a different result each time, so check the result before the member moves on. When a member is blocked after trying the documented fixes, that is what the lifelines are for.

## What is not validated

- **The GitHub Copilot app.** Local VS Code is the validated path. The app is a best-effort option, and VS Code is the fallback. See the student page [Copilot app (best effort)](../site/src/content/docs/prompts/copilot-app.md).
- **A live run of the re-packaged archetype scripts.** The previous package deployed and ran. The new one passed provider validation but has not had a live `azd provision`, so ask members to tell you if `preflight.ps1`, the post-deploy tests or the deployment summary misbehave.
- **The full flow in one rehearsal.** The pieces were checked one at a time. The dry run in B13 is the first time the whole path runs, and the new event order (ALZ-lite at T-7, vending at T-1) has not been rehearsed as an event.
