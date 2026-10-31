---
title: "VS Code: prerequisites"
description: Where the VM setup steps and the check before Step 1 live.
sidebar:
  label: Prerequisites
  order: 1
---

Used before [C3, requirement 1](../../../challenges/c03-assess-the-source/#requirements); complete [Step 3.3](../../../deploy/member-steps/#33-set-up-vm-dev01) first.

**Validated on:** 2026-10-31 (documentation consistency with the linked setup steps and playbook; no new VM or runtime check).

There is nothing to paste here. Your VM is set up once, in [Step 3: Datacenter and workstation](../../../deploy/member-steps/#33-set-up-vm-dev01), and the setup has one source. Don't repeat the steps from memory.

- **The setup steps.** [Step 3.3](../../../deploy/member-steps/#33-set-up-vm-dev01) covers the sign-ins, git identity, `AZURE_TOKEN_CREDENTIALS`, the kit clone, the `member` remote, your `vm-dev01-work` branch, your plain clone for evidence, VS Code and the Upgrade agent. Its [Check your setup](../../../deploy/member-steps/#check-your-setup) list tells you whether the VM is ready.
- **The check before playbook Step 1 (Assess and plan).** [Step 0: Set up](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#step-0-set-up) has the short checklist to run on `vm-dev01`, including the clean-tree check and the `git clean` commands.

Run everything on `vm-dev01`, in PowerShell 7. When the check passes, continue to [Assess and plan](../01-assess-and-plan/).
