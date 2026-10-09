---
title: "M4: Modernize the app"
description: Run the Upgrade agent's seven tasks to .NET 10 on the dev VM.
---

## Covers

[C6: Modernize with GHCP](../../challenges/c06-modernize-with-ghcp/).

## Prerequisites

M2's reviewed assessment and plan. M3's archetype deployed (for its registry; the app doesn't run against it yet).

## Bootstrap (standalone)

A clean clone of `app/ContosoUniversity` on a dev VM with the Upgrade agent installed, following `.github/modernization/plan-prompt.txt` and `.github/modernization/playbook.md`. If a member gets stuck mid-run, ask your coach.

## Exit evidence

- Seven task commits, each preceded by a passing build and local run.
- The app running on the dev VM against the source database, with Blob, Service Bus and OpenTelemetry all proven live.
- A clean CVE audit, or a documented remediation.
- The image pushed to the archetype's registry.

## Reset

`git reset --hard` to the commit before task 01 (recorded by the playbook's Step 0) restarts the run from a clean .NET Framework 4.8 tree.

## Time box

180 minutes.

## Last validated

2026-10-02 (B06), 2026-10-08 (B10 lifelines).
