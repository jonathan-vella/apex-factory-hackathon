---
title: "C1: Define the opportunity"
description: The team scopes the modernization opportunity and a six-dimension plan.
---

## Background

Before any app or data work starts, the team needs one shared answer to "what does modernized mean for Contoso University?" C1 is where you write it down, so every later decision has something to point back to.

**Objective.** Be able to scope a modernization opportunity across six dimensions and agree a target outcome the whole team can repeat.

**Time and points.** Team, **45 min**, **10 pts** (team). Everyone starts here at 09:00, the team lead included: the team lead deployed the foundation before the event, so there's nothing to deploy and C1 needs no Azure access. Members start [C3](../c03-assess-the-source/) later, at 10:15.

The one-time evidence set-up takes about 5 minutes and requirements 2 to 5 add up to 35, so the 45 minutes leave little slack. Do the set-up while teammates read the canvas template, and keep to the times given.

## Challenge

**Starting point.** Nothing beyond the kit brief: Contoso University, an ASP.NET MVC 5 app on .NET Framework 4.8, moving to .NET 10 and Azure.

**Fixed by the kit.** The target shape: .NET 10 on Azure App Service, SQL Managed Instance, private-by-default networking, central logging, and cost tracked against the vending budget (the budget alert that vending created for each member before the event).

**You decide.** The sponsor, the problem you solve for them, the pains that matter most, and the one-sentence outcome that counts as done.

**Where to work.** The dev container of your own repo, and only there: it has the tools and the GitHub sign-in you set up in [Set up your repo](../../deploy/set-up-your-repo/). Don't use a terminal outside the container. On event day, open VS Code on your repo and choose **Reopen in Container** if it isn't already open in it. The terminal opens at the repo root, so you don't need to `cd`. Work on one shared screen: one person types, everyone contributes. To save a screenshot or a chat file from your laptop into `factory/evidence/c01/`, drag it into that folder in VS Code's Explorer.

### Where your evidence goes

The team doesn't collect evidence in a common repository. You work in one private repo of your own (the one from [Set up your repo](../../deploy/set-up-your-repo/), with the kit in `factory/` and the import merged into `main`). Your evidence lives in it, on `main`, under `factory/evidence/cNN/` (`c01` to `c10`), next to `factory/evidence/readiness/` from the readiness check. Your coach reads each member's repo to score it. One rule says where to commit:

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

The `-n` keeps anything you already created in the readiness check (such as `factory/evidence/readiness/`), and the command works whether or not `factory/evidence/` exists yet.

</details>

## Requirements

1. **Copy the template.** In your own repo, copy `factory/templates/attendee/opportunity-canvas.md` to `factory/evidence/c01/opportunity-canvas.md`:

   ```bash
   cp factory/templates/attendee/opportunity-canvas.md factory/evidence/c01/opportunity-canvas.md
   ```

2. **Business case (5 min).** Name the sponsor (a role, for example "the university's CIO") and write one or two sentences on the problem modernizing Contoso University solves for them.

3. **Current pain (5 min).** List at least three concrete problems with today's app: for example a framework that's no longer evolving, IIS and Windows patching on a VM, MSMQ with no managed equivalent, manual deployment. Say whether each is cost, risk, agility or support burden.

4. **Six dimensions (20 min).** For each of application, data, platform, security, operations and cost, write two lines: `Today:` and `Target:`. Use the kit's fixed shape as the target where it applies.

5. **Target outcome (5 min).** Fill in the **Target outcome** section, which is third in the canvas but easiest to write last. Write one sentence a sponsor would accept as "done" at the end of day two, and make sure every teammate can say it from memory.

6. **Open questions.** Record any disagreement under "Open questions" with the people holding each view, then move on. C4 decides.

7. **Commit.** The person who typed runs `git pull`, then commits. The typist posts the final file in the team channel. Then every teammate runs `git pull`, saves the file unchanged as `factory/evidence/c01/opportunity-canvas.md` in their own repo and commits it.

   ```bash
   git add factory/evidence/c01/opportunity-canvas.md
   git commit -m "docs: C1 opportunity canvas"
   git push
   ```

   Don't commit tenant IDs, subscription IDs or secrets.

## Success criteria

To complete this challenge, show your coach in your own repo:

- [ ] `factory/evidence/c01/opportunity-canvas.md`, committed on `main`, with all six dimensions filled in (not left as the template's placeholder text). It's scored once per team, from the team lead's copy.
- [ ] Each of the six dimensions has both a `Today:` and a `Target:` line, and no `<!-- ... -->` comment lines remain in the file.
- [ ] A one-sentence target outcome the whole team can repeat.
- [ ] Every teammate's copy is committed on `main` of their own repo and matches the team lead's.

Next, continue with [C2: Secure, AI-ready foundation](../c02-secure-ai-ready-foundation/): the coach's live portal demo, then the team lead walks the team through the foundation they deployed before the event. Members start [C3: Assess the source](../c03-assess-the-source/) at 10:15.

<details>
<summary>We don't agree on scope</summary>

Time-box the disagreement: write both views in the canvas's "open questions" area and move on. C4's ADRs are where you commit to specific choices; C1 is directional.

</details>

<details>
<summary>We're not sure what counts as a "dimension"</summary>

Application: code and framework. Data: storage and schema. Platform: compute and networking. Security: identity and secrets. Operations: telemetry and support. Cost: what you'll spend and how you'll justify it. One line each is enough for C1.

</details>

<details>
<summary>If you need to start over</summary>

- **Redo the canvas:** copy the template over your file again with `cp factory/templates/attendee/opportunity-canvas.md factory/evidence/c01/opportunity-canvas.md`. This replaces everything you wrote, so copy your text somewhere first if you want to keep any of it. If your team already agreed on a version, the typist posts the file in the team channel again and every teammate saves it unchanged.
- **The evidence folder has the wrong layout** (you see `factory/evidence/evidence/`): move the folders up a level with `cp -rn factory/evidence/evidence/. factory/evidence/`, then remove `factory/evidence/evidence` with `rm -r`, and commit.

</details>

**Bonus.** None for C1.

## References

- [Cloud Adoption Framework: strategy and plan](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/)
- [Assess .NET apps for migration to Azure App Service](https://learn.microsoft.com/azure/app-service/app-service-migration-assess-net)
