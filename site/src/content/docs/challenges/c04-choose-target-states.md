---
title: "C4: Choose target states"
description: Commit to app, data, platform and migration-method decisions as ADRs.
---

## Goal

Record the target states the kit has fixed as committed decisions, one ADR per decision, each with the alternative you considered and the consequence. Turn C3's triaged findings into a deferred-work register for everything you're consciously not doing yet.

## Scope and time box

Team and member. **45 min**.

## Points

**25 pts** (15 team + 10 member).

## Inputs

C3's triaged findings (everyone's `factory/evidence/c03/triage.md`, each teammate shares theirs on the shared screen), including the trace-flag decision, and C2's exemptions tables.

## Where to run

In your own repo, in the folder on your computer (the same terminal as C1: `cd ~/repos/<your-repo>`). Copy the templates you need from `factory/templates/attendee/` ([ADR](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/adr.md), [deferred-work register](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/deferred-work-register.md)). No Azure access is needed. The team writes the team documents together on one person's screen; then every teammate copies the final files into their own repo, commits with a conventional message (for example `docs: C4 target-state decisions`) and runs `git push` to `main`.

## Your tasks

1. As a team, write the platform ADR in `factory/evidence/c04/adr-platform.md`: the CoE archetype's shape (App Service, SQL MI, Blob, Service Bus, Key Vault, Application Insights) and why it fits C1's opportunity. Every teammate copies it into their own `factory/evidence/c04/`.
2. As a team, write the migration-method ADR in `factory/evidence/c04/adr-migration.md`: Arc SQL migration assessment plus MI link, online, with a planned cutover — and why not an offline backup/restore. Every teammate copies it too.
3. As a member, write two ADRs in your own repo: `factory/evidence/c04/adr-app.md` for the app target state (.NET 10, ASP.NET Core MVC, GitHub Copilot's Upgrade agent) and `factory/evidence/c04/adr-data.md` for the data target state (SQL Managed Instance, Microsoft Entra authentication only).
4. As a team, assemble `factory/evidence/c04/deferred-work-register.md`. One teammate types it from everyone's `triage.md`: every C3 finding you're deferring, including the trace-flag removal after cutover (one row per member, because each member has their own `vm-app01`), each with an owner, a target and a timeline. Add the exemptions from C2 as rows too: each member reads out their exemptions table, and you map its columns to the register's (policy assignment to finding, owner to owner, target date to timeline). Every teammate copies the final register too.
5. Commit and push everything to `main` of your own repo.

Done when `factory/evidence/c04/` in your repo holds both team ADRs and the register (matching the platform lead's copies) and your two ADRs.

## Evidence

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

## Bonus

None for C4.

## Learn more

- [Architecture decision records overview](https://learn.microsoft.com/azure/well-architected/architect-role/architecture-decision-record)
- [Choose the right migration tool for Azure SQL Managed Instance](https://learn.microsoft.com/azure/azure-sql/migration-guides/managed-instance/sql-server-to-managed-instance-overview)
