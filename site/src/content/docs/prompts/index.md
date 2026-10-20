---
title: Prompt library
description: Copy-paste prompts for the Upgrade agent workflow in C3, C6 and C8.
sidebar:
  order: 1
---

Short prompts for the parts of the modernization work that aren't already one paste, like
[`plan-prompt.txt`](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/plan-prompt.txt).
Each page is one prompt: what it's for, the exact text, and what to check afterward. They don't replace the
[playbook](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md),
the [GHCP upgrade guide](../guides/ghcp-upgrade/) or the challenge pages: those explain the why and the
acceptance bar. The playbook is the source of truth for the checks, so these pages link to it instead of copying it.

## Where to run

Unless a page says otherwise, run the prompts on `vm-dev01`, in VS Code opened on `C:\src\factory`, on your
`vm-dev01-work` branch (see [Switching to vm-dev01](../guides/ghcp-upgrade/#switching-to-vm-dev01)). The App Service
check and the acceptance pack say where their commands can run.

## The pages

| When | Page |
| --- | --- |
| Before C3 | [Prerequisites](vscode/00-prerequisites/) |
| C3 | [Assess and plan](vscode/01-assess-and-plan/), [Triage assessment findings](vscode/07-triage-assessment-findings/) |
| C6 | [Run a task](vscode/02-run-a-task/), [CVE scan](vscode/03-cve-scan/), [Troubleshoot](vscode/04-troubleshoot/), [App Service check](vscode/05-app-service-check/) |
| C8 | [Acceptance pack](vscode/06-acceptance-pack/) |

## Copilot app

The pages are written for VS Code, which is the validated path. [Copilot app (best effort)](copilot-app/) lists what
to check if you want to try the GitHub Copilot app instead. It isn't validated, and VS Code is the fallback.
