---
title: "VS Code: acceptance pack"
description: Diagnose a failed C8 acceptance check with plain Agent mode.
sidebar:
  label: Acceptance pack (C8)
  order: 8
---

Used in [C8, requirements 1 to 5](../../../challenges/c08-validate-the-pattern/#requirements).

C8's acceptance pack is the checklist. This page only adds the prompt for interpreting a failure. The tasks, the
commands and where each one runs are in [C8](../../../challenges/c08-validate-the-pattern/), and the read-only
`Test-Acceptance.ps1` check is its task 5.

## Where to run

Browser checks run in any browser. The row counts and the blob listing run on `vm-dev01`, because the databases
and storage are private-only. The load and security checks run in your dev container, from `factory/`. C8's
**Where to run** table has the details.

## If you want the agent to help with a failure

```text
This acceptance pack check failed: <paste the exact symptom or Test-Acceptance.ps1 output>. Diagnose the likely cause (app configuration, network/private endpoint, or identity/role) without changing anything, and tell me what to check next.
```

Paste the real output. The agent can't see your terminal, and a guess at the cause costs more time than the
check itself.

## Check

- Every C8 requirement has a result (pass, fail or not applicable) with evidence, in the
  [acceptance and handover template](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/acceptance-handover.md).
- `Test-Acceptance.ps1` ends `ACCEPT`, or each UNKNOWN is settled in the portal as C8 describes.
