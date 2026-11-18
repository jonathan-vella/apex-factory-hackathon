# C2 answer key: Secure, AI-ready foundation (coach)

> [!WARNING]
> Coach material. This page has the answers to C2. Each member runs C2 on `vm-dev01` in `C:\src\<your-repo>` and their vended `rg-spoke`. The team lead ran the landing zone and vending from GitHub Actions before the event; the kit scripts below are only for a coach's repair.

C2 is a **Member** challenge (45 minutes). Instead of a passive walk-through, each member tries to make an AI coding agent bypass two layers of guardrails:

1. **Layer 1 (APEX in-repo guardrails):** `.github/instructions/references/iac-security-baseline.md` and `npm run validate:iac-security-baseline -- --public-web-app infra/bicep/university/modules/web-app.bicep`.
2. **Layer 2 (Azure Landing Zone `Deny` policies in Azure):** `alzl-deny-pna-acr` and `alzl-deny-nic-pip` assigned at `mg-factory-corp` and inherited by each member's vended `rg-spoke`.

Each member also checks their `rg-datacenter` policy exemptions and runs `Test-Connectivity.ps1` on `vm-dev01`.

## Expected evidence

**Timing cues:** finish Layer 1 by 10:00 and Layer 2 by 10:15, before the curveball. Reserve the final minutes for connectivity checks.

On `vm-dev01` (`C:\src\<your-repo>`):

- **Layer 1:**
  - What the AI coding agent did when prompted to enable `acrAdminUserEnabled: true` and `publicNetworkAccess: 'Enabled'` in `infra/bicep/university/modules/registry.bicep` (whether it refused citing `.github/instructions/references/iac-security-baseline.md`, or edited the file).
  - Output of `npm run validate:iac-security-baseline -- --public-web-app infra/bicep/university/modules/web-app.bicep` showing the scanner catching `publicNetworkAccess: 'Enabled'` in `registry.bicep`.
  - Confirmation that `infra/bicep/university/modules/registry.bicep` was restored cleanly (`git status --short -- infra/bicep/university` is empty) so C5 can deploy without errors.
- **Layer 2:**
  - `RequestDisallowedByPolicy` output from attempting to create a public Container Registry (`az acr create -g rg-spoke -n "acrguard$($s.suffix)" --sku Basic --public-network-enabled true -l $s.location`), naming `alzl-deny-pna-acr`.
  - `RequestDisallowedByPolicy` output from attempting to attach `pip-guardrail-test` to a NIC in `vnet-spoke/snet-app`, naming `alzl-deny-nic-pip`, with `pip-guardrail-test` deleted afterward.
- **Layer 3 & takeaway:**
  - Output of `./scripts/Test-Connectivity.ps1` showing `PASS` on every applicable check.
  - Member can explain in two sentences why repository instructions alone are not enough for autonomous AI agents and why Azure Landing Zone `Deny` policies are mandatory.

## Model answer

### Layer 1: Repository security baseline

From `C:\src\<your-repo>` on `vm-dev01`:

```powershell
# After prompting the agent or editing infra/bicep/university/modules/registry.bicep
# to set publicNetworkAccess: 'Enabled':
npm run validate:iac-security-baseline -- --public-web-app infra/bicep/university/modules/web-app.bicep

# Restore cleanly before C5:
git restore --source=HEAD -- infra/bicep/university/modules/registry.bicep
git status --short -- infra/bicep/university
```

Why `--public-web-app infra/bicep/university/modules/web-app.bicep` is passed: Contoso University's web front end is a documented public HTTPS exception in the archetype brief, while all data backends (ACR, SQL MI, Storage, Service Bus, Key Vault) must keep `publicNetworkAccess: 'Disabled'`.

### Layer 2: Azure Landing Zone `Deny` policies

From `C:\src\<your-repo>\factory` in PowerShell 7 on `vm-dev01`:

```powershell
./scripts/Initialize-Settings.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'
$s = Get-Content .local/settings.json | ConvertFrom-Json
az account set --subscription $s.subscriptionId

# Denied by alzl-deny-pna-acr:
az acr create -g rg-spoke -n "acrguard$($s.suffix)" --sku Basic --public-network-enabled true -l $s.location

# Denied by alzl-deny-nic-pip:
az network public-ip create -g rg-spoke -n pip-guardrail-test --sku Standard -l $s.location
az network nic create -g rg-spoke -n nic-guardrail-test --vnet-name vnet-spoke --subnet snet-app --public-ip-address pip-guardrail-test -l $s.location
az network public-ip delete -g rg-spoke -n pip-guardrail-test
```

Note for coaches: in tenants with MCAPS Modify policies (such as the build tenant), Storage and Key Vault resources have `publicNetworkAccess` silently modified to `Disabled` before `Deny` runs. Container Registry (`alzl-deny-pna-acr`) and NIC public IP (`alzl-deny-nic-pip`) reliably trigger `RequestDisallowedByPolicy` in both customer tenants and MCAPS tenants.

### Exemptions and connectivity

```powershell
az policy assignment list --disable-scope-strict-match -o table
az policy state summarize --resource-group rg-datacenter -o json
az policy exemption list --resource-group rg-datacenter --query "[].{name:displayName, category:exemptionCategory, expires:expiresOn, description:description}" -o table
./scripts/Test-Connectivity.ps1 -SubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex
```

And the team lead confirms the Graph grant from Step 2.2 once for the team:

```powershell
./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -WhatIf
```

### Repair (coaches only)

Use this only when a pre-hackathon stage run can't be repaired in time (rerun the stage first: the stages are idempotent). A coach runs the same scripts by hand, in this order. Students don't run them:

Use the commands on [Repair: deploy with scripts](deploy-with-scripts.md#team-lead), including the configured `MG_PREFIX` and `PARENT_MG`, rather than the scripts' default scope.

- Run `Deploy-Vending.ps1`, the restarts, the exemptions and the connectivity test once per member, after ALZ-lite and after that member's datacenter and Arc onboarding. Take the other members' values from the roster the team lead keeps privately (captured at Step 1).
- Never rerun Arc, and never redeploy a datacenter after Arc. A datacenter redeployed after vending requires vending again.

## Business outcome check

The outcome is secure by default. Check that the member's two-sentence takeaway clearly distinguishes repository guardrails (which catch mistakes in code before deployment, but can be bypassed) from Azure Landing Zone `Deny` policies (which enforce rules at the Azure control plane regardless of how a human or AI agent calls Azure).

## Day 1 curveball

At **10:15**, after Layer 2 and before C3 at 10:30, use **Curveballs** in the Coach sidebar. The team lead assigns `curveball-allowed-locations` at the event's Corp management group under your direction, observes the denial and decision, then removes only that exercise assignment before C5 at 13:45. Never weaken a baseline or tenant policy.

## Common mistakes

- Forgetting to run `git restore --source=HEAD -- infra/bicep/university/modules/registry.bicep` after Layer 1. If `publicNetworkAccess: 'Enabled'` is left in `registry.bicep`, C5's `azd provision` will fail on `alzl-deny-pna-acr`.
- Running `npm run validate:iac-security-baseline` from `factory/` instead of the repo root (`C:\src\<your-repo>`), or omitting `-- --public-web-app infra/bicep/university/modules/web-app.bicep`.
- Leaving `pip-guardrail-test` in `rg-spoke` after the NIC creation is denied. Remind members to run `az network public-ip delete -g rg-spoke -n pip-guardrail-test`.
- Treating an empty exemption list as failure: Bastion's standalone public IP is not in the NIC policy's scope.
- Restarting after a datacenter redeploy without rerunning vending: a restart alone does not restore the hub DNS and routes. Never redeploy an Arc-connected datacenter.

## Reset

If a member left changes in `infra/bicep/university/`, run `git restore --source=HEAD -- infra/bicep/university`. If `pip-guardrail-test` remains in `rg-spoke`, delete it with `az network public-ip delete -g rg-spoke -n pip-guardrail-test`. If a member's spoke or exemptions need to be recreated, rerun the `vending` stage for that member (`-f members=<n>`).
