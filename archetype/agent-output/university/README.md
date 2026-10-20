<!-- markdownlint-disable MD033 MD041 -->

<a id="readme-top"></a>

<div align="center">

![Status](https://img.shields.io/badge/Status-In%20Progress-yellow?style=for-the-badge)
![Step](https://img.shields.io/badge/Step-4%20of%207-blue?style=for-the-badge)

# 🏗️ university

**CoE archetype (B09): Azure platform for the Contoso University app in an existing Corp landing zone spoke**

[View Architecture](#-architecture) · [View Artifacts](#-generated-artifacts) · [View Progress](#-workflow-progress)

</div>

---

## 📋 Project Summary

| Property           | Value                                                          |
| ------------------ | -------------------------------------------------------------- |
| **Created**        | 2026-10-05                                                     |
| **Last Updated**   | 2026-10-09                                                     |
| **Region**         | swedencentral (derived from hub; alternate germanywestcentral) |
| **Environment**    | dev (training/demo)                                            |
| **Estimated Cost** | $1,320.95/month (≈ $1.81/hour), Step 2 verified pricing        |
| **AVM Coverage**   | Pinned AVM modules; raw SQL MI, schedule and diagnostic settings; 36 resources planned |

---

## ✅ Workflow Progress

Step 4 is owner-reopened for kit #52/#60. Approved plan-only clarifications and dependency-diagram PNG/SVG are
finalized and validated. Fresh named Challenger [pass 9](challenge-findings-plan-pass9.json) returned
`NEEDS_REVISION` (one must-fix, no should-fix or suggestions); the plan remains `DRAFT`.
The owner retains the B08/shared-identity architecture for this hackathon and accepts the residual LAB risk below.
Acceptance is not technical remediation and does not clear `569fbf8e` or the renewed gate-3 requirement.
Historical Step 5 completion does not authorize CodeGen or deployment from this draft.

### Hackathon-Only Residual LAB Risk: 569fbf8e

Owner decision recorded 2026-10-09: retain the existing shared identity, Graph grants, member assignment rights and
workload Owner authority. Participants with resource-write permission and shared-identity assignment rights can
attach it to non-SQL-MI resources. Its Graph application permissions expose tenant-wide directory read;
short-lived workload subscriptions do not contain that exposure. Historical normal-user directory visibility
does not establish an equivalent boundary to the identity's app-only Graph permissions.

This acceptance applies only to this hackathon, not production reuse. Pass9's `must_fix` severity and every
historical finding, disposition and hash remain unchanged; no control is claimed implemented or finding closed.
The intended final teardown deletes the shared identity only after all SQL MI consumers have been removed.
Rehearsal teardown previously retained it; final deletion has not been evidenced and is not claimed to have happened.

| Outstanding Input | Evidence Status |
| --- | --- |
| Tenant-owner approval | Not recorded; workload-owner acceptance does not prove tenant-owner authority or approval. |
| Event-end date | Not provided; the cost-monitoring exception expiry is not an event-end date. |
| Cleanup owner | B08 lifecycle ownership is known; a named accountable final-teardown operator is not recorded. |
| Verification evidence | Consumer-removal inventory and final identity-deletion proof are not supplied. |

**APEX contract result:** supported decision logging records this owner acceptance but permits no approval,
Step 4 completion, CodeGen, Azure change or deployment. The
[review lifecycle](../../.github/skills/apex-azure-defaults/references/adversarial-review-protocol.md#review-lifecycle)
and [Planner approval contract](../../.github/skills/apex-iac-common/references/iac-planner-approval-gate.md)
block unresolved must-fix findings. The
[runtime completion check](../../tools/apex-recall/src/apex_recall/commands/complete_step.py#L133)
rejects them independently of risk decisions. `--allow-missing-challenger` applies only to missing reviews;
`--plan-review` selects evidence, not an exception. Neither permits bypassing pass9.

**Required workflow-owner route:** human handoff to `01-Orchestrator` to obtain explicit APEX workflow/governance-owner
authorization for a versioned, hackathon-specific exception contract. It must specify required approver authority
(including tenant-owner approval), project/event scope and end date, cleanup accountability and verification evidence,
expiry/revocation conditions, and exactly which gates a recorded exception can permit. It must preserve the finding's
must-fix severity and distinguish accepted risk from technical closure, without waiving non-negotiable baseline or
governance requirements. The owner must reconcile the review lifecycle, Planner gate-3 contract, workflow graph and
`complete-step` / `transition --complete` enforcement before such an exception can authorize advancement.
Specifically, `gate-3`'s `plan-readiness` precondition in the
[workflow graph](../../.github/skills/apex-workflow-engine/templates/workflow-graph.json)
requires `challenger.exit_criteria == 'all-passes-APPROVED'` and otherwise stays at Step 4. Any owner-authorized
lab-exception change must define a legitimate alternative attestation while preserving pass9's must-fix, and
reconcile it with the runtime rejection above; setting an approval flag alone cannot satisfy either contract.
That contract change is not authorized here; no validator, workflow or review is changed. The current decision alone
cannot open gate-3. No review is rerun to seek a different verdict; documentation and the finalized #52/#60 inputs
remain available while Step 4 stays `DRAFT`.

| Step | Phase          |                                    Status                                     | Artifact                                                           |
| :--: | -------------- | :---------------------------------------------------------------------------: | ------------------------------------------------------------------ |
|  1   | Requirements   |     ![Done](https://img.shields.io/badge/-Done-success?style=flat-square)     | [01-requirements.md](./01-requirements.md)                         |
|  2   | Architecture   |     ![Done](https://img.shields.io/badge/-Done-success?style=flat-square)     | [02-architecture-assessment.md](./02-architecture-assessment.md) · [03-des-cost-estimate.md](./03-des-cost-estimate.md) — approved 2026-10-06 |
|  3   | Design         |     ![Done](https://img.shields.io/badge/-Done-success?style=flat-square)     | [03-des-diagram.png](./03-des-diagram.png) · [03-des-network-diagram.png](./03-des-network-diagram.png) · 8 ADRs (`03-des-adr-*.md`) — approved 2026-10-06 |
| 3.5  | Governance     |     ![Done](https://img.shields.io/badge/-Done-success?style=flat-square)     | [04-governance-constraints.md](./04-governance-constraints.md) · [04-governance-constraints.json](./04-governance-constraints.json) — approved 2026-10-06 |
|  4   | Planning       |     ![WIP](https://img.shields.io/badge/-WIP-yellow?style=flat-square)     | [04-implementation-plan.md](./04-implementation-plan.md) · [04-iac-contract.json](./04-iac-contract.json) — owner-reopened 2026-10-09 for kit #52/#60; prior approval is historical, not approval of this draft |
|  5   | Implementation | Historical completion | [05-implementation-reference.md](./05-implementation-reference.md) · [04-preflight-check.md](./04-preflight-check.md) · [05-iac-handoff.json](./05-iac-handoff.json) — evidence for predecessor plan `5a4b96e4`, not this revised draft; no infrastructure changed during Step 4 reopening |
|  6   | Deployment     | ![Pending](https://img.shields.io/badge/-Pending-lightgrey?style=flat-square) | [06-deployment-summary.md](./06-deployment-summary.md)             |
|  7   | Documentation  | ![Pending](https://img.shields.io/badge/-Pending-lightgrey?style=flat-square) | [07-documentation-index.md](./07-documentation-index.md)           |

> **Legend**:
> ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) Complete
> | ![WIP](https://img.shields.io/badge/-WIP-yellow?style=flat-square) In Progress
> | ![Pending](https://img.shields.io/badge/-Pending-lightgrey?style=flat-square) Pending
> | ![Skip](https://img.shields.io/badge/-Skipped-blue?style=flat-square) Skipped

---

## 🏛️ Architecture

- Design: [03-des-diagram.png](./03-des-diagram.png) · [03-des-network-diagram.png](./03-des-network-diagram.png)
- Plan: [04-dependency-diagram.png](./04-dependency-diagram.png) · [04-runtime-diagram.png](./04-runtime-diagram.png)

### Key Resources

| Resource                 | Type                                | SKU                     | Purpose                                 |
| ------------------------ | ----------------------------------- | ----------------------- | --------------------------------------- |
| App Service plan + app   | Microsoft.Web                       | P0v3 (Linux, container) | Hosts the Contoso University container  |
| Container registry       | Microsoft.ContainerRegistry         | Premium                 | Private image registry                  |
| SQL Managed Instance     | Microsoft.Sql/managedInstances      | GP Gen5, 4 vCores, 64 GB | Migration target database              |
| Storage account          | Microsoft.Storage                   | Standard_LRS (GPv2)     | `teaching-materials` blobs              |
| Service Bus namespace    | Microsoft.ServiceBus                | Premium, 1 MU           | `notifications` queue                   |
| Key Vault                | Microsoft.KeyVault                  | Standard                | Runtime secrets                         |
| Application Insights     | Microsoft.Insights                  | Workspace-based         | Telemetry to central `log-management`   |
| User-assigned identity   | Microsoft.ManagedIdentity           | —                       | Web app runtime identity                |

---

## 📄 Generated Artifacts

<details open>
<summary><strong>📁 Step 1-3: Requirements, Architecture & Design</strong></summary>

| File                                       | Description                        |                               Status                               | Created    |
| ------------------------------------------ | ---------------------------------- | :----------------------------------------------------------------: | ---------- |
| [01-requirements.md](./01-requirements.md) | Project requirements with NFRs     | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-05 |
| [sku-manifest.json](./sku-manifest.json)   | SKU manifest rev 3 (Step 4 reconciled, locked) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-07 |
| [sku-manifest.md](./sku-manifest.md)       | Rendered SKU manifest              | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-05 |
| [challenge-findings-requirements.json](./challenge-findings-requirements.json) | Step 1 challenger review | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-05 |
| [challenge-findings-requirements-decisions.json](./challenge-findings-requirements-decisions.json) | Per-finding decisions | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-05 |
| [02-architecture-assessment.md](./02-architecture-assessment.md) | WAF assessment (S 8, R 4, P 6, C 7, O 7) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |
| [03-des-cost-estimate.md](./03-des-cost-estimate.md) | Cost estimate ($1,320.95/month) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |
| [02-waf-scores.png](./02-waf-scores.png) · [03-des-cost-distribution.png](./03-des-cost-distribution.png) · [03-des-cost-projection.png](./03-des-cost-projection.png) | Charts (`.py` + `.png` + `.svg`) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |
| [02-cost-estimate.json](./02-cost-estimate.json) | Workload pricing (COMPLETE, ARM MCP) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |
| [02-cost-estimate-sqlmi-options.json](./02-cost-estimate-sqlmi-options.json) · [02-cost-estimate-sqlmi-schedule.json](./02-cost-estimate-sqlmi-schedule.json) · [02-cost-estimate-shared-services.json](./02-cost-estimate-shared-services.json) · [02-cost-estimate-manifest.json](./02-cost-estimate-manifest.json) | Comparison, shared-services and manifest pricing (COMPLETE) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |
| [challenge-findings-architecture.json](./challenge-findings-architecture.json) | Step 2 architecture review (APPROVED) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |
| [challenge-findings-cost-estimate.json](./challenge-findings-cost-estimate.json) | Step 2 cost-feasibility review (APPROVED) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |
| [challenge-findings-architecture-decisions.json](./challenge-findings-architecture-decisions.json) | Step 2 per-finding decisions | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |

</details>

<details open>
<summary><strong>📁 Step 3.5-4: Governance & Implementation Plan</strong></summary>

| File | Description | Status | Created |
| ---- | ----------- | :----: | ------- |
| [04-governance-constraints.md](./04-governance-constraints.md) · [04-governance-constraints.json](./04-governance-constraints.json) | Governance constraints (19 Deny) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |
| [04-implementation-plan.md](./04-implementation-plan.md) | Draft kit #52/#60 revision (single deployment, 36 resources); renewed approval required | ![WIP](https://img.shields.io/badge/-WIP-yellow?style=flat-square) | 2026-10-09 |
| [04-iac-contract.json](./04-iac-contract.json) · [04-policy-property-map.json](./04-policy-property-map.json) · [04-environment-manifest.json](./04-environment-manifest.json) | Draft IaC contract revised; policy map and environment manifest preserved | ![WIP](https://img.shields.io/badge/-WIP-yellow?style=flat-square) | 2026-10-09 |
| [04-dependency-diagram.png](./04-dependency-diagram.png) · [04-runtime-diagram.png](./04-runtime-diagram.png) | Plan diagrams (`.py` + `.png` + `.svg`) | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-06 |
| [challenge-findings-plan.json](./challenge-findings-plan.json) to [challenge-findings-plan-pass7.json](./challenge-findings-plan-pass7.json) | Historical Step 4 reviews preserved; selected [pass 3](./challenge-findings-plan-pass3.json) is stale for this revision, never restamped | Historical | 2026-10-07 |
| [challenge-findings-plan-pass8.json](./challenge-findings-plan-pass8.json) | Independent #52/#60 comprehensive confirmation; strict input verification passed; `NEEDS_REVISION` | Blocked: `569fbf8e` needs B08-owned control evidence beyond this revision scope | 2026-10-09 |
| [challenge-findings-plan-pass9.json](./challenge-findings-plan-pass9.json) | Fresh independent adjudication after approved clarifications; all declared input hashes verified | `NEEDS_REVISION`: `569fbf8e` upheld; historical acceptance preserved, not technical closure | 2026-10-09 |
| [challenge-findings-plan-decisions.json](./challenge-findings-plan-decisions.json) | Step 4 per-finding decisions | ![Done](https://img.shields.io/badge/-Done-success?style=flat-square) | 2026-10-07 |

</details>

---

## 🔗 Related Resources

| Resource            | Path                                                                           |
| ------------------- | ------------------------------------------------------------------------------ |
| **Bicep Templates** | [`infra/bicep/university/`](../../infra/bicep/university/) (created at Step 5) |
| **Workflow Docs**   | [Published workflow guide](https://apexops.pro/concepts/workflow/)             |
| **Troubleshooting** | [Published troubleshooting guide](https://apexops.pro/guides/troubleshooting/) |

---

<div align="center">

**Generated by [APEX](../../README.md)** · 02-Requirements agent | 2026-10-05

<a href="#readme-top">⬆️ Back to Top</a>

</div>
