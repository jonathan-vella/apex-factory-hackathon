---
title: "C4: Choose target states"
description: Commit to app, data, platform and migration-method decisions as ADRs.
---

## Goal

Record the target states the kit has fixed as committed decisions, one ADR per decision, each with the alternative you considered and the consequence. Turn C3's triaged findings into a deferred-work register for everything you're consciously not doing yet.

## Scope and time box

Team and member. **45 min**: about 10 for each team ADR (tasks 1 and 2), 5 for each of your own two (task 3), 10 for the register (task 4) and 5 to copy and push (task 5).

## Points

**25 pts** (15 team + 10 member).

## Inputs

C3's triaged findings (everyone's `factory/evidence/c03/triage.md`, each teammate shares theirs on the shared screen), including the trace-flag decision, and C2's exemptions tables.

## Where to run

In your own repo's dev container (VS Code, **Reopen in Container**, as in C5), in a terminal at the repo root. No Azure access is needed. Run `git pull`, then copy the templates ([ADR](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/adr.md), [deferred-work register](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/deferred-work-register.md)) from `factory/templates/attendee/` into `factory/evidence/c04/`. This gives you the four ADR files and the register, each with its prompts to fill in:

```bash
git pull
mkdir -p factory/evidence/c04
for name in adr-platform adr-migration adr-app adr-data; do cp factory/templates/attendee/adr.md "factory/evidence/c04/$name.md"; done
cp factory/templates/attendee/deferred-work-register.md factory/evidence/c04/
```

The team writes the team documents (tasks 1, 2 and 4) together: one person types on a shared screen, then every teammate saves the final file under the same name in their own `factory/evidence/c04/`.

## Your tasks

1. As a team, write the platform ADR in `factory/evidence/c04/adr-platform.md`: the CoE archetype's shape (App Service, container registry, SQL MI, Blob, Service Bus, Key Vault, Application Insights) and why it fits C1's opportunity. Every teammate saves the final file in their own `factory/evidence/c04/`.
2. As a team, write the migration-method ADR in `factory/evidence/c04/adr-migration.md`. The decision is the one the kit fixes: the Arc SQL migration assessment plus the MI link, online, with a planned cutover. The alternative to record is an offline backup and restore, and its consequence is a long outage while the backup restores (the link needs only a short stop at cutover). Every teammate saves the final file too.
3. As a member, write two ADRs in your own repo:
   - `factory/evidence/c04/adr-app.md` for the app target state (.NET 10, ASP.NET Core MVC, GitHub Copilot's Upgrade agent). The alternative can be keeping .NET Framework 4.8 on a VM, or a manual rewrite.
   - `factory/evidence/c04/adr-data.md` for the data target state (SQL Managed Instance, Microsoft Entra authentication only). The alternative is SQL Server on an Azure VM. The rule: choose SQL MI unless C3's triage found a real blocker, a feature SQL MI doesn't support at all that the app uses. If you found none, the decision is SQL MI and the VM is the alternative you rejected; if you found one, name it in the ADR and decide for the VM.
4. As a team, assemble `factory/evidence/c04/deferred-work-register.md`. One teammate types it from everyone's `triage.md`: every C3 finding you're deferring, including the trace-flag removal after cutover (one row per member, because each member has their own `vm-app01`), each with an owner, a target and a timeline. Add the exemptions from C2 as rows too: each member reads out their exemptions table, and you map its columns to the register's (policy assignment to finding, owner to owner, target date to timeline; source is C2, and target is "retire the exemption once the resource meets the policy"). Every teammate saves the final register too.
5. Commit and push everything to `main` of your own repo (see the evidence rule below).

Done when `factory/evidence/c04/` in your repo holds four ADR files (two team ADRs, plus your own `adr-app.md` and `adr-data.md`, each with a decision, an alternative and a consequence) and the register, and the team files match your teammates' copies.

## Evidence

Save the files in `factory/evidence/c04/` of your own repo, on `main`. In the dev container, run `git pull` first. On `vm-dev01`, use `C:\src\<your-repo>\factory\evidence\c04\` (the plain clone of your own repo) and run `git pull --rebase` first. Commit with a conventional message (for example `docs: C4 target-state decisions`) and run `git push`.

- The ADRs: platform and migration method (team, scored from the platform lead's copy), app and data (each member). Each has a decision, an alternative considered, and a consequence.
- The deferred-work register, with every deferred C3 finding present and the trace-flag removal step explicitly listed for each member.

## Hints

<details>
<summary>How detailed does an ADR need to be?</summary>

One page: context, decision, alternatives considered, consequences. The template has headings for each — fill them in, don't pad them.
</details>

<details>
<summary>What goes in the register versus an ADR?</summary>

An ADR commits to a choice. The register tracks something you're explicitly not doing now — like removing the trace flags only after the link is gone. If it has an owner and a date, it's a register entry, not a decision.
</details>

## If you need to start over

ADRs and the register are append-only documents, and there's nothing in Azure to reset. Correct a file in place and commit the change (for example `docs: correct C4 ADR`). To change a decision you already committed, set its Status to Superseded and write a new ADR instead of deleting the old one.

## Bonus

None for C4.

## Learn more

- [Architecture decision records overview](https://learn.microsoft.com/azure/well-architected/architect-role/architecture-decision-record)
- [Choose the right migration tool for Azure SQL Managed Instance](https://learn.microsoft.com/azure/azure-sql/migration-guides/managed-instance/sql-server-to-managed-instance-overview)
