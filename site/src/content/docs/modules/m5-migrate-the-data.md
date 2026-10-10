---
title: "M5: Migrate the data"
description: Seed, validate, cut over, and bring the app live on App Service.
---

## Covers

[C7: Migrate and go live](../../challenges/c07-migrate-and-go-live/).

## Prerequisites

M3's deployed SQL Managed Instance. M4's modernized, packaged app image.

## Bootstrap (standalone)

Start an MI link migration from the Arc portal against a deployed SQL Managed Instance and a source SQL Server already onboarded to Arc. If a member gets stuck, ask your coach.

## Exit evidence

- The MI link seeded, validated and cut over, with the link removed afterward.
- The contained database user created for the web app's managed identity.
- The app live on App Service against SQL MI, serving the five pages with migrated data.
- The cutover and rollback runbook, written from what actually happened.

## Reset

Delete the MI link and any partially seeded database on the MI, then restart the seed. If the web app won't start after go-live, check the Key Vault secret and the database user first, and ask your coach.

## Time box

120 minutes.

## Last validated

2026-10-02 (B07).
