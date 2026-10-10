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

Every prior challenge's evidence, across the team, in the team repo's `evidence/` folder: each member's C0 to C9 folders (`evidence/cNN/member-<n>/`), including every member's C8 acceptance pack in `evidence/c08/member-<n>/`.

## Where to run

On your own computers, in the team repo's folder (the clone from C1, next to your own repo). No VM, dev container or Azure access is needed. Everything goes in `evidence/c10/`. Split the work so nobody waits: one person on the handover (task 2), one on the gap register and checklist (tasks 3 and 4), and the others on the asset (task 1) and the showcase (task 5), then swap to review each other's parts. Run `git pull` first, commit only your own files, then `git pull --rebase` and `git push`.

Plan about 60 minutes in total: 15 for the asset, 15 for the handover, 10 for the register, 5 for the checklist and 15 for the showcase. If you're short of time, a two-minute verbal showcase with one screen shown still counts.

## Your tasks

1. Package one reusable asset from the engagement — the archetype adaptation, the modernization playbook run, or the perf kit fixes — as something another team could pick up without you in the room. Copy the files into `evidence/c10/reusable-asset/` (for example the adapted archetype folder from a member's own repo, or the five fix scripts from `evidence/c09/`) with a short README that says what a new team must supply and how to run it.
2. Complete the [acceptance and handover](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/acceptance-handover.md) document for the whole engagement in `evidence/c10/`, pulling in each member's C8 acceptance pack from `evidence/c08/member-<n>/`. Name every member and link their pack.
3. Fill in the [AI-readiness gap register](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/ai-readiness-gap-register.md), honestly: where GitHub Copilot's agents needed a human to unblock them, where a lifeline was used, and what that implies for running this unattended at a customer.
4. Run through the [factory-kit checklist](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/factory-kit-checklist.md) as a final sanity pass across the team's deliverables.
5. Prepare a short showcase: what was modernized, what's deferred, and the single most useful thing Copilot did for the team. Write the outline in `evidence/c10/showcase.md`, then deliver it to your coach.

## Evidence

- The packaged reusable asset, committed in `evidence/c10/reusable-asset/` and referenced from the handover document.
- The completed acceptance and handover document, covering every team member.
- The AI-readiness gap register, with at least one entry per lifeline used across the team (if any), and a credible one if none were used.
- The factory-kit checklist, all items addressed.
- The showcase outline (`evidence/c10/showcase.md`), delivered to your coach.

## Hints

<details>
<summary>What makes an asset "reusable"?</summary>

Someone outside the team should be able to run it without first asking you a question. If your packaging still assumes tribal knowledge from the two days, it isn't done yet.
</details>

<details>
<summary>We didn't use any lifelines — is the gap register empty then?</summary>

No — the register should also note where a human review step (not a lifeline) was still essential, even though nothing broke. Look back over the challenges for the points where the kit deliberately keeps a person in charge, and record them as the current state of AI readiness, not as gaps to close. Ask your coach if you want a nudge.
</details>

## Bonus

Up to 10 pts for a showcase that includes a live demo of the modernized app against SQL Managed Instance, not just slides.

## Learn more

- [Cloud Adoption Framework: govern and manage](https://learn.microsoft.com/azure/cloud-adoption-framework/govern/)
