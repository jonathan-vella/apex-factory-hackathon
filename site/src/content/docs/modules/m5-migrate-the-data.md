---
title: "M5: Migrate the data"
description: Seed, validate, cut over, and bring the app live on App Service.
---

## Covers

[C7: Migrate and go live](../../challenges/c07-migrate-and-go-live/). The tasks and evidence are on the challenge page; the [Arc and MI link guide](../../guides/arc-mi-link/) has the mechanics.

## Prerequisites

M3's deployed SQL Managed Instance and M4's packaged app image. The Graph read grant for `id-sqlmi-directory` from C2, or `CREATE USER ... FROM EXTERNAL PROVIDER` fails. A source SQL Server already onboarded to Arc (M0).

## Where to run

The Azure portal for the link, SSMS and PowerShell on `vm-dev01` for the database user, the Key Vault secret and the web app, and `vm-app01` through Bastion for the maintenance window. Never stop or deallocate `vm-dev01`.

## Bootstrap (standalone)

Start an MI link migration from the Arc portal against your deployed SQL Managed Instance, then follow the C7 tasks in order. Stop every writer to the source before you cut over.

## Exit evidence

The items in [C7's Evidence](../../challenges/c07-migrate-and-go-live/#evidence): the migration status through link removal, the maintenance-window output (site and pool stopped, an empty session list, lag 0), the app live on App Service with the migrated data, the contained database user, the source's trace flags (`-T1800`, `-T9567`) removed, and the cutover and rollback runbook.

## Reset

Delete the MI link and any partially seeded database on the managed instance, then restart the seed. If the web app won't start after go-live, check the Key Vault secret and the database user first, then ask your coach.

## Time box

120 minutes.
