---
title: "M0: Pre-work"
description: Member prerequisites, datacenter and Arc onboarding, done before the event.
---

## Covers

[C0: Ready to hack](../../challenges/c00-ready-to-hack/). The tasks, commands and evidence are on the challenge page.

## Prerequisites

An assigned workload subscription, and the [Prerequisites](../../getting-started/prerequisites/) page done: your own repo from the `apex-accelerator` template, the dev container, the kit imported into `factory/`, and `factory/.local/settings.json` written.

## Where to run

The dev container of your own repo, from `factory/`. M0 needs no shared services subscription, except for the platform lead's Tenant Root check in the preflight task.

## Bootstrap (standalone)

Follow the C0 tasks in order: preflight, deploy the datacenter, `Test-Datacenter.ps1` while both VMs run, Arc onboarding, then the first Arc assessment. The order matters: Arc onboarding turns off the run commands that `Test-Datacenter.ps1` needs.

## Exit evidence

The items in [C0's Evidence](../../challenges/c00-ready-to-hack/#evidence): the preflight output, the `Test-Datacenter.ps1` output from before Arc, the Arc resource with the SQL Server extension, and the first assessment.

## Reset

Re-running `Deploy-Datacenter.ps1` converges the datacenter after a failure. If the datacenter was already vended, the re-run resets its DNS servers and routes, so your platform lead must vend you again (C2). `Connect-DatacenterArc.ps1` can't be re-run: it refuses once `vm-app01` is an Arc machine or its guest agent is off. If onboarding didn't finish, redeploy `vm-app01` with `Deploy-Datacenter.ps1`, then run the Arc script again. Ask your coach before you do either.

## Time box

150 minutes of pre-work, not on the two-day agenda. The deployments run unattended for part of it.
