# C2 answer key: Secure, AI-ready foundation (coach)

> [!WARNING]
> Coach material. This page has the answers to C2. Each member runs C2 in their own dev container and vended `rg-spoke`. The team lead ran the landing zone and vending from GitHub Actions before the event; the kit scripts below are only for a coach's repair.

C2 is a **Member** challenge (45 minutes, 15 member points). Instead of a passive walk-through, each member tries to make an AI coding agent bypass two layers of guardrails:

1. **Layer 1 (APEX in-repo guardrails):** `.github/instructions/references/iac-security-baseline.md` and `npm run validate:iac-security-baseline -- --public-web-app infra/bicep/university/modules/web-app.bicep`.
2. **Layer 2 (Azure Landing Zone `Deny` policies in Azure):** `alzl-deny-public-acr` and `alzl-deny-nic-pip` assigned at `mg-factory-corp` and inherited by each member's vended `rg-spoke`.

Each member also checks their `rg-datacenter` policy exemptions and runs `Test-Connectivity.ps1`, then commits `factory/evidence/c02/guardrail-test.md`.

## Expected evidence

In each member's own repo (`factory/evidence/c02/guardrail-test.md`), with no tenant, subscription or object IDs:

- **Layer 1 (5 member pts):**
  - What the AI coding agent did when prompted to enable `adminUserEnabled: true` and `publicNetworkAccess: 'Enabled'` in `infra/bicep/university/modules/registry.bicep` (whether it refused citing `.github/instructions/references/iac-security-baseline.md`, or edited the file).
  - Output of `npm run validate:iac-security-baseline -- --public-web-app infra/bicep/university/modules/web-app.bicep` showing the scanner catching `publicNetworkAccess: 'Enabled'` in `registry.bicep`.
  - Confirmation that `infra/bicep/university/modules/registry.bicep` was restored cleanly (`git status --short -- infra/bicep/university` is empty) so C5 can deploy without errors.
- **Layer 2 (5 member pts):**
  - `RequestDisallowedByPolicy` output from attempting to create a public Container Registry (`az acr create -g rg-spoke -n "acrguard$($s.suffix)" --sku Basic --public-network-enabled true -l $s.location`), naming `alzl-deny-public-acr`.
  - `RequestDisallowedByPolicy` output from attempting to attach `pip-guardrail-test` to a NIC in `vnet-spoke/snet-app`, naming `alzl-deny-nic-pip`, with `pip-guardrail-test` deleted afterward.
- **Exemptions, connectivity and takeaway (5 member pts):**
  - Output of `az policy exemption list --resource-group rg-datacenter -o table` showing the time-limited exemptions created by Step 4 (`vending`), with owner, reason and expiry.
  - Output of `./scripts/Test-Connectivity.ps1` showing `PASS` on every applicable check.
  - Two sentences explaining why repository instructions alone are not enough for autonomous AI agents and why Azure Landing Zone `Deny` policies are mandatory.

## Model answer

### Layer 1: Repository security baseline

From the repo root (`/workspaces/<your-repo>`) in the dev container:

```bash
# After prompting the agent or editing infra/bicep/university/modules/registry.bicep
# to set publicNetworkAccess: 'Enabled':
npm run validate:iac-security-baseline -- --public-web-app infra/bicep/university/modules/web-app.bicep

# Restore cleanly before C5:
git restore --source=HEAD -- infra/bicep/university/modules/registry.bicep
git status --short -- infra/bicep/university
```

Why `--public-web-app infra/bicep/university/modules/web-app.bicep` is passed: Contoso University's web front end is a documented public HTTPS exception in the archetype brief, while all data backends (ACR, SQL MI, Storage, Service Bus, Key Vault) must keep `publicNetworkAccess: 'Disabled'`.

### Layer 2: Azure Landing Zone `Deny` policies

From `/workspaces/<your-repo>/factory` in PowerShell:

```powershell
./scripts/Initialize-Settings.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'
$s = Get-Content .local/settings.json | ConvertFrom-Json
az account set --subscription $s.subscriptionId

# Denied by alzl-deny-public-acr:
az acr create -g rg-spoke -n "acrguard$($s.suffix)" --sku Basic --public-network-enabled true -l $s.location

# Denied by alzl-deny-nic-pip:
az network public-ip create -g rg-spoke -n pip-guardrail-test --sku Standard -l $s.location
az network nic create -g rg-spoke -n nic-guardrail-test --vnet-name vnet-spoke --subnet snet-app --public-ip-address pip-guardrail-test -l $s.location
az network public-ip delete -g rg-spoke -n pip-guardrail-test
```

Note for coaches: in tenants with MCAPS Modify policies (such as the build tenant), Storage and Key Vault resources have `publicNetworkAccess` silently modified to `Disabled` before `Deny` runs. Container Registry (`alzl-deny-public-acr`) and NIC public IP (`alzl-deny-nic-pip`) reliably trigger `RequestDisallowedByPolicy` in both customer tenants and MCAPS tenants.

### Exemptions and connectivity

```powershell
az policy assignment list --disable-scope-strict-match -o table
az policy exemption list --resource-group rg-datacenter --query "[].{name:displayName, category:exemptionCategory, expires:expiresOn, description:description}" -o table
./scripts/Test-Connectivity.ps1 -SubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex
```

And the team lead confirms the Graph grant from Step 2.2 once for the team:

```powershell
./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -WhatIf
```

### Repair (coaches only)

Use this only when a pre-hackathon stage run can't be repaired in time (rerun the stage first: the stages are idempotent). A coach runs the same scripts by hand, in this order. Students don't run them:

```powershell
./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location
./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId <member-subscription-id> -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <n> -MemberPrincipalId <member-object-id> -BudgetEmail <member-email> -Location $s.location
az vm restart -g rg-datacenter -n vm-dev01 --subscription <member-subscription-id>
az vm restart -g rg-datacenter -n vm-app01 --subscription <member-subscription-id>
./scripts/New-DatacenterExemptions.ps1 -SubscriptionId <member-subscription-id> -Owner '<name>'
./scripts/Test-Connectivity.ps1 -SubscriptionId <member-subscription-id> -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <n>
```

- Run `Deploy-Vending.ps1`, the restarts, the exemptions and the connectivity test once per member, after ALZ-lite and after that member's datacenter and Arc onboarding. Take the other members' values from the roster the team lead keeps privately (captured at Step 1).
- Never rerun Arc, and never redeploy a datacenter after Arc. A datacenter redeployed after vending requires vending again.

## Business outcome check

The outcome is secure by default. Check that the member's two-sentence takeaway in `guardrail-test.md` clearly distinguishes repository guardrails (which catch mistakes in code before deployment, but can be bypassed) from Azure Landing Zone `Deny` policies (which enforce rules at the Azure control plane regardless of how a human or AI agent calls Azure).

## Common mistakes

- Forgetting to run `git restore --source=HEAD -- infra/bicep/university/modules/registry.bicep` after Layer 1. If `publicNetworkAccess: 'Enabled'` is left in `registry.bicep`, C5's `azd provision` will fail on `alzl-deny-public-acr`.
- Running `npm run validate:iac-security-baseline` from `factory/` instead of the repo root (`/workspaces/<your-repo>`), or omitting `-- --public-web-app infra/bicep/university/modules/web-app.bicep`.
- Leaving `pip-guardrail-test` in `rg-spoke` after the NIC creation is denied. Remind members to run `az network public-ip delete -g rg-spoke -n pip-guardrail-test`.
- Not restarting `vm-app01`/`vm-dev01` if a VM was stopped or redeployed after vending, causing `Test-Connectivity.ps1` DNS checks to fail.

## Partial credit

- Layer 1 and Layer 2 evidence complete, but `Test-Connectivity.ps1` or the exemptions table is missing from `guardrail-test.md`: award the Layer 1 and Layer 2 rows (10 pts) and ask the member to add the exemptions and connectivity output before C4.
- Member forgot to restore `registry.bicep`: have them restore it on the spot before signing off Layer 1.

## Bonus

Up to 5 member bonus points (under the shared 30-point team bonus cap) for testing a `DeployIfNotExists` policy from `infra/foundation/validation.md`: creating a temporary private endpoint in `rg-spoke` / `snet-pe` without a DNS zone group, waiting for Azure Policy remediation (~12 minutes) to register its `A` record in the hub's central private DNS zone, recording the result in `guardrail-test.md`, and deleting the test resources afterward.

## Reset

If a member left changes in `infra/bicep/university/`, run `git restore --source=HEAD -- infra/bicep/university`. If `pip-guardrail-test` remains in `rg-spoke`, delete it with `az network public-ip delete -g rg-spoke -n pip-guardrail-test`. If a member's spoke or exemptions need to be recreated, rerun the `vending` stage for that member (`-f members=<n>`).
