---
title: "C4: Choose target states"
description: Commit to app, data, platform and migration-method decisions as ADRs.
---

## Goal

Turn C3's triaged findings into committed decisions — one ADR per dimension that matters — plus a deferred-work register for everything you're consciously not doing yet.

## Scope and time box

Team and member. **45 min**.

## Points

**25 pts** (15 team + 10 member).

## Inputs

C3's triaged findings, including the trace-flag decision.

## Your tasks

1. As a team, write an [ADR](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/adr.md) for the platform target state: the CoE archetype's shape (App Service, SQL MI, Blob, Service Bus, Key Vault, Application Insights) and why it fits C1's opportunity.
2. As a team, write an ADR for the migration method: Arc SQL migration assessment plus MI link, online, with a planned cutover — and why not an offline backup/restore.
3. As a member, write an ADR for the app target state (.NET 10, ASP.NET Core MVC, GitHub Copilot's Upgrade agent) and the data target state (SQL Managed Instance, Microsoft Entra authentication only).
4. Move every finding from C3 that you're deferring — including the trace-flag removal after cutover — into the [deferred-work register](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/deferred-work-register.md), each with an owner, a target and a timeline.
5. Commit the ADRs and the register to your team repo.

## Evidence

- At least four ADRs (platform, migration method, app, data), each with a decision, an alternative considered, and a consequence.
- The deferred-work register, with every deferred C3 finding present and the trace-flag removal step explicitly listed.

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
