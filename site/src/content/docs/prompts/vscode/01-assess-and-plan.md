---
title: "VS Code: assess and plan"
description: Assess and plan in C3 requirement 1, using the Upgrade agent.
sidebar:
  label: Assess and plan (C3)
  order: 2
---

Used in [C3, requirement 1](../../../challenges/c03-assess-the-source/#requirements).

## Before you send

1. Check your VM is ready, as in [VS Code: prerequisites](../00-prerequisites/).
2. A new chat, harness **Local**, agent **Upgrade**, a balanced model (Sonnet- or Terra-class) for the
   assessment — see the playbook's [Models](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#models)
   table.

## The prompt

Paste the whole of `.github/modernization/plan-prompt.txt` with its characters intact:

```powershell
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Get-Content -Raw -Encoding utf8 .github\modernization\plan-prompt.txt | Set-Clipboard
```

Then paste the clipboard into the chat and send it. Answer the pre-initialization confirmation as the prompt
says: target `net10.0`, **Guided**, stay on the current branch, commit strategy **Manual**, branch sync off.

## Check the assessment and plan gates

Follow the assessment and plan gates, required-output checks, recovery steps and commit guidance in
[Step 1 of the playbook](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#step-1-assess-and-plan-c3).
Use a balanced model for assessment, then switch to the most capable model before approving planning; the
playbook's [Models table](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#models)
is the source for picker guidance.
