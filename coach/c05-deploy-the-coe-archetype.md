# C5 answer key: Deploy the CoE archetype with APEX

> [!WARNING]
> Coach material. This page has the answers to C5. Attendees run APEX's `/apex-adapt-archetype` flow themselves, in the local dev container.

The one thing to watch for here is members trying this natively on Windows — it produces a subtle, hard-to-diagnose failure (a corrupted tree hash from CRLF line endings), not an obvious error.

## Expected evidence

- The member's own repo (created from `apex-accelerator`) with the kit imported by `Import-Kit.ps1`, which also imports the archetype's APEX project into the repo root. There's no pinned tag or commit: the import takes `main`.
- `/apex-adapt-archetype`'s outputs: the governance check's result, and the stop at `azd provision --preview`.
- `azd provision`'s deployment record (resource group populated).
- `agent-output/university/06-deployment-summary.md`, the deployment summary `azd provision` writes. Check it for IDs before it is committed.
- `agent-output/university/07-as-built.md` from the As-Built agent, describing the deployed state.
- `az resource list -g rg-university-<suffix> -o table` showing App Service, ACR, SQL MI, Storage (Blob), Service Bus, Key Vault and Application Insights.
- `factory/evidence/c05/governance-note.md`: any policy-compliance finding the governance check surfaced and how it was resolved, or "none".

## Model answer

1. The member's repo and the archetype are already in place from the repo setup (`Import-Kit.ps1`). If the archetype is missing, run `./factory/archetype/Import-Archetype.ps1 -Ref main` from the repo root.
2. Open the repo in the dev container (never natively on Windows — `.gitattributes` forces LF for `*.bicep` but not `*.bicepparam`, and a Windows checkout corrupts the tree hash the governance check relies on).
3. Run `/apex-adapt-archetype` in agent mode: it asks only for tenant ID, subscription ID and suffix, confirms the spoke that vending created before the event exists (`rg-spoke`, `vnet-spoke`, `snet-app`, `snet-pe`, `snet-sqlmi`), runs its lightweight governance check, and stops at `azd provision --preview`.
4. Review the preview (see the "looks incomplete" hint below — it's expected to be partial), then run `azd provision` for real.
5. Run agent `08-As-Built` to produce the deployed-state document.
6. Confirm no public endpoints beyond the web app's front end and Application Insights ingestion (the member's `publicNetworkAccess` queries on Storage, Key Vault, Service Bus and ACR all return `Disabled`), naming convention followed, and the web app identity's six role assignments present: AcrPull, Key Vault Secrets User, Storage Blob Data Contributor, Service Bus Data Sender, Service Bus Data Receiver and Monitoring Metrics Publisher. Monitoring Metrics Publisher is required, not a known gap: Application Insights has local authentication off, so telemetry needs it. The template grants it to the web app identity and, since 2026-10-20 ([#60](https://github.com/jonathan-vella/apex-factory-hackathon/issues/60)), to the member who deploys. If the member's own grant is missing on an older deployment, they grant it once with the command in the C6 task 06 check of the [playbook](../.github/modernization/playbook.md) (`az role assignment create --role 'Monitoring Metrics Publisher'` on the Application Insights resource). The student page says "five roles" but lists six: the count is six.
7. SQL MI licensing. The archetype prices SQL MI with Azure Hybrid Benefit (`licenseType` is `'BasePrice'` in `infra/bicep/university/modules/sql-mi.bicep`, which assumes SQL Server core licenses with Software Assurance). A member without them changes `var licenseType = 'BasePrice'` to `'LicenseIncluded'` in that file **before** `azd provision`. After deployment, use `az sql mi update -g rg-university-<suffix> -n sqlmi-university-<suffix> --license-type LicenseIncluded` and make the same Bicep edit, or the next `azd provision` sets it back. It costs about $0.40 more per hour (about $292 a month at 730 hours: $0.67 an hour with Hybrid Benefit, $1.07 licence-included; see `archetype/agent-output/university/02-cost-estimate-sqlmi-options.json`). Ask the member to tell you which case they are before they deploy, and note it in the evidence. This is the same question as the readiness check's `-NoHybridBenefit`, which covers only `vm-app01`.

## Business outcome check

The outcome is repeatable provisioning. Check that the deployment summary and the As-Built record describe the resources the resource listing shows. This supports the scoring rows on the deployment record, the As-Built document and the resource listing. It earns no points of its own.

## Common mistakes

- Running `/apex-adapt-archetype` natively on Windows "because the dev container is slow to start" — this is the single most impactful mistake in C5; insist on the dev container every time.
- Treating `azd provision --preview`'s partial output as a failure — it only lists resource types `azd` has display names for; SQL MI, the managed identity, role assignments and the maintenance schedule are created even though the preview doesn't name them.
- Skipping the As-Built step because the deployment "obviously worked" — As-Built is graded evidence, not optional.
- Trying to run `/apex-adapt-archetype` for a member who hasn't been vended yet (vending is the team lead's T-1 run, or later for a member whose readiness record was approved late) — it fails fast with a clear "spoke not found" message; this is a sequencing issue, not a bug. A preflight that stops with "cannot be read" or a missing `assign/action` permission on `id-sqlmi-directory` means vending ran without the member's `-MemberPrincipalId`: the team lead re-runs vending with it.

## Partial credit

- Deployment succeeds but As-Built step skipped: partial credit, complete it before moving on — it's needed as an artifact for C10's reusable-asset packaging.
- A policy-compliance finding surfaced by the governance check and resolved, but not noted on the evidence page: partial credit, ask the member to add the one-line note the challenge page asks for.

## Bonus

The no-agent fallback compared with the APEX path, in preview only (`./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix -WhatIf` from `factory/`, against `azd provision --preview`), is worth up to 5 bonus points — useful for members curious about what the agent flow automates versus the fallback script. Discourage a real fallback run after `azd`: same resource group and SQL MI subnet, and it can reset the web app to the placeholder image.

## Reset

`azd down --purge` then redeploy from the member's repo if something needs a clean restart. **It deletes `rg-university-<suffix>` including the SQL managed instance and, after C7, the migrated database**, so only use it before C7, and tell the member first. After the managed instance is deleted, its SQL virtual cluster keeps holding `snet-sqlmi` for a while, and the preflight stops with "a SQL virtual cluster from a deleted managed instance still holds snet-sqlmi" until Azure releases it (this can take hours). So prefer fixing forward over `azd down` when you can, and if you do tear down, expect to wait before redeploying. The governance check and spoke vending don't need to be redone.
