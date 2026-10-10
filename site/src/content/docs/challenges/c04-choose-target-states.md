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

C3's triaged findings (everyone's `evidence/c03/member-<n>/triage.md`), including the trace-flag decision, and C2's exemptions tables.

## Where to run

In the team repo, in the folder on your computer (the same terminal as C1: `cd ~/repos/<team-repo>`, then `git pull`). Copy the templates you need from the repo's `templates/` folder ([ADR](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/adr.md), [deferred-work register](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/deferred-work-register.md)). No Azure access is needed. Commit only your own files, then `git pull --rebase` and `git push`.

## Your tasks

1. As a team, write the platform ADR in `evidence/c04/adr-platform.md`: the CoE archetype's shape (App Service, SQL MI, Blob, Service Bus, Key Vault, Application Insights) and why it fits C1's opportunity. One teammate commits it.
2. As a team, write the migration-method ADR in `evidence/c04/adr-migration.md`: Arc SQL migration assessment plus MI link, online, with a planned cutover — and why not an offline backup/restore. One teammate commits it.
3. As a member, write two ADRs in your own folder: `evidence/c04/member-<n>/adr-app.md` for the app target state (.NET 10, ASP.NET Core MVC, GitHub Copilot's Upgrade agent) and `evidence/c04/member-<n>/adr-data.md` for the data target state (SQL Managed Instance, Microsoft Entra authentication only).
4. As a team, assemble `evidence/c04/deferred-work-register.md`. One teammate writes it from everyone's `triage.md`: every C3 finding you're deferring, including the trace-flag removal after cutover (one row per member, because each member has their own `vm-app01`), each with an owner, a target and a timeline. Add the exemptions from C2 as rows too: each member sends their exemptions table, and you map its columns to the register's (policy assignment to finding, owner to owner, target date to timeline).
5. Commit and push everything, and check `git log` shows each teammate's files.

Done when `evidence/c04/` holds both team ADRs and the register, and each member's folder holds their two ADRs.

## Evidence

- The ADRs: platform and migration method (team), app and data (each member). Each has a decision, an alternative considered, and a consequence.
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
