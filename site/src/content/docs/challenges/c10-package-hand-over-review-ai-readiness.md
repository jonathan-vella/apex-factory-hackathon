---
title: "C10: Package, hand over, review AI readiness"
description: Close out the engagement as a team with a reusable asset, a concise handover summary and an honest AI-readiness review.
next: false
---

## Background

Modernizing one app is only worth it if the next team can repeat it and the customer can run what you built. C10 closes the engagement: you package something reusable, record the team's handover and AI-readiness review in one concise document, and deliver your 5-minute showcase.

**Business context.** Dana, the CIO, has to tell the board what the university can do next and what it can't yet. C10 hands over what the team built and says how ready the university is to run AI on it.

**Business outcome.** Documented path to AI. The handover says what is ready for AI use and what is not, with an owner and a next step for each gap, and another team can repeat the work from the package.

**Objective.** Be able to package a reusable asset, complete a handover, and assess how ready a customer is to run GitHub Copilot's agents unattended.

**Time and scope.** Day 2, **15:15**, **60 min**, **Team**.

## Challenge

**Starting point.** Each member's completed C8 `acceptance.json` and live check results, plus C9's five `.sql` fix scripts and Query Store `baseline` vs `after` improvement.

**Fixed by the kit.** The pre-created `factory/evidence/c10/handover-and-ai-review.md` template in the team/pod lead's repository.

**You decide.** Which asset to package into `factory/evidence/c10/reusable-asset/`, where Copilot's agents needed a human during the two days, and your talking points for the 5-minute team showcase.

:::note[Where to work]

<span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt; (VS Code &amp; pwsh)</span> — Work together on one shared screen in the team/pod lead's clone (`C:\src\<your-repo>` on `main` on `vm-dev01`). `Import-Kit.ps1` already pre-created `factory/evidence/c10/handover-and-ai-review.md` in your repository. Commit `reusable-asset/` and `handover-and-ai-review.md` once in the team/pod lead's repository and share the completed file in the team channel (teammates do not need to copy-paste `member-packs/` or duplicate files across every repository).

:::

## Requirements

1. **Package one reusable asset (`factory/evidence/c10/reusable-asset/`, 20 min).** <span class="sl-badge note">vm-dev01 · Team/pod lead</span> Package one reusable asset from the engagement—the adapted archetype Bicep (`infra/bicep/university/`), the modernization playbook and `.github/upgrades/scenarios/dotnet-version-upgrade/plan.md`, or the five C9 `.sql` fix scripts (`factory/evidence/c09/*.sql`)—into `factory/evidence/c10/reusable-asset/` in the team/pod lead's repository, along with a short `README.md` explaining what inputs the next delivery team supplies and how to run it.

2. **Complete `factory/evidence/c10/handover-and-ai-review.md` (25 min).** <span class="sl-badge note">vm-dev01 · Shared screen</span> Open the pre-created `factory/evidence/c10/handover-and-ai-review.md` in the team/pod lead's repository (if missing, copy `factory/templates/attendee/handover-and-ai-review.md` to `factory/evidence/c10/handover-and-ai-review.md`) and fill in its four sections:
   - **Member acceptance and optimization summary (C8 & C9):** one row per member recording their C8 `acceptance.json` verdict (`ACCEPT`), their C8 live checks (smoke pages, Blob upload, Service Bus toast, 20-request burst, App Insights), and their C9 Query Store CPU/duration improvement (`baseline` vs `after`).
   - **Reusable factory asset:** what `factory/evidence/c10/reusable-asset/` packages and how the next engagement runs it.
   - **AI-readiness gap register:** where a human had to step in during C1–C9 (including any coach support or lifeline used), why the agent could not complete it alone, and the next step for customer engagements.
   - **Showcase talking points (5 minutes):** business outcomes met from C1, the most valuable GitHub Copilot workflow, one guardrail that caught a mistake, and remaining deferred items handed to operations.

3. **Commit in the team/pod lead's repository and deliver the showcase (15 min).** <span class="sl-badge note">vm-dev01 · Team/pod lead</span> Commit `factory/evidence/c10/` (after confirming no tenant, subscription, or object IDs appear) on `main` in the team/pod lead's repository, share `handover-and-ai-review.md` in the team channel, and present your 5-minute showcase at 16:15:

   ```powershell title="vm-dev01 — C:\src\<your-repo> (pwsh)"
   cd C:\src\<your-repo>
   git pull --rebase
   git add factory/evidence/c10
   git commit -m "docs: C10 reusable asset, handover and AI-readiness review"
   git push
   ```

## Success criteria

To complete this challenge, review with your coach in the team/pod lead's repo:

- [ ] `factory/evidence/c10/reusable-asset/` committed on `main` in the team/pod lead's repo with a short `README.md`.
- [ ] `factory/evidence/c10/handover-and-ai-review.md` committed on `main` in the team/pod lead's repo (and shared in the team channel), covering every member's C8 and C9 results, the AI-readiness gap register, and the showcase talking points.
- [ ] 5-minute team showcase delivered at 16:15.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

<details>
<summary>What makes an asset "reusable"?</summary>

Someone outside the team should be able to run it without first asking you a question. If your packaging still assumes tribal knowledge from the two days, add the missing inputs or commands to `reusable-asset/README.md`.

</details>

<details>
<summary>We didn't use any coach support. Is the AI-readiness gap register empty then?</summary>

No. Record where a human review gate was still essential (for example, reviewing `azd provision --preview` in C5, verifying local app runs after each Upgrade task in C6, or confirming zero replication lag before C7 cutover) and what that means for running agents unattended at a customer.

</details>

<details>
<summary>If you need to start over</summary>

C10 produces documents only, so there is no deployed state to reset. Edit `factory/evidence/c10/handover-and-ai-review.md` in place and commit on `main`.

</details>

## References

- [Cloud Adoption Framework: AI adoption](https://learn.microsoft.com/azure/cloud-adoption-framework/ai/strategy)
- [Cloud Adoption Framework: Manage](https://learn.microsoft.com/azure/cloud-adoption-framework/manage/ready-cloud-operations)

After the showcase, save your work and follow [Tear down (T+2)](../../deploy/tear-down/) (or [Tear down: Lead-provisioned cohort](/deploy/lead-setup/tear-down/)).
