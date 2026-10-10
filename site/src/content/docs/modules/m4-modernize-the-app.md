---
title: "M4: Modernize the app"
description: Run the Upgrade agent's seven tasks to .NET 10 on the dev VM.
---

## Covers

[C6: Modernize with GHCP](../../challenges/c06-modernize-with-ghcp/). The tasks and evidence are on the challenge page; the [GitHub Copilot upgrade guide](../../guides/ghcp-upgrade/) and the playbook (`.github/modernization/playbook.md`) have the mechanics.

## Prerequisites

C3's reviewed assessment and approved plan (`plan.md`, committed as `app: assess and plan`) from M2, as C6's Inputs list them. M3's archetype deployed, for its registry and its Key Vault, Service Bus, Storage and Application Insights, which the app's checks use. The app doesn't run on App Service yet.

## Where to run

`vm-dev01`, through Bastion, in the kit clone at `C:\src\factory` on your `vm-dev01-work` branch. The portal checks in C6 task 5 can run in any browser.

## Bootstrap (standalone)

A clean kit clone on `vm-dev01` with the Upgrade extension installed, set up as in the playbook's Step 0. Then follow `.github/modernization/plan-prompt.txt` and the playbook's steps 1 to 5.

## Exit evidence

The items in [C6's Evidence](../../challenges/c06-modernize-with-ghcp/#evidence): seven task commits, each preceded by a passing build and local run; the app running on `vm-dev01` with Blob, Service Bus and Application Insights proven live; Key Vault checked; a clean CVE audit or a documented remediation; the image in your registry; and the App Service configuration checked, not changed.

## Reset

`git reset --hard` to the playbook's `app: assess and plan` commit restarts the run from a clean .NET Framework 4.8 tree. It discards uncommitted work, and your next push needs `git push --force-with-lease`. Ask your coach before you reset after you've pushed.

## Time box

180 minutes.
