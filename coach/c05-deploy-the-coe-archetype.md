# C5 answer key: Deploy the CoE archetype with APEX

> [!WARNING]
> Coach material. This page has the answers to C5. Attendees run APEX's `adapt-archetype` flow themselves, in a dev container or Codespaces.

The one thing to watch for here is members trying this natively on Windows — it produces a subtle, hard-to-diagnose failure (a corrupted tree hash from CRLF line endings), not an obvious error.

## Expected evidence

- An archetype repo created from `apex-accelerator`, with this kit's `archetype/` folder imported per `archetype/README.md`'s import command, at the pinned commit.
- `adapt-archetype`'s outputs: the governance check's result, and the stop at `azd provision --preview`.
- `azd provision`'s deployment record (resource group populated).
- `agent-output/university/07-as-built.md` from the As-Built agent, describing the deployed state.
- `az resource list -g rg-university-<suffix> -o table` showing App Service, ACR, SQL MI, Storage (Blob), Service Bus, Key Vault and Application Insights.

## Model answer

1. Create the archetype repo from the pinned `apex-accelerator` commit; import `archetype/` with the documented script.
2. Open the repo in the dev container or Codespaces (never natively on Windows — `.gitattributes` forces LF for `*.bicep` but not `*.bicepparam`, and a Windows checkout corrupts the tree hash the governance check relies on).
3. Run `adapt-archetype` in agent mode: it asks only for tenant ID, subscription ID and suffix, confirms C2's vended spoke exists (`rg-spoke`, `vnet-spoke`, `snet-app`, `snet-pe`, `snet-sqlmi`), runs its lightweight governance check, and stops at `azd provision --preview`.
4. Review the preview (see the "looks incomplete" hint below — it's expected to be partial), then run `azd provision` for real.
5. Run agent `08-As-Built` to produce the deployed-state document.
6. Confirm no public endpoints beyond the web app's front door and Application Insights ingestion, naming convention followed, and the managed identity's roles present (ACR Pull, Key Vault Secrets User, Storage Blob Data Contributor, Service Bus Data Owner/Sender-Receiver as applicable, Monitoring Metrics Publisher — note #60 if this last one is missing; that's a known archetype gap, not something to fix here).

## Common mistakes

- Running `adapt-archetype` natively on Windows "because the dev container is slow to start" — this is the single most impactful mistake in C5; insist on the dev container or Codespaces every time.
- Treating `azd provision --preview`'s partial output as a failure — it only lists resource types `azd` has display names for; SQL MI, the managed identity, role assignments and the maintenance schedule are created even though the preview doesn't name them.
- Skipping the As-Built step because the deployment "obviously worked" — As-Built is graded evidence, not optional.
- Trying to run `adapt-archetype` before C2's vending finished for that member — it fails fast with a clear "spoke not found" message; this is a sequencing issue, not a bug.

## Partial credit

- Deployment succeeds but As-Built step skipped: partial credit, complete it before moving on — it's needed as an artifact for C10's reusable-asset packaging.
- A policy-compliance finding surfaced by the governance check and resolved, but not noted on the evidence page: partial credit, ask the member to add the one-line note the challenge page asks for.

## Bonus

The no-agent fallback (`archetype/deploy.ps1 -WhatIf`, then for real) run side by side with the APEX path is worth up to 5 bonus points — useful for members curious about what the agent flow automates versus the fallback script.

## Reset

`azd down --purge` then redeploy from the archetype repo if something needs a clean restart; the governance check and spoke vending don't need to be redone.
