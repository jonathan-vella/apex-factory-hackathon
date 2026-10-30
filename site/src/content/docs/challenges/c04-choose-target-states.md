---
title: "C4: Choose target states"
description: Commit to app, data, platform and migration-method decisions as ADRs, and record everything you are deferring.
---

## Background

C3 told you what the source looks like. C4 turns that into decisions the team stands behind. The kit has already fixed the target states, so the value here is the alternative you weighed and the consequence you accept, not the choice itself.

**Business context.** Dana, the CIO, has to take the plan to the board. C4 puts each decision in writing, with the road not taken and what the choice costs, so she can defend it.

**Business outcome.** Current platform. The ADRs name the target stack (.NET 10, ASP.NET Core, App Service and SQL Managed Instance) and why each beats its alternative. Deferred work has an owner and a date, so nothing is forgotten.

**Objective.** Be able to record a decision as an architecture decision record (ADR) with its alternative and consequence, and to track the work you are consciously not doing yet.

**Time and points.** Day 1, **11:30**, **45 min**, **Team and member**, **25 pts** (15 team + 10 member).

## Challenge

**Starting point.** Everyone's triaged C3 findings (`factory/evidence/c03/triage.md`), including the trace-flag decision, and C2's datacenter compliance/deferred-work entry ("none needed" is valid for exemptions). Each teammate shares theirs on the shared screen.

**Fixed by the kit.** The platform is the CoE archetype (App Service, container registry, SQL Managed Instance, Blob, Service Bus, Key Vault, Application Insights). The migration method is the Arc SQL migration assessment plus the MI link, online, with a planned cutover. The app target is .NET 10 and ASP.NET Core MVC. The data target is SQL Managed Instance with Microsoft Entra authentication only.

**You decide.** The platform ADR's alternative is yours. The other ADRs give alternatives as a starting point: explain why you reject them and the consequence you accept. Also decide which C3 findings you defer, who owns them and when they get done.

**Where to work.** Your own repo's dev container, in a terminal at the repo root. No Azure access is needed. The team writes the team documents together: one person types on a shared screen, then every teammate saves the final file under the same name in their own `factory/evidence/c04/`.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

### Set up the files

Run `git pull`, then copy the templates ([ADR](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/adr.md), [deferred-work register](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/deferred-work-register.md)) from `factory/templates/attendee/`. This gives you four ADR files and the register, each with prompts to fill in:

```bash
git pull
mkdir -p factory/evidence/c04
for name in adr-platform adr-migration adr-app adr-data; do cp factory/templates/attendee/adr.md "factory/evidence/c04/$name.md"; done
cp factory/templates/attendee/deferred-work-register.md factory/evidence/c04/
```

## Requirements

1. **Platform ADR (team, about 10 min).** Write `adr-platform.md`: the shape of the CoE archetype and why it fits C1's opportunity.

2. **Migration-method ADR (team, about 10 min).** Write `adr-migration.md`. The decision is the one the kit fixes: the Arc SQL migration assessment plus the MI link, online, with a planned cutover. Record an offline backup and restore as the alternative. Its consequence is a long outage while the backup restores, where the link needs only a short stop at cutover.

3. **App ADR (each member, about 5 min).** In your own repo, write `adr-app.md` for the app target state: .NET 10, ASP.NET Core MVC, GitHub Copilot's Upgrade agent. The alternative can be keeping .NET Framework 4.8 on a VM, or a manual rewrite.

4. **Data ADR (each member, about 5 min).** In your own repo, write `adr-data.md` for the data target state: SQL Managed Instance, Microsoft Entra authentication only. The alternative is SQL Server on an Azure VM. Choose SQL MI unless C3's triage found a real blocker, which means a feature the app uses that SQL MI doesn't support at all. If you found none, the VM is the alternative you rejected. If you found one, name it in the ADR and decide for the VM.

5. **Deferred-work register (team, about 10 min).** Assemble `deferred-work-register.md`. One teammate types it from everyone's `triage.md`. It holds:
   - every C3 finding you are deferring, including the trace-flag removal after cutover, with one row per member because each member has their own `vm-app01`;
   - one datacenter entry per member from C2, even when no exemption is needed. Record the production target, a named teammate as owner and a timeline. If an exemption exists, read its reason, owner and target date from the description and replace "GitHub Actions pipeline" with the accountable teammate. Map the policy assignment to finding and its target date to timeline; the target is to meet the policy and retire the exemption.

   Every row has an owner, a target and a timeline.

6. **Commit (about 5 min).** Commit and push everything to `main` of your own repo. Every teammate saves the final team files under the same names as their teammates.

## Success criteria

To complete this challenge, show your coach in your own repo's `factory/evidence/c04/`:

- [ ] The platform and migration-method ADRs, each with a decision, an alternative and a consequence. They are scored once, from the team lead's copy.
- [ ] Your own `adr-app.md` and `adr-data.md`, each with a decision, an alternative and a consequence.
- [ ] The deferred-work register with every deferred C3 finding present, and the trace-flag removal step listed for each member.
- [ ] The team files match your teammates' copies.
- [ ] Outcome check (unscored guidance): your ADRs tie back to the top-ranked outcome from C1, and Dana could read them without asking you a question.

Evidence rule: in the dev container, run `git pull` first. On `vm-dev01`, use `C:\src\<your-repo>\factory\evidence\c04\` (the plain clone of your own repo) and run `git pull --rebase` first. Commit with a conventional message, for example `docs: C4 target-state decisions`, and run `git push`.

<details>
<summary>How detailed does an ADR need to be?</summary>

One page: context, decision, alternatives considered, consequences. The template has headings for each. Fill them in, don't pad them.

</details>

<details>
<summary>What goes in the register versus an ADR?</summary>

An ADR commits to a choice. The register tracks something you're explicitly not doing now, like removing the trace flags only after the link is gone. If it has an owner and a date, it's a register entry, not a decision.

</details>

<details>
<summary>If you need to start over</summary>

ADRs and the register are append-only documents, and there's nothing in Azure to reset. Correct a file in place and commit the change, for example `docs: correct C4 ADR`. To change a decision you already committed, set its Status to Superseded and write a new ADR instead of deleting the old one.

</details>

**Bonus.** None for C4.

## References

- [Architecture decision records overview](https://learn.microsoft.com/azure/well-architected/architect-role/architecture-decision-record)
- [Migration overview: SQL Server to Azure SQL Managed Instance](https://learn.microsoft.com/azure/azure-sql/migration-guides/managed-instance/sql-server-to-managed-instance-overview)

Next: [C5: Deploy the CoE archetype with APEX](../c05-deploy-the-coe-archetype/).
