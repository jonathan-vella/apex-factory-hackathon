---
title: "VS Code: diagnose a slow plan"
description: Use Query Store evidence to diagnose one slow query without giving away the fixes.
sidebar:
  label: Diagnose a slow plan (C9)
  order: 9
---

Used in [C9, requirements 1 to 5](../../../challenges/c09-optimize-the-db-with-ghcp/#requirements), on `vm-dev01` in plain Agent mode with the MSSQL extension, not the Upgrade agent.

**Validated on:** 2026-10-31 (documentation consistency with C9's tool, baseline and evidence guidance; no new database or runtime check).

## Before you send

Capture the baseline first. Supply the query, its execution plan and Query Store measurements from the challenge's current database. Remove secrets, identifiers and personal data from pasted output. Keep the saved original in your private evidence folder.

## The prompt

```text
Diagnose this slow query from its execution plan and Query Store baseline: <paste the redacted query, plan and per-call measurements>.

Explain the operators and warnings that support your diagnosis. Separate observed facts from hypotheses and tell me what evidence is missing. Propose the smallest change that addresses the cause, checking existing objects and indexes first. Explain any effect on results or user-visible behavior.

Give me a candidate script to review, a rollback, and a before/after verification using the same query and workload. Do not execute changes, reset the database or clear Query Store. Do not claim improvement before it is measured.
```

## Check and save

Review the proposal against the plan before applying it as C9 directs. Keep one reviewed script per fix and use C9's baseline and two checkpoints, not a separate workload run for every fix. Record per-call duration and reads, any behavior trade-off and the observed effect in `factory/evidence/c09/` in your own repo on `main`.

Return to [C9](../../../challenges/c09-optimize-the-db-with-ghcp/) for the workload, capture commands and acceptance criteria.
