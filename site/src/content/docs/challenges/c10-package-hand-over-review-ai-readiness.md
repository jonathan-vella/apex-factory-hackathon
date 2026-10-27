---
title: "C10: Package, hand over, review AI readiness"
description: Close out the engagement as a team with a reusable asset, a handover and an honest AI-readiness review.
---

## Background

Modernizing one app is only worth it if the next team can repeat it and the customer can run what you built. C10 closes the engagement: you package something reusable, hand over, and record honestly how much of the work needed a human.

**Objective.** Be able to package a reusable asset, complete a handover, and assess how ready a customer is to run GitHub Copilot's agents unattended.

**Time and points.** Team, **60 min**, **20 pts** (team).

## Challenge

**Starting point.** Every prior challenge's evidence, in each member's own repo: the `factory/evidence/cNN/` folders for C1 to C9, including every member's C8 acceptance pack. Each member packages in their own repo, which may be private, so share files instead of opening each other's repos. Ask every teammate to share their C8 pack (`factory/evidence/c08/acceptance-handover.md` and its `acceptance.json`) on one screen or in your team chat. Save each as `factory/evidence/c10/member-packs/member-<n>.md` and `member-<n>-acceptance.json`, where `<n>` is that member's index.

**You decide.** Which asset to package, who the engagement is handed to and how they operate it, and where Copilot's agents needed a human.

**Where to work.** The dev container of your own repo, with VS Code open on it (the repo you created in [Set up your repo](../../deploy/set-up-your-repo/)). No `vm-dev01` or Azure access is needed. Run `git pull` first, so you start from the latest `main`.

Write the package together on one person's screen, in `factory/evidence/c10/`. Split the work so nobody waits: one person on the handover (requirement 2), one on the gap register and checklist (requirements 3 and 4), and the others on the asset (requirement 1) and the showcase (requirement 5). Then swap to review each other's parts. One person types each document.

The package is scored once for the team, from the team lead's copy, so the other copies must match it. When the files are final, every teammate saves them under the same names in their own `factory/evidence/c10/`, commits with a conventional message (for example `docs: C10 package`) and pushes `main`.

## Requirements

1. **Reusable asset (about 15 min).** Package one reusable asset from the engagement: the archetype adaptation, the modernization playbook run, or the perf kit fixes. Another team must be able to pick it up without you in the room. Copy the files into `factory/evidence/c10/reusable-asset/`, for example the adapted archetype folder from a member's own repo, or the five fix scripts from `factory/evidence/c09/`. Add a short README that says what a new team must supply and how to run it.

2. **Acceptance and handover (about 15 min).** Copy `factory/templates/attendee/acceptance-handover.md` ([template on GitHub](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/acceptance-handover.md)) to `factory/evidence/c10/acceptance-handover.md` and complete it for the whole engagement. In its handover summary, name every member and link their pack in `factory/evidence/c10/member-packs/`. Say who the engagement is handed to and how they operate it.

3. **AI-readiness gap register (about 10 min).** Copy `factory/templates/attendee/ai-readiness-gap-register.md` to `factory/evidence/c10/` and fill it in honestly: where GitHub Copilot's agents needed a human to unblock them, where coach support was used, and what that implies for running this unattended at a customer. Delete the template's example rows.

4. **Factory-kit checklist (about 5 min).** Copy `factory/templates/attendee/factory-kit-checklist.md` to `factory/evidence/c10/` and run through it as a final sanity pass across the team's deliverables.

5. **Showcase (about 15 min).** Prepare a short showcase: what was modernized, what's deferred, and the single most useful thing Copilot did for the team. Write the outline in `factory/evidence/c10/showcase.md`, then deliver it to your coach. If you're short of time, a two-minute verbal showcase with one screen shown still counts.

## Success criteria

To complete this challenge, show your coach in `factory/evidence/c10/` on `main`:

- [ ] The packaged reusable asset in `reusable-asset/`, referenced from the handover document.
- [ ] The completed `acceptance-handover.md`, covering every team member.
- [ ] The AI-readiness gap register, with at least one entry for each time the team used coach support, or a credible one if none was used.
- [ ] The factory-kit checklist, with all items addressed.
- [ ] The showcase outline (`showcase.md`), delivered to your coach.
- [ ] Every teammate's copies match the team lead's.

<details>
<summary>What makes an asset "reusable"?</summary>

Someone outside the team should be able to run it without first asking you a question. If your packaging still assumes tribal knowledge from the two days, it isn't done yet.

</details>

<details>
<summary>We didn't use any coach support. Is the gap register empty then?</summary>

No. The register should also note where a human review step (not coach support) was still essential, even though nothing broke. Look back over the challenges for the points where the kit deliberately keeps a person in charge, and record them as the current state of AI readiness, not as gaps to close. Ask your coach if you want a nudge.

</details>

<details>
<summary>If you need to start over</summary>

C10 produces documents only, so there is no deployed state to reset. To redo a document, delete it from `factory/evidence/c10/` and copy its template again from `factory/templates/attendee/`. If teammates' copies drift apart, one person's final files win: everyone saves those over their own.

</details>

**Bonus.** Up to 10 pts for a showcase that includes a live demo of the modernized app against SQL Managed Instance, not just slides. Bonus points from all challenges share one cap of 30 points per team.

## References

- [Cloud Adoption Framework: govern and manage](https://learn.microsoft.com/azure/cloud-adoption-framework/govern/)
