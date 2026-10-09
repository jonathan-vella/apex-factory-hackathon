---
title: Azure Hybrid Benefit
description: What's on by default, and how to turn it off if you need to.
---

Azure Hybrid Benefit (AHB) is on by default everywhere the kit deploys a Windows Server or SQL Server licence, trading an on-premises licence you already own for a lower Azure rate. The owner decision for this kit is to always use it — it's part of the cost model, not an optional saving.

## Where it applies

| Resource | AHB setting |
|---|---|
| `vm-app01`, `vm-dev01` (Windows Server licence) | On |
| SQL Managed Instance (`licenseType`) | `BasePrice` (AHB applied) — never the `SameAsSource` setting, and never the SQL MI free offer |

## Turning it off

If you need to compare costs with and without AHB (for example, for a customer who doesn't hold an eligible on-premises licence), set the VM licence type to none, or the managed instance's `licenseType` to `LicenseIncluded`, and redeploy. Don't leave it off after the comparison — the kit's cost figures throughout this site assume AHB is on.
