---
title: "C1: Define the opportunity"
description: The team scopes the modernization opportunity and a six-dimension plan.
---

## Goal

Agree, as a team, what "modernized" means for Contoso University and write it down before any infrastructure exists.

## Scope and time box

Team. **45 min** (runs in parallel with ALZ-lite deploying in C2 — don't wait for it).

## Points

**10 pts** (team).

## Inputs

None beyond the kit brief: Contoso University, an ASP.NET MVC 5 app on .NET Framework 4.8, moving to .NET 10 and Azure.

## The team repo: what it is and how to set it up

Your **own repo** (from Prerequisites) holds your dev container, your copy of the kit and your personal settings. The **team repo** is different: one private repo that the whole team shares, holding only the team's written evidence (canvases, ADRs, runbooks, acceptance documents, screenshots). Nothing is deployed from it and it has no dev container. The assessors read it to score the team.

It isn't a GitHub template repo: the starting content is the kit's `templates/team/` folder, which you copy into a new empty repo. One teammate (ask your coach who) does this once; everyone else only accepts the invitation and clones.

**Setup, by one teammate (about 10 minutes):**

1. **Create an empty private repo** in the partner's GitHub org, for example `team-<team-name>-evidence`. On github.com choose **New repository**, set the owner to the partner org, **Private**, no README, no `.gitignore`.
2. **Clone it next to your own repo**, in the same folder (not inside your own repo), in a terminal on your computer (WSL on Windows 11):

   ```bash
   cd ~/repos
   git clone https://github.com/<your-org>/<team-repo>.git
   ```

3. **Copy the template in** from the kit in your own repo, then commit and push:

   ```bash
   cp -r ~/repos/<your-repo>/factory/templates/team/. ~/repos/<team-repo>/
   cd ~/repos/<team-repo>
   git add -A && git commit -m "Add team evidence template" && git push
   ```

4. **Give every teammate write access.** On github.com open the repo's **Settings** > **Collaborators and teams** > **Add people**, add each teammate by GitHub user name, and choose the **Write** role. If your org uses a GitHub team for your team, add the team instead.

**Every other teammate:**

1. Accept the invitation (an email, or `https://github.com/<your-org>/<team-repo>/invitations`).
2. Clone the repo into `~/repos`, next to your own repo: `git clone https://github.com/<your-org>/<team-repo>.git`.
3. Before every edit, run `git pull`. Commit and push after every challenge.

The repo has an `evidence/` folder with one subfolder per challenge (`evidence/c01/`, `evidence/c02/`, and so on), where member-scoped evidence goes in `member-<n>/` subfolders, and a `templates/` folder with copies of the attendee templates. Its README explains the layout. Never commit secrets, tenant IDs or subscription IDs.

If you can't create repos in the partner org, or a teammate can't be added, tell your coach before the event: it's a blocker like any other prerequisite.

## Your tasks

Work on one shared screen (one person types, everyone contributes), in the team repo's folder on that person's computer. No dev container or Azure access is needed for C1.

1. **Copy the template.** In the team repo, copy `templates/opportunity-canvas.md` to `evidence/c01/opportunity-canvas.md`:

   ```bash
   cd ~/repos/<team-repo>
   git pull
   cp templates/opportunity-canvas.md evidence/c01/opportunity-canvas.md
   ```

2. **Business case (5 min).** Name the sponsor (a role, for example "the university's CIO") and write one or two sentences on the problem modernizing Contoso University solves for them.
3. **Current pain (5 min).** List at least three concrete problems with today's app: for example .NET Framework 4.8 end of mainstream support, SQL Server 2022 on a VM, MSMQ, manual deployment. Say whether each is cost, risk, agility or support burden.
4. **Six dimensions (20 min).** For each of application, data, platform, security, operations and cost, write two lines: `Today:` and `Target:`. Use the kit's fixed shape as the target where it applies: .NET 10 on Azure App Service, SQL Managed Instance, private-by-default networking, central logging, and cost tracked against the vending budget.
5. **Target outcome (5 min).** Write one sentence a sponsor would accept as "done" at the end of day two, and make sure every teammate can say it from memory.
6. **Open questions.** Record any disagreement under "Open questions" with the people holding each view, then move on. C4 decides.
7. **Commit.**

   ```bash
   git add evidence/c01/opportunity-canvas.md
   git commit -m "C1: opportunity canvas"
   git pull --rebase
   git push
   ```

   Don't commit tenant IDs, subscription IDs or secrets.

Done when no HTML comment prompt text remains in the file, all six dimensions have both a `Today:` and a `Target:` line, and the commit is on the team repo's main branch.

## Evidence

- `evidence/c01/opportunity-canvas.md`, committed, with all six dimensions filled in (not left as the template's placeholder text).
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

## Lifeline

A content lifeline is available if your team is stuck on the canvas format itself (not on the business decision) — ask your coach. Point cap: using it caps C1 at partial credit.

## Bonus

None for C1.

## Learn more

- [Cloud Adoption Framework: strategy and plan](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/)
- [App Service migration planning guidance](https://learn.microsoft.com/azure/app-service/migrate-overview)
