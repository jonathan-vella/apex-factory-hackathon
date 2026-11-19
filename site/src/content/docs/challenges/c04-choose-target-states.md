---
title: "C4: Choose target states"
description: Record your platform, migration-method, app and data decisions and deferred-work register in one concise team document.
---

## Background

C3 told you what the source looks like. C4 turns that into decisions the team stands behind. The kit has already fixed the target states, so the value here is the alternative you weighed and the consequence you accept, not the choice itself.

**Business context.** Dana, the CIO, has to take the plan to the board. C4 puts each decision in writing, with the road not taken and what the choice costs, so she can defend it.

**Business outcome.** Current platform. The decision table names the target stack (.NET 10, ASP.NET Core, App Service and SQL Managed Instance) and why each beats its alternative. Deferred work has an owner and a timeline, so nothing is forgotten.

**Objective.** Be able to record target-state architecture decisions with their alternatives and consequences, and track the work you are consciously deferring.

**Time and scope.** Day 1, **11:30**, **45 min**, **Team**.

## Challenge

**Starting point.** Everyone's triaged C3 findings (`factory/evidence/c03/triage.md`), including the trace-flag decision.

**Fixed by the kit.** The platform is the CoE archetype (App Service, container registry, SQL Managed Instance, Blob, Service Bus, Key Vault, Application Insights). The migration method is the Arc SQL migration assessment plus the MI link, online, with a planned cutover. The app target is .NET 10 and ASP.NET Core MVC. The data target is SQL Managed Instance with Microsoft Entra authentication only.

**You decide.** For each of the four areas (**Platform**, **Migration method**, **Application**, **Data**), review and refine the chosen target, the alternative you rejected, why the chosen target fits C1's outcomes and C3's findings, and the consequences/trade-offs you accept. Also assign an owner and timeline to each deferred item in the **Deferred-work register**.

:::note[Where to work]

<span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt; (VS Code &amp; pwsh)</span> — Work together on one shared screen in the team/pod lead's clone (`C:\src\<your-repo>` on `main` on `vm-dev01`). `Import-Kit.ps1` already pre-created `factory/evidence/c04/decisions-and-register.md` in your repository. Commit once in the team/pod lead's repository and share the completed file in the team channel.

:::

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

## Requirements

1. **Open `factory/evidence/c04/decisions-and-register.md` (5 min).** <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt;</span> Open the pre-created file in VS Code on the team/pod lead's `vm-dev01` (if missing, copy `factory/templates/attendee/decisions-and-register.md` to `factory/evidence/c04/decisions-and-register.md`).

2. **Complete the four-row Target-state decisions table (20 min).** <span class="sl-badge note">vm-dev01 · Shared screen</span> Review and tailor the four rows in **Target-state decisions**:
   - **Platform:** CoE archetype in the vended spoke (`App Service Linux P1v3`, `SQL MI GP Gen5 4 vCores`, private endpoints) vs custom Bicep from scratch or VM lift-and-shift.
   - **Migration method:** Managed Instance link (online seeding + planned cutover) and .NET SDK container publish to ACR vs offline backup/restore or Dockerfile build.
   - **Application:** .NET 10 ASP.NET Core MVC with `DefaultAzureCredential` (Blob Storage, Service Bus, Key Vault, OpenTelemetry) vs keeping .NET Framework 4.8 on a VM.
   - **Data:** Azure SQL Managed Instance General Purpose (Gen5, 4 vCores, 64 GB, AHB `BasePrice`, Entra authentication) vs SQL Server on an Azure VM.

3. **Complete the Deferred-work register table (15 min).** <span class="sl-badge note">vm-dev01 · Shared screen</span> Fill in **Deferred-work register** with:
   - Removing startup trace flags `-T1800` and `-T9567` on `vm-app01` after C7 cutover (`Prepare-MiLinkSource.ps1 -RemoveTraceFlags`), with an owner and timeline (`C7 Requirement 7`).
   - Tuning top resource-consuming queries on SQL MI with Query Store (`C9`).
   - Any additional findings deferred from C2 or C3 (such as enabling paid Microsoft Defender for Cloud workload plans post-hackathon).

4. **Commit once in the team/pod lead's repo and share (5 min).** <span class="sl-badge note">vm-dev01 · Team/pod lead</span> Commit `decisions-and-register.md` on `main` in the team/pod lead's repository and share it in the team channel:

   ```powershell title="vm-dev01 — C:\src\<your-repo> (pwsh)"
   cd C:\src\<your-repo>
   git pull --rebase
   git add factory/evidence/c04/decisions-and-register.md
   git commit -m "docs: C4 target-state decisions and deferred register"
   git push
   ```

## Success criteria

To complete this challenge, check the following in the team/pod lead's repo:

- [ ] `factory/evidence/c04/decisions-and-register.md` committed on `main` in the team/pod lead's repo and shared in the team channel.
- [ ] All four rows (**Platform**, **Migration method**, **Application**, **Data**) state the chosen target, an alternative considered, the reasoning tied to C1/C3, and the consequence/trade-off.
- [ ] The **Deferred-work register** lists the trace-flag removal after C7 cutover and other deferred items, each with a named owner, target resolution, and timeline.
- [ ] Outcome check: your decisions tie back to the top-ranked outcome from C1, and Dana could defend them to the board.

<details>
<summary>What goes in the register versus the decision table?</summary>

The decision table commits to a target architecture choice and trade-off. The deferred-work register tracks work you are explicitly sequencing later (such as removing the trace flags after the MI link is deleted in C7, or tuning queries in C9) with a named owner and timeline.

</details>

<details>
<summary>If you need to start over</summary>

There's nothing in Azure to reset. Edit `factory/evidence/c04/decisions-and-register.md` in place and commit on `main`.

</details>

## References

- [Architecture decision records overview](https://learn.microsoft.com/azure/well-architected/architect-role/architecture-decision-record)
- [Migration overview: SQL Server to Azure SQL Managed Instance](https://learn.microsoft.com/data-migration/sql-server/managed-instance/overview)

Next: [C5: Deploy the CoE archetype with APEX](../c05-deploy-the-coe-archetype/).
