---
title: "VS Code: prerequisites"
description: Where the VM setup steps and the check before Step 1 live.
sidebar:
  order: 1
---

There is nothing to paste here. Your VM is set up once, in the readiness check ([set up `vm-dev01`](../../../deploy/member-steps/#set-up-vm-dev01)), and the steps live in two places. Don't repeat them from memory.

- **The setup steps.** The guide's [Switching to vm-dev01](../../../guides/ghcp-upgrade/#switching-to-vm-dev01) section covers the sign-ins, git identity, `AZURE_TOKEN_CREDENTIALS`, the kit clone, the `member` remote, your `vm-dev01-work` branch, your plain clone for evidence, VS Code and the Upgrade agent. Its [Check your setup](../../../guides/ghcp-upgrade/#check-your-setup) list tells you whether the VM is ready.
- **The check before Step 1.** The playbook's [Step 0: Set up](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#step-0-set-up) has the short checklist to run on `vm-dev01`, including the clean-tree check and the `git clean` commands.

Run everything on `vm-dev01`, in PowerShell 7. When the check passes, continue to [Assess and plan](../01-assess-and-plan/).
