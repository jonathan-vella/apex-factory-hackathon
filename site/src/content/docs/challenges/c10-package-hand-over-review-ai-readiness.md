---
title: "C10: Package, hand over, review AI readiness"
description: Close out the engagement as a team — reusable asset, handover, and an honest AI-readiness review.
---

## Goal

Leave the engagement with one reusable asset, a complete handover, an AI-readiness gap register, and a showcase of what the team actually built.

## Scope and time box

Team. **60 min**.

## Points

**20 pts** (team).

## Inputs

Every prior challenge's evidence, in each member's own repo: the `factory/evidence/cNN/` folders for C1 to C9, including every member's C8 acceptance pack in `factory/evidence/c08/`. Each member packages in their own repo, which may be private, so share files instead of opening each other's repos. Ask every teammate to share their C8 pack (their `factory/evidence/c08/acceptance-handover.md` and its `acceptance.json`) on one screen or in your team chat, and save each as `factory/evidence/c10/member-packs/member-<n>.md` (and `member-<n>-acceptance.json`), where `<n>` is that member's index.

## Where to run

In the dev container of your own repo, with VS Code open on it (the repo you created in [Set up your repo](../../deploy/set-up-your-repo/)): no `vm-dev01` or Azure access is needed. Run `git pull` first, so you start from the latest `main`. Write the package together on one person's screen, in `factory/evidence/c10/`. Split the work so nobody waits: one person on the handover (task 2), one on the gap register and checklist (tasks 3 and 4), and the others on the asset (task 1) and the showcase (task 5), then swap to review each other's parts. One person types each document. When the files are final, every teammate saves the final files under the same names in their own `factory/evidence/c10/`, commits with a conventional message (for example `docs: C10 package`) and pushes `main`. Your evidence goes in `factory/evidence/` on `main`. The package is scored once for the team, from the team lead's copy, so the other copies must match it.

Plan about 60 minutes in total: 15 for the asset, 15 for the handover, 10 for the register, 5 for the checklist and 15 for the showcase. If you're short of time, a two-minute verbal showcase with one screen shown still counts.

## Your tasks

1. Package one reusable asset from the engagement — the archetype adaptation, the modernization playbook run, or the perf kit fixes — as something another team could pick up without you in the room. Copy the files into `factory/evidence/c10/reusable-asset/` (for example the adapted archetype folder from a member's own repo, or the five fix scripts from `factory/evidence/c09/`) with a short README that says what a new team must supply and how to run it.
2. Complete the acceptance and handover document for the whole engagement: copy `factory/templates/attendee/acceptance-handover.md` to `factory/evidence/c10/acceptance-handover.md` (the [template on GitHub](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/acceptance-handover.md)). In its handover summary, name every member and link their pack in `factory/evidence/c10/member-packs/`, and say who the engagement is handed to and how they operate it.
3. Copy `factory/templates/attendee/ai-readiness-gap-register.md` to `factory/evidence/c10/` and fill it in, honestly: where GitHub Copilot's agents needed a human to unblock them, where coach support was used, and what that implies for running this unattended at a customer. Delete the template's example rows.
4. Copy `factory/templates/attendee/factory-kit-checklist.md` to `factory/evidence/c10/` and run through it as a final sanity pass across the team's deliverables.
5. Prepare a short showcase: what was modernized, what's deferred, and the single most useful thing Copilot did for the team. Write the outline in `factory/evidence/c10/showcase.md`, then deliver it to your coach.

## Evidence

- The packaged reusable asset, committed in `factory/evidence/c10/reusable-asset/` and referenced from the handover document.
- The completed acceptance and handover document (`factory/evidence/c10/acceptance-handover.md`), covering every team member.
- The AI-readiness gap register, with at least one entry for each time the team used coach support (if any), and a credible one if none was used.
- The factory-kit checklist, all items addressed.
- The showcase outline (`factory/evidence/c10/showcase.md`), delivered to your coach.

## Hints

<details>
<summary>What makes an asset "reusable"?</summary>

Someone outside the team should be able to run it without first asking you a question. If your packaging still assumes tribal knowledge from the two days, it isn't done yet.
</details>

<details>
<summary>We didn't use any coach support — is the gap register empty then?</summary>

No — the register should also note where a human review step (not coach support) was still essential, even though nothing broke. Look back over the challenges for the points where the kit deliberately keeps a person in charge, and record them as the current state of AI readiness, not as gaps to close. Ask your coach if you want a nudge.
</details>

## If you need to start over

C10 produces documents only, so there is no deployed state to reset. To redo a document, delete it from `factory/evidence/c10/` and copy its template again from `factory/templates/attendee/`. If teammates' copies drift apart, one person's final files win: everyone saves those over their own.

## Bonus

Up to 10 pts for a showcase that includes a live demo of the modernized app against SQL Managed Instance, not just slides. Bonus points from all challenges share one cap of 30 points per team.

## Learn more

- [Cloud Adoption Framework: govern and manage](https://learn.microsoft.com/azure/cloud-adoption-framework/govern/)
