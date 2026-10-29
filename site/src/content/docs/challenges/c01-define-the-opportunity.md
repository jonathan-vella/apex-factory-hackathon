---
title: "C1: Define the opportunity"
description: Act as Solution Architects to connect Contoso University's problems and triggers to CAF business outcomes, solutions and measurable KPIs.
---

## Background

You are Solution Architects at the Microsoft Solutions Partner that Contoso University hired. A solution architect does not start a modernization engagement with a list of Azure services. You start with the customer's problems and triggers, define the business outcomes those problems require, map each outcome to the solution that addresses it, and set measurable KPIs to verify that the solution worked.

This challenge follows the [Cloud Adoption Framework for Microsoft Azure (CAF) Strategy methodology](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/). Every decision in the factory traces along one chain:

```text
Problem / Trigger  -->  Business Outcome (CAF category)  -->  Solution  -->  KPI (verified in C8, C9 or C10)
```

[The customer story](../../getting-started/customer-story/) introduces Contoso University, its four leaders (Dana, Priya, Marcus and Tomás), the problems that triggered this project, and the six business outcomes they want. In C1, your team connects those triggers to outcomes, solutions and KPIs, and ranks them in priority order.

**Business context.** Dana, the CIO, has asked your partner for a modernization plan she can take to the board. She cannot fund six outcomes at once. She needs a ranked plan that shows which problem each outcome solves, what your team will build to address it, and which KPI will prove it worked before the engagement closes.

**Business outcome.** All six, in order. The ranking sets what the team protects when time runs short on day two.

**Objective.** Connect customer problems and triggers to prioritized business outcomes, map each outcome to a CAF category and a concrete solution, and define KPIs you can measure later in the hackathon.

**Time and points.** Team, **45 min**, **10 pts** (team). Everyone starts here at 09:00, right after the tech lead's 30-minute kickoff presentation. The team lead deployed the foundation before the event, so C1 needs no Azure access.

The one-time evidence setup takes about 5 minutes and requirements 2 to 5 add up to 40, so keep to the times given. Do the folder setup while teammates read the canvas template.

## Challenge

**Starting point.** The customer story: Contoso University, a legacy ASP.NET MVC 5 enrollment app on .NET Framework 4.8 and SQL Server on a single VM (`vm-app01`), the problems that triggered the engagement, and the six outcomes its leaders need.

**Fixed by the kit.** The six outcomes, the six modernization dimensions (application, data, platform, security, operations and cost), and the target architecture: .NET 10 on Azure App Service for Linux, Azure SQL Managed Instance, private endpoints, central logging, and cost tracked against the member subscription budget.

**How problems, outcomes, solutions and KPIs connect.** Use this CAF Strategy mapping as your reference when filling out the canvas:

| Problem and trigger | Stakeholder | Business outcome (CAF category) | Solution in this factory | Verification KPI |
|---|---|---|---|---|
| Audit findings: SQL password in `Web.config`, unrestricted network paths, no central logging | Tomás (Security) | **Secure by default** (Risk reduction and compliance) | Private endpoints, Entra managed identity, Key Vault, Azure Landing Zone `Deny` policies | `Test-Acceptance.ps1` passes with 0 secrets in config and 0 public data endpoints (C8) |
| `.NET Framework 4.8` on a single hand-patched Windows VM (`vm-app01`) with no container pipeline | Dana (CIO) | **Current platform** (Agility and technical debt reduction) | `.NET 10` and ASP.NET Core MVC container on Azure App Service for Linux | App running on `.NET 10` container image in Azure Container Registry (C6 and C7) |
| Manual server builds and configuration drift across environments | Priya (Infra) | **Repeatable provisioning** (Operational efficiency) | Bicep CoE archetype deployed via `azd provision` with an As-Built record | Clean `azd provision` from the repo and committed deployment record (C5) |
| Fragile manual releases and fear of registrar downtime during database cutover | Priya (Infra) and Marcus (DBA) | **Safe, repeatable change** (Reliability and risk reduction) | Online SQL MI link replication and planned cutover with a written rollback | Cutover completed within the planned window with matching row counts (C7) |
| Course catalog and enrollment pages stall during start-of-term registration peaks | Marcus (DBA) | **Reliable at enrollment peaks** (Customer experience and performance) | SQL Managed Instance with Query Store baseline and post-fix tuning for the top 5 queries | Measured query duration and CPU reduction across all 5 workloads in Query Store (C9) |
| Board wants an AI roadmap, but academic data is siloed on `vm-app01` and ungoverned | Dana (CIO) | **Documented path to AI** (Innovation and growth) | Governed SQL MI and Blob data estate plus an AI readiness gap register | Completed AI readiness review with every gap assigned an owner and next action (C10) |

**You decide.** The priority rank (1 to 6) of the outcomes, why your top two come first and your sixth comes last, the specific target value for each KPI, the `Today:` and `Target:` summary across all six dimensions, and the one-sentence target outcome statement that defines "done" for Dana.

**Where to work.** The dev container of your own repo, and only there: it has the tools and the GitHub sign-in you set up in [Step 1: Repo and preflight](../../deploy/set-up-your-repo/). Don't use a terminal outside the container. On event day, open VS Code on your repo and choose **Reopen in Container** if it isn't already open in it. The terminal opens at the repo root, so you don't need to `cd`. Work on one shared screen: one person types, everyone contributes. To save a screenshot or a chat file from your laptop into `factory/evidence/c01/`, drag it into that folder in VS Code's Explorer.

### Where your evidence goes

The team doesn't collect evidence in a common repository. You work in one private repo of your own (the one from [Step 1: Repo and preflight](../../deploy/set-up-your-repo/), with the kit in `factory/` and the import merged into `main`). Your evidence lives in it, on `main`, under `factory/evidence/cNN/` (`c01` to `c10`), next to `factory/evidence/readiness/` from Step 3. Your coach reads each member's repo to score it. One rule says where to commit:

- **Dev container:** evidence goes in `factory/evidence/` on `main`; run `git pull` first.
- **`vm-dev01`:** evidence goes in `C:\src\<your-repo>\factory\evidence\...` (the plain clone of your own repo) on `main`; run `git pull --rebase` first.

Why `factory/`: the repo's lint and format ignores cover it, so evidence files don't trip the pre-commit hooks, and the weekly upstream sync leaves it alone.

Commit messages in your own repo must be conventional commits (`type: Subject`, with a type of `feat`, `fix`, `docs` or `chore`), or the commit hook rejects them. For example `docs: C1 opportunity canvas`. If the hook rejects a message, fix it and commit again. Commit evidence with plain `git` and push to `main`; no pull request is needed. Don't use `/apex-git-commit` for this: it skips some paths and refuses `main`. Never commit secrets, tenant IDs or subscription IDs.

**Team deliverables** (the C1 canvas, C4's team ADRs, the C10 package): the team writes one document together on one person's screen. Then the typist posts the final file in the team channel, and every teammate saves it unchanged under the same name in their own `factory/evidence/cNN/` and commits it. A team item is scored once per team, from the team lead's copy, so the other copies must match it.

<details>
<summary>Set up the evidence folders once (about 5 minutes)</summary>

In the dev container terminal, at the repo root:

```bash
git pull
cp -rn factory/templates/team/evidence/. factory/evidence/
cp factory/templates/team/README.md factory/evidence/README.md
git add factory/evidence
git commit -m "docs: add evidence folders"
git push
```

The `-n` keeps anything you already created in Step 3 (such as `factory/evidence/readiness/`), and the command works whether or not `factory/evidence/` exists yet.

</details>

## Requirements

1. **Copy the template.** In your own repo, copy `factory/templates/attendee/opportunity-canvas.md` to `factory/evidence/c01/opportunity-canvas.md`:

   ```bash
   cp factory/templates/attendee/opportunity-canvas.md factory/evidence/c01/opportunity-canvas.md
   ```

2. **Map problems and triggers to ranked business outcomes (15 min).** Rank the six outcomes from the customer story from 1 to 6. For each row in the table, fill in:
   - **Problem / Trigger:** the business or technical pain point that forces action now.
   - **Outcome (CAF category):** the outcome name and its Cloud Adoption Framework category (for example risk reduction, agility, operational efficiency, reliability, performance or innovation).
   - **Voice:** who at the university cares most (Dana, Marcus, Priya or Tomás).
   - **Solution:** the modernization change in this factory that addresses the problem.
   - **KPI and Target:** what you will measure in C8, C9 or C10 and the target value that counts as success. Label any number you invent "illustrative target".

   Below the table, write one sentence on why your top two outcomes come first and one sentence on why your sixth outcome comes last.

3. **Six dimensions (10 min).** For each of application, data, platform, security, operations and cost, write two lines: `Today:` and `Target:`. Use the kit's fixed target architecture where it applies.

4. **Target outcome statement (5 min).** Fill in the **Target outcome** section with one sentence linking the customer trigger, the modernized solution, and the measurable business outcome that Dana can take to the board as the definition of "done" at the end of day two. Make sure every teammate can state it from memory.

5. **Open questions and commit (10 min).** Record any trade-offs the team has not settled yet under **Open questions** (C4 resolves them in ADRs). Then the typist runs `git pull`, commits, and posts `opportunity-canvas.md` in the team channel. Every teammate saves the file unchanged as `factory/evidence/c01/opportunity-canvas.md` in their own repo and commits it:

   ```bash
   git add factory/evidence/c01/opportunity-canvas.md
   git commit -m "docs: C1 opportunity canvas"
   git push
   ```

   Don't commit tenant IDs, subscription IDs or secrets.

## Success criteria

To complete this challenge, show your coach in your own repo:

- [ ] `factory/evidence/c01/opportunity-canvas.md`, committed on `main`, with all six outcomes ranked and each mapped to a problem/trigger, a CAF outcome category, a stakeholder voice, a solution, a KPI and a target (with no template placeholder comments left in place). Scored once per team from the team lead's copy.
- [ ] Each of the six dimensions has both a `Today:` and a `Target:` line, and no `<!-- ... -->` comment lines remain in the file.
- [ ] A one-sentence target outcome statement linking trigger, solution and measurable outcome that the whole team can repeat.
- [ ] Every teammate's copy is committed on `main` of their own repo and matches the team lead's.
- [ ] Outcome check (unscored guidance): the KPI for your top-ranked outcome is one you will verify with evidence in C8, C9 or C10.

Next, continue with [C2: Secure, AI-ready foundation](../c02-secure-ai-ready-foundation/).

<details>
<summary>We don't agree on the ranking order</summary>

Time-box the disagreement: record both views under **Open questions** and move on. Rank by what Dana would fund first if she could fund only one outcome. C4's architecture decision records (ADRs) are where you lock specific technical trade-offs; C1 sets business priority and measurable outcomes.

</details>

<details>
<summary>What is the difference between a business outcome and a KPI?</summary>

A business outcome states the change the organization needs, such as "Secure by default (risk reduction and compliance)." A KPI is the concrete measurement that proves the outcome was achieved, such as "`Test-Acceptance.ps1` reports 0 secrets in configuration and 0 public data endpoints in C8."

</details>

<details>
<summary>We're not sure what counts as a "dimension"</summary>

Application: code and framework. Data: storage and schema. Platform: compute and networking. Security: identity and secrets. Operations: telemetry and support. Cost: what you'll spend and how you'll justify it. One line each for `Today:` and `Target:` is enough for C1.

</details>

<details>
<summary>If you need to start over</summary>

- **Redo the canvas:** copy the template over your file again with `cp factory/templates/attendee/opportunity-canvas.md factory/evidence/c01/opportunity-canvas.md`. This replaces everything you wrote, so copy your text somewhere first if you want to keep any of it. If your team already agreed on a version, the typist posts the file in the team channel again and every teammate saves it unchanged.
- **The evidence folder has the wrong layout** (you see `factory/evidence/evidence/`): move the folders up a level with `cp -rn factory/evidence/evidence/. factory/evidence/`, then remove `factory/evidence/evidence` with `rm -r`, and commit.

</details>

**Bonus.** None for C1.

## References

- [Cloud Adoption Framework: Strategy methodology](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/)
- [Cloud Adoption Framework: Define business outcomes](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/business-outcomes)
- [Cloud Adoption Framework: Cloud adoption motivations](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/motivations)
- [Assess .NET apps for migration to Azure App Service](https://learn.microsoft.com/azure/app-service/app-service-migration-assess-net)
