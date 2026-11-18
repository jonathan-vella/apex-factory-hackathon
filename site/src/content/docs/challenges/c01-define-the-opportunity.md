---
title: "C1: Define the opportunity"
description: Act as Solution Architects to connect Contoso University's problems and triggers to CAF business outcomes, solutions and measurable KPIs.
---

## Background

You are Solution Architects at the Microsoft Solutions Partner that Contoso University hired. A solution architect does not start a modernization engagement with a list of Azure services. You start with the customer's problems and triggers, define the business outcomes those problems require, map each outcome to the solution that addresses it, and set measurable KPIs to verify that the solution worked.

This challenge follows the [Cloud Adoption Framework for Microsoft Azure (CAF) Strategy methodology](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/). Every decision in the factory traces along one chain:

```text
Problem / Trigger  -->  Business Outcome (CAF category)  -->  Solution  -->  KPI (verified in C5 to C10)
```

[The customer story](../../getting-started/customer-story/) introduces Contoso University, its four leaders (Dana, Priya, Marcus and Tomás), the problems that triggered this project, and the six business outcomes they want. In C1, your team connects those triggers to outcomes, solutions and KPIs, and ranks them in priority order.

**Business context.** Dana, the CIO, has asked your partner for a modernization plan she can take to the board. She cannot fund six outcomes at once. She needs a ranked plan that shows which problem each outcome solves, what your team will build to address it, and which KPI will prove it worked before the engagement closes.

**Business outcome.** All six, in order. The ranking sets what the team protects when time runs short on day two.

**Objective.** Connect customer problems and triggers to prioritized business outcomes, map each outcome to a CAF category and a concrete solution, and define KPIs you can measure later in the hackathon.

**Time and scope.** Day 1, **09:00**, **45 min**, **Team**. Everyone starts after the tech lead's kickoff. The team lead deployed the foundation before the event, so C1 needs no Azure access.

## Challenge

**Starting point.** The customer story: Contoso University, a legacy ASP.NET MVC 5 enrollment app on .NET Framework 4.8 and SQL Server on a single VM (`vm-app01`), the problems that triggered the engagement, and the six outcomes its leaders need.

**Fixed by the kit.** The six outcomes, the six modernization dimensions (application, data, platform, security, operations and cost), and the target architecture: .NET 10 on Azure App Service for Linux, Azure SQL Managed Instance, private endpoints, central logging, and cost tracked against the member subscription budget.

**How problems, outcomes, solutions and KPIs connect.** The outcome names are the kit's; map each to one of CAF's three motivation categories: **Reduce business risk**, **Accelerate innovation**, or **Enhance agility and efficiency**.

| Problem and trigger | Stakeholder | Business outcome (CAF category) | Solution in this factory | Verification KPI |
|---|---|---|---|---|
| Audit findings: SQL password in `Web.config`, unrestricted network paths, no central logging | Tomás (Security) | **Secure by default** (Reduce business risk) | Private endpoints, managed identity, Key Vault, ALZ `Deny` policies | 0 public data endpoints from the C8 checker; separately 0 stored passwords/keys from C6/C7 configuration checks |
| `.NET Framework 4.8` on a hand-patched VM with no container pipeline | Dana (CIO) | **Current platform** (Enhance agility and efficiency) | .NET 10 / ASP.NET Core MVC container on App Service for Linux | Verified container running on App Service (C6/C7) |
| Manual builds and configuration drift | Priya (IT operations) | **Repeatable provisioning** (Enhance agility and efficiency) | Bicep archetype through `azd`, with As-Built documentation | Clean provision and committed deployment record (C5) |
| Fragile releases and registrar downtime during cutover | Priya and Marcus | **Safe, repeatable change** (Reduce business risk) | Online SQL MI link and planned cutover with written recovery | Cutover within the planned window and matching row counts (C7) |
| Enrollment pages stall at registration peaks | Marcus (Registrar) | **Reliable at enrollment peaks** (Reduce business risk) | SQL MI and Query Store tuning for the five workloads | Measured duration/CPU reduction across all five workloads (C9) |
| Board needs an AI roadmap; data is siloed and ungoverned | Dana (CIO) | **Documented path to AI** (Accelerate innovation) | Governed SQL MI/Blob data and an AI-readiness gap register | Every gap has an owner and next action (C10) |

**You decide.** The priority rank (1 to 6) of the outcomes, why your top two come first and your sixth comes last, the specific target value for each KPI, the `Today:` and `Target:` summary across all six dimensions, and the one-sentence target outcome statement that defines "done" for Dana.

:::note[Where to work]

<span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt; (VS Code &amp; pwsh)</span> — Work on `vm-dev01` in the team/pod lead's clone (`C:\src\<your-repo>` on `main`) on one shared screen: one person types, everyone contributes. `Import-Kit.ps1` already pre-created `factory/evidence/c01/opportunity-canvas.md` in your repository.

:::

### Where your evidence goes

You work in your single private repo on `vm-dev01` (`C:\src\<your-repo>` on `main`). `Import-Kit.ps1` pre-populated `factory/evidence/` with the working templates (`c01/opportunity-canvas.md`, `c03/triage.md`, `c04/decisions-and-register.md`, `c07/cutover-rollback-runbook.md`, `c10/handover-and-ai-review.md`).

- **Team deliverables (C1, C4, C10):** The team (or breakout pod) writes the document together on the team/pod lead's screen, commits it once to `main` in the team/pod lead's repository (`C:\src\<your-repo>`), and shares it in the team channel for reference. Teammates do not need to copy-paste identical team files into their own repositories.
- **Member deliverables (C3, C5, C6, C7, C8, C9):** Committed in each member's own repository (`C:\src\<your-repo>` on `main`).

Use a conventional commit message (`type: Subject`, with a type of `feat`, `fix`, `docs` or `chore`), for example `docs: C1 opportunity canvas`. Never commit secrets, tenant IDs or subscription IDs.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

## Requirements

1. **Open the pre-created canvas.** <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt;</span> Open `factory/evidence/c01/opportunity-canvas.md` in VS Code on `vm-dev01` (if missing, copy it from `factory/templates/attendee/opportunity-canvas.md`). HTML comments in the template can stay in place.

2. **Map problems and triggers to ranked business outcomes (15 min).** <span class="sl-badge note">vm-dev01 · Shared screen</span> Rank the six outcomes from the customer story from 1 to 6. For each row in the table, fill in:
   - **Problem / Trigger:** the business or technical pain point that forces action now.
   - **Outcome (CAF category):** the kit's outcome name and its CAF motivation category: Reduce business risk, Accelerate innovation, or Enhance agility and efficiency.
   - **Voice:** who at the university cares most (Dana, Marcus, Priya or Tomás).
   - **Solution:** the modernization change in this factory that addresses the problem.
   - **KPI and Target:** what you will measure later in the hackathon (C5 to C10) and the target value that counts as success. Label any number you invent "illustrative target".

   Below the table, write one sentence on why your top two outcomes come first and one sentence on why your sixth outcome comes last.

3. **Six dimensions (10 min).** <span class="sl-badge note">vm-dev01 · Shared screen</span> For each of application, data, platform, security, operations and cost, write two lines: `Today:` and `Target:`. Use the kit's fixed target architecture where it applies.

4. **Target outcome statement (5 min).** <span class="sl-badge note">vm-dev01 · Shared screen</span> Fill in the **Target outcome** section with one sentence linking the customer trigger, the modernized solution, and the measurable business outcome that Dana can take to the board as the definition of "done" at the end of day two. Make sure every teammate can state it from memory.

5. **Open questions and commit (10 min).** <span class="sl-badge note">vm-dev01 · Team/pod lead</span> Record any trade-offs the team has not settled yet under **Open questions** (C4 resolves them). Then the team/pod lead commits `opportunity-canvas.md` on `main` and shares it in the team channel:

   ```powershell title="vm-dev01 — C:\src\<your-repo> (pwsh)"
   cd C:\src\<your-repo>
   git pull --rebase
   git add factory/evidence/c01/opportunity-canvas.md
   git commit -m "docs: C1 opportunity canvas"
   git push
   ```

   Don't commit tenant IDs, subscription IDs or secrets.

## Success criteria

To complete this challenge, review with your coach in the team/pod lead's repo:

- [ ] `factory/evidence/c01/opportunity-canvas.md`, committed on `main` in the team/pod lead's repo and shared in the team channel, with all six outcomes ranked and each mapped to a problem/trigger, a CAF outcome category, a stakeholder voice, a solution, a KPI and a target.
- [ ] Each of the six dimensions has both a `Today:` and a `Target:` line.
- [ ] A one-sentence target outcome statement linking trigger, solution and measurable outcome that the whole team can repeat.
- [ ] Outcome check: the KPI for your top-ranked outcome is one you will verify in C8, C9 or C10.

Next, continue with [C2: Secure, AI-ready foundation](../c02-secure-ai-ready-foundation/).

<details>
<summary>We don't agree on the ranking order</summary>

Time-box the disagreement: record both views under **Open questions** and move on. Rank by what Dana would fund first if she could fund only one outcome. C4's target-state decisions are where you lock specific technical trade-offs; C1 sets business priority and measurable outcomes.

</details>

<details>
<summary>What is the difference between a business outcome and a KPI?</summary>

A business outcome states the change the organization needs, such as "Secure by default (risk reduction and compliance)." A KPI is the measurement that proves it: 0 public data endpoints from the C8 checker, and separately 0 stored passwords or keys from the C6/C7 configuration checks. The checker does not scan for secrets.

</details>

<details>
<summary>We're not sure what counts as a "dimension"</summary>

Application: code and framework. Data: storage and schema. Platform: compute and networking. Security: identity and secrets. Operations: telemetry and support. Cost: what you'll spend and how you'll justify it. One line each for `Today:` and `Target:` is enough for C1.

</details>

<details>
<summary>If you need to start over</summary>

- **Redo the canvas:** copy the template over your file again with `Copy-Item factory\templates\attendee\opportunity-canvas.md factory\evidence\c01\opportunity-canvas.md -Force`.

</details>

## References

- [Cloud Adoption Framework: Strategy methodology](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/)
- [CAF: Determine your motivations, mission, and objectives](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/motivations)
