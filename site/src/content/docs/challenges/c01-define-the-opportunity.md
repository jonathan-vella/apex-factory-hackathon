---
title: "C1: Define the opportunity"
description: The team scopes the modernization opportunity and a six-dimension plan.
---

## Goal

Agree, as a team, what "modernized" means for Contoso University and write it down before any infrastructure exists.

## Scope and time box

Team. **45 min**. The platform lead starts ALZ-lite at 09:00, so it deploys during C1 (see [C2](../c02-secure-ai-ready-foundation/), task 3); C1 needs no Azure access, so don't wait for it. Members start C3 later, at 10:15 (see [C3](../c03-assess-the-source/)).

The one-time evidence set-up below takes about 5 minutes and tasks 2 to 5 add up to 35, so the 45 minutes leave little slack. Do the set-up while teammates read the canvas template, and keep to the times given.

## Points

**10 pts** (team).

## Inputs

None beyond the kit brief: Contoso University, an ASP.NET MVC 5 app on .NET Framework 4.8, moving to .NET 10 and Azure.

## Where your evidence goes

The team doesn't collect evidence in a common repository. You work in one private repo of your own (the one from Prerequisites, with the kit in `factory/`). Your evidence lives in it, on `main`, under `factory/evidence/cNN/` (`c00` to `c10`). Your coach reads each member's repo to score it.

Why `factory/`: the repo's lint and format ignores cover it, so evidence files don't trip the pre-commit hooks, and the weekly upstream sync leaves it alone.

**Set it up once (about 5 minutes).** In your own repo's folder on your computer (WSL on Windows 11) or in its dev container:

```bash
cd ~/repos/<your-repo>
cp -r factory/templates/team/evidence factory/evidence
cp factory/templates/team/README.md factory/evidence/README.md
git add factory/evidence
git commit -m "docs: add evidence folders"
git push
```

If you already created `factory/evidence/c00/` in C0, use `cp -rn` for the first copy: it adds the missing folders and keeps yours.

**Commit messages** in your own repo must be conventional commits (`type: Subject`), or the commit hook rejects them. For example `docs: C1 opportunity canvas`. Commit evidence with plain `git` and push to `main`; no pull request is needed. Don't use `/apex-git-commit` for this: it skips some paths and refuses `main`. Never commit secrets, tenant IDs or subscription IDs.

**Team deliverables** (the C1 canvas, C4's team ADRs, the C10 package): the team writes one document together on one person's screen. Afterwards every teammate copies the final file into their own `factory/evidence/cNN/` and commits it. A team item is scored once per team, from the platform lead's copy, so the other copies must match it.

## Where to run

Work on one shared screen (one person types, everyone contributes). Use your own repo's folder on that person's computer (`cd ~/repos/<your-repo>` in a terminal on your computer, WSL on Windows 11) or its dev container. No Azure access is needed for C1.

## Your tasks

1. **Copy the template.** In your own repo, copy `factory/templates/attendee/opportunity-canvas.md` to `factory/evidence/c01/opportunity-canvas.md`:

   ```bash
   cd ~/repos/<your-repo>
   cp factory/templates/attendee/opportunity-canvas.md factory/evidence/c01/opportunity-canvas.md
   ```

2. **Business case (5 min).** Name the sponsor (a role, for example "the university's CIO") and write one or two sentences on the problem modernizing Contoso University solves for them.
3. **Current pain (5 min).** List at least three concrete problems with today's app: for example a framework that's no longer evolving, IIS and Windows patching on a VM, MSMQ with no managed equivalent, manual deployment. Say whether each is cost, risk, agility or support burden.
4. **Six dimensions (20 min).** For each of application, data, platform, security, operations and cost, write two lines: `Today:` and `Target:`. Use the kit's fixed shape as the target where it applies: .NET 10 on Azure App Service, SQL Managed Instance, private-by-default networking, central logging, and cost tracked against the vending budget.
5. **Target outcome (5 min).** Write one sentence a sponsor would accept as "done" at the end of day two, and make sure every teammate can say it from memory.
6. **Open questions.** Record any disagreement under "Open questions" with the people holding each view, then move on. C4 decides.
7. **Commit.** The person who typed commits first. Then every teammate copies the final file into their own `factory/evidence/c01/` and commits it.

   ```bash
   git add factory/evidence/c01/opportunity-canvas.md
   git commit -m "docs: C1 opportunity canvas"
   git push
   ```

   Don't commit tenant IDs, subscription IDs or secrets.

Done when no HTML comment prompt text remains in the file, all six dimensions have both a `Today:` and a `Target:` line, and every teammate's copy is committed on `main` of their own repo and matches the platform lead's.

## Evidence

- `factory/evidence/c01/opportunity-canvas.md`, committed, with all six dimensions filled in (not left as the template's placeholder text). It's scored once per team, from the platform lead's copy.
- A one-sentence target outcome the whole team can repeat.

## Hints

<details>
<summary>We don't agree on scope</summary>

Time-box the disagreement: write both views in the canvas's "open questions" area and move on. C4's ADRs are where you commit to specific choices; C1 is directional.
</details>

<details>
<summary>We're not sure what counts as a "dimension"</summary>

Application: code and framework. Data: storage and schema. Platform: compute and networking. Security: identity and secrets. Operations: telemetry and support. Cost: what you'll spend and how you'll justify it. One line each is enough for C1.
</details>

## Bonus

None for C1.

## Learn more

- [Cloud Adoption Framework: strategy and plan](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/)
- [Assess .NET apps for migration to Azure App Service](https://learn.microsoft.com/azure/app-service/app-service-migration-assess-net)
