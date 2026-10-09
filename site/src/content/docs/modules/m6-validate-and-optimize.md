---
title: "M6: Validate and optimize"
description: Acceptance checks and database performance tuning against the live app.
---

## Covers

[C8: Validate the pattern](../../challenges/c08-validate-the-pattern/), [C9: Optimize the DB with GHCP](../../challenges/c09-optimize-the-db-with-ghcp/).

## Prerequisites

M5's app, live on App Service against SQL MI.

## Bootstrap (standalone)

Against any live Contoso University on SQL MI: run the acceptance pack from `templates/attendee/acceptance-handover.md`, and `db/perf-kit`'s `Start-Workload.ps1` against the same MI for C9.

## Exit evidence

- The acceptance and handover document, every check recorded.
- Query Store before/after evidence for all five planted performance issues.

## Reset

`db/perf-kit/scripts/Reset-PerfKit.ps1` restores the planted issues and workload baseline for a repeat run of C9. C8's checks are read-only and need no reset.

## Time box

105 minutes (45 + 60).

## Last validated

2026-09-25 (B05), 2026-10-08 (B10 acceptance checks).
