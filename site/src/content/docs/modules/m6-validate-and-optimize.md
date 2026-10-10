---
title: "M6: Validate and optimize"
description: Acceptance checks and database performance tuning against the live app.
---

## Covers

[C8: Validate the pattern](../../challenges/c08-validate-the-pattern/) and [C9: Optimize the DB with GHCP](../../challenges/c09-optimize-the-db-with-ghcp/). The tasks and evidence are on the challenge pages.

## Prerequisites

M5's app, live on App Service against SQL Managed Instance.

## Where to run

C8's browser checks run in any browser (or on `vm-dev01`), and its load and security checks, including `scripts/Test-Acceptance.ps1`, run in the dev container from `factory/`. C9 runs entirely on `vm-dev01`, in the kit clone at `C:\src\factory`. Never stop `vm-dev01`.

## Bootstrap (standalone)

Against any live Contoso University on SQL Managed Instance: run C8's acceptance pack (the checks in C8 and `templates/attendee/acceptance-handover.md`), and `db/perf-kit/Start-Workload.ps1` against the same managed instance for C9.

## Exit evidence

The items in the Evidence sections of [C8](../../challenges/c08-validate-the-pattern/#evidence) and [C9](../../challenges/c09-optimize-the-db-with-ghcp/#evidence): the acceptance and handover document with every check recorded, a security check that ends in `ACCEPT`, and Query Store before and after evidence for all five planted performance issues.

## Reset

C8's checks are read-only and need no reset. To start C9 from scratch, run `db/perf-kit/Reset-PerfKit.ps1` on `vm-dev01`. Against SQL Managed Instance, run `./db/perf-kit/Reset-PerfKit.ps1 -Server '<sql-mi-host-name>' -Authentication ActiveDirectoryInteractive`. It puts the planted issues back, drops every index added since, and clears Query Store, which deletes your baseline. Save your evidence first, and never run it between a baseline and its re-runs.

## Time box

105 minutes: 45 for C8 and 60 for C9.
