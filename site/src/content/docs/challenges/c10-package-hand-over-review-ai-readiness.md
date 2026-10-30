---
title: "C10: Package, hand over, review AI readiness"
description: Close out the engagement as a team with a reusable asset, a handover and an honest AI-readiness review.
next:
  link: /deploy/tear-down/
  label: Tear down (T+2)
---

## Background

Modernizing one app is only worth it if the next team can repeat it and the customer can run what you built. C10 closes the engagement: you package something reusable, hand over, and record honestly how much of the work needed a human.

**Business context.** Dana, the CIO, has to tell the board what the university can do next and what it can't yet. C10 hands over what the team built and says how ready the university is to run AI on it.

**Business outcome.** Documented path to AI. The handover says what is ready for AI use and what is not, with an owner and a next step for each gap, and another team can repeat the work from the package.

**Objective.** Be able to package a reusable asset, complete a handover, and assess how ready a customer is to run GitHub Copilot's agents unattended.

**Time and points.** Team, **60 min**, **20 pts** (team).

## Challenge

**Starting point.** The source material lives in each member's own repo: the `factory/evidence/cNN/` folders for C1 to C9, including every member's [C8 acceptance pack](../c08-validate-the-pattern/). Use [C1's outcomes](../c01-define-the-opportunity/) and [C9's fix scripts](../c09-optimize-the-db-with-ghcp/) in the final package. Ask every teammate to share their C8 pack (`factory/evidence/c08/acceptance-handover.md` and its `acceptance.json`) on one screen or in your team chat. Save each as `factory/evidence/c10/member-packs/member-<n>.md` and `member-<n>-acceptance.json`, where `<n>` is that member's index.

**Fixed by the kit.** The three attendee templates and the scoring rule: the team lead's copy is the one coaches score.

**You decide.** Which asset to package, who the engagement is handed to and how they operate it, and where Copilot's agents needed a human.

**Where to work.** The dev container of your own repo, with VS Code open on it (the repo you created in [Set up your repo](../../deploy/set-up-your-repo/)). No `vm-dev01` or Azure access is needed. Run `git pull` first, so you start from the latest `main`.

One person, ideally the team lead, owns the package in their repo at `factory/evidence/c10/` and types the final files on one screen; don't open each other's repos. The other members draft their assigned parts and send them to that person. Split the work so nobody waits: one person on the handover (requirement 2), one on the gap register and checklist (requirements 3 and 4), and the others on the asset (requirement 1) and the showcase (requirement 5). Then swap to review each other's parts. When the package is final, everyone copies the files unchanged to their own repo.

When the files are final, every teammate saves the same files under the same names in their own `factory/evidence/c10/`, commits with a conventional message (for example `docs: C10 package`) and pushes `main`.

## Requirements

Copy the imported templates in your own repo's dev container:

```bash
mkdir -p factory/evidence/c10
cp factory/templates/attendee/acceptance-handover.md factory/evidence/c10/
cp factory/templates/attendee/ai-readiness-gap-register.md factory/evidence/c10/
cp factory/templates/attendee/factory-kit-checklist.md factory/evidence/c10/
```

The [gap register](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/ai-readiness-gap-register.md) and [factory-kit checklist](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/factory-kit-checklist.md) are also readable on GitHub.

1. **Reusable asset (about 15 min).** Package one reusable asset from the engagement: the archetype adaptation, the modernization playbook run, or the perf kit fixes. Another team must be able to pick it up without you in the room. Copy the files into `factory/evidence/c10/reusable-asset/`, for example the adapted archetype folder from a member's own repo, or the five fix scripts from `factory/evidence/c09/`. Add a short README that says what a new team must supply and how to run it.

2. **Acceptance and handover (about 15 min).** Copy `factory/templates/attendee/acceptance-handover.md` ([template on GitHub](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/acceptance-handover.md)) to `factory/evidence/c10/acceptance-handover.md` and complete it for the whole engagement. In its handover summary, name every member and link their pack in `factory/evidence/c10/member-packs/`. Say who the engagement is handed to and how they operate it.

3. **AI-readiness gap register (about 10 min).** Copy `factory/templates/attendee/ai-readiness-gap-register.md` to `factory/evidence/c10/` and fill it in honestly: where GitHub Copilot's agents needed a human, each time a coach unblocked you (including any checkpoint a coach gave you), and what that implies for running this unattended at a customer. Ordinary hints and discussion need no separate entry. Delete the template's example rows.

4. **Factory-kit checklist (about 5 min).** Copy `factory/templates/attendee/factory-kit-checklist.md` to `factory/evidence/c10/` and run through it as a final sanity pass across the team's deliverables.

5. **Showcase (about 15 min).** Prepare a short showcase: what was modernized, what's deferred, how the work serves your top-ranked outcome from C1, and the single most useful thing Copilot did for the team. Write the outline in `factory/evidence/c10/showcase.md`, then deliver it to your coach. If you're short of time, a two-minute verbal showcase with one screen shown still counts.

## Success criteria

To complete this challenge, show your coach in `factory/evidence/c10/` on `main`:

- [ ] The packaged reusable asset in `reusable-asset/`, referenced from the handover document.
- [ ] The completed `acceptance-handover.md`, covering every team member.
- [ ] The AI-readiness gap register, with an entry each time a coach unblocked the team (including a supplied checkpoint), or a credible non-use entry explaining the human reviews that were still needed.
- [ ] The factory-kit checklist, with all items addressed.
- [ ] The showcase outline (`showcase.md`), delivered to your coach.
- [ ] Every teammate's copies match the team lead's.
- [ ] Outcome check (unscored guidance): every gap in your register has an owner and a next step, so Dana can say what comes after the handover.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

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

- [Cloud Adoption Framework: AI adoption](https://learn.microsoft.com/azure/cloud-adoption-framework/ai/strategy)
- [Cloud Adoption Framework: Manage](https://learn.microsoft.com/azure/cloud-adoption-framework/manage/ready-cloud-operations)

After the showcase, save your work and follow [Tear down (T+2)](../../deploy/tear-down/).
