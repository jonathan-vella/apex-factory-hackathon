---
title: Azure Hybrid Benefit
description: What's on by default, and how to turn it off if you need to.
sidebar:
  order: 2
---

Azure Hybrid Benefit (AHB) is on by default everywhere the kit deploys a Windows Server or SQL Server license, trading an on-premises license you already own for a lower Azure rate. The owner decision for this kit is to always use it — it's part of the cost model, not an optional saving.

## Where it applies

| Resource | AHB setting |
|---|---|
| `vm-app01` (Windows Server license) | `Windows_Server`, on by default. Optional |
| `vm-dev01` (Windows 11 dev VM) | `Windows_Client` (multitenant hosting rights, which Windows 11 on Azure needs). Mandatory, not optional |
| SQL Managed Instance (`licenseType`) | `BasePrice` (AHB applied), never the SQL MI free offer |

## Turning it off

If you need to compare costs with and without AHB (for example, for a customer who doesn't hold an eligible on-premises license), turn it off for `vm-app01` only, with `Deploy-Datacenter.ps1 -NoHybridBenefit` or `az vm update -g rg-datacenter -n vm-app01 --license-type None`, or set the managed instance's `licenseType` to `LicenseIncluded`, and redeploy. Leave `vm-dev01` on `Windows_Client`. Don't leave AHB off after the comparison: the kit's cost figures throughout this site assume it's on.
