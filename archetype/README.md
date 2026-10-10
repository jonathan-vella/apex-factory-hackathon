# The CoE archetype: Contoso University platform

> **Status:** APEX output from a build tenant, deployed with both `azd` and the `deploy.ps1` fallback
> and torn down there. `agent-output/university/` and `infra/bicep/university/` are that output, with
> the two governance files redacted as described below. The APEX Deploy path and the re-emitted
> handoff aren't validated yet ([#52](https://github.com/jonathan-vella/apex-factory-hackathon/issues/52)).
> The deployer doesn't get Monitoring Metrics Publisher on Application Insights yet
> ([#60](https://github.com/jonathan-vella/apex-factory-hackathon/issues/60)).

## What this is

An [APEX](https://github.com/jonathan-vella/apex-accelerator) project that designs and deploys the
private-by-default Azure platform for the modernized Contoso University web app: App Service, a
container registry, a SQL Managed Instance, Blob storage, Service Bus, Key Vault and Application
Insights, in a Corp landing zone spoke that already exists (vended in C2). It does not deploy or
modernize the app itself -- that is the separate app- and database-modernization work (C6 to C9).

APEX release/commit this project is pinned to: `apex-accelerator` has no tagged releases, so this
records the commit SHA the archetype was generated with, `c209d8b`. `BRIEF.md`'s Notes section
names `bc96b7284eb116ab5c2ee71b9ba9510f4c22d99a`, the commit that was current when the brief was
written; the build tenant's repo was synced to `c209d8b` before the APEX steps ran, so `c209d8b` is
the one that counts.

**App Service plan `P0v3` VNet integration:** confirmed supported (regional VNet integration is a
Premium-tier App Service Plan feature, and P0v3 is a Premium v3 SKU); the Bicep wires
`virtualNetworkSubnetResourceId` into `snet-app` accordingly.

## Layout

```text
archetype/
  BRIEF.md                           the brief pasted into APEX step 1
  README.md                          this file
  deploy.ps1                         no-agent fallback deploy
  .github/prompts/
    adapt-archetype.prompt.md        adapt prompt; ends at `azd provision --preview`
  agent-output/university/           APEX's artifacts (about 95 files), copied in with
                                      04-governance-constraints.json and
                                      04-policy-property-map.json redacted
  infra/bicep/university/            APEX's generated Bicep, copied in as-is (main.bicep,
                                      main.bicepparam, azure.yaml, modules/, scripts/)
```

This mirrors APEX's own repo layout (`agent-output/{project}/`, `infra/bicep/{project}/`), so a
member can copy the contents of `archetype/` straight into the matching paths of their own APEX
repo and continue from there.

## Deploy it

### With APEX + azd (primary)

1. Create your repo from the [`apex-accelerator`](https://github.com/jonathan-vella/apex-accelerator)
   template, as described on the site's Prerequisites page. There's no pinned tag or release: the
   kit always imports from `main`.
2. Import this folder into that repo. Members normally don't run this by hand:
   `scripts/Import-Kit.ps1` (see the site's Prerequisites page) imports the kit into `factory/` and
   then runs this script for them. To redo only the archetype import, run this from your repo root
   (inside the dev container):

   ```powershell
   ./factory/archetype/Import-Archetype.ps1
   ```

   This downloads `archetype/` at `-Ref` (default `main`) straight from GitHub (no git clone, no
   auth needed for the public repo), copies `agent-output/university/`, `infra/bicep/university/` and
   `.github/prompts/adapt-archetype.prompt.md` into the matching paths of `-Destination` (default:
   the current repo), and adds the prompt to `EXCLUDE_PATHS` in the destination's
   `weekly-upstream-sync.yml` so the weekly upstream sync doesn't delete it (`.github/prompts/` is
   otherwise synced wholesale from upstream). It refuses to overwrite an existing `university`
   project unless you pass `-Force`, which loses your changes to it. It prints a file count and
   content hash for `infra/bicep/university/` so you can sanity-check the copy -- a mismatch
   against the packaged tree hash below is the already-documented drift, not something the script
   resolves. Without a repo checked out (for example, to import into another folder), download the
   script first:

   ```powershell
   iwr "https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/archetype/Import-Archetype.ps1" -OutFile Import-Archetype.ps1; ./Import-Archetype.ps1 -Destination <path to the repo>
   ```

   Or copy the three paths by hand if you'd rather not run a script from the kit repo.
3. Run the `adapt-archetype` prompt in VS Code's **built-in agent mode** (not `01-Orchestrator`,
   which would route on to APEX Deploy), after signing in to azd with `azd auth login
   --use-device-code` (azd keeps its own sign-in, separate from `az login`). It's self-contained:
   it reads the tenant ID, subscription ID and suffix from `factory/.local/settings.json` and asks
   you to confirm them (it asks for them if the file is missing), checks that a spoke is already
   vended (your platform lead vends it in C2), runs a lightweight governance check
   (live Deny-effect discovery, compared against the packaged policy set by policy definition and
   resource type -- stopping only on a genuinely new deny; never overwriting the tracked
   `04-governance-*` files or running drift routing/Step 4-5 re-emission), creates the `azd`
   environment, sets the three inputs, sets `AZURE_LOCATION` from the hub's region (a core azd
   value azd needs before it will provision at all), runs `./scripts/preflight.ps1` in the same
   shell session to derive the other required values, then stops at `azd provision --preview`.
   The preview only lists resource types azd has display names for -- expect it to omit the SQL
   Managed Instance, the UAMI, role assignments, diagnostic settings and the maintenance schedule
   even though they're all in the template and will be created. It never runs `azd provision`,
   `azd down`, `07b-Bicep Deploy`, or anything else that writes to Azure -- running the deployment
   is the member's own decision. `azd` stores the tenant and subscription IDs it was given in the
   gitignored `.azure/<env>/.env` -- expected, not a leak.
4. Review the preview, then run `azd provision` yourself (from `infra/bicep/university/`, same
   shell session) to deploy. The `preprovision`/`postprovision` hooks run `preflight.ps1` and
   `postdeploy-tests.ps1` automatically. Because `azd` bypasses APEX Deploy (`07b`), which would
   otherwise write the Step 6 artifact, `postprovision` also runs `write-deployment-summary.ps1`:
   it writes `agent-output/university/06-deployment-summary.md` from the live deployment record
   (name, timing, outcome, resource types/names -- no tenant, subscription or full ARM resource
   ID) and the post-deploy test results, then tries to mark Step 6 complete with `apex-recall`. If
   `apex-recall` isn't on your PATH it still writes the file and prints the command to run
   yourself before As-Built.
5. Run **As-Built** (agent `08-As-Built`, workflow step 7) to generate
   `agent-output/university/07-as-built.md`.
6. Verify with APEX's `apex-recall` (or its current equivalent) that workflow state shows steps 1-8
   complete.

### With APEX Deploy (optional advanced path)

A member who prefers APEX to drive the deployment itself, instead of azd, can hand off to
**APEX Deploy** (agent `07b-Bicep Deploy`, workflow step 6) against `infra/bicep/university/`
after the governance refresh, the same way the `adapt-archetype` prompt used to. This still works,
but isn't the path the prompt or this README walks through by default.

**Known tree hash drift (tracked, [#52](https://github.com/jonathan-vella/apex-factory-hackathon/issues/52)):**
the packaged `infra/bicep/university/` tree hash no longer matches the APEX handoff, because two
bugs (cmd.exe escaping in `preflight.ps1`, an ACR NIC match in `postdeploy-tests.ps1`) and the new
`write-deployment-summary.ps1` were hand-patched into this APEX-output tree instead of being
re-emitted by APEX step `06b`. This only matters for **APEX Deploy** above, which checks the tree
hash; `azd provision` does not check it and is unaffected. The drift clears once the fixes are ported
into the upstream APEX project (`apex-factory-coe`) and this folder is re-packaged from the new
handoff (#52).

### Fallback (no agent, no azd)

Run it from the `factory/` folder of your repo (in the dev container), so the script and `.local/settings.json` resolve. In the kit repo itself, run it from the repo root.

```powershell
cd factory
$s = Get-Content .local/settings.json | ConvertFrom-Json
./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix -WhatIf
./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix
```

`deploy.ps1` takes the same three inputs and discovers everything else the same way APEX does: the
hub from the spoke's peering, the region from the hub, the Log Analytics workspace by its ALZ-lite
name, and the SQL MI Entra admin from the signed-in user. It runs a plain `az deployment sub
create` of `infra/bicep/university/main.bicep` (subscription-scope; the template creates its own
`rg-university-<suffix>`).

## Inputs

Only three: **tenant ID**, **subscription ID**, **suffix**. Everything else -- region, spoke,
subnets, Log Analytics workspace, SQL MI Entra admin -- is derived or discovered by both the APEX
path and the fallback script, by the backlog's naming conventions.

## Cost

The archetype adds about **$1.83/hour** while deployed: SQL MI General Purpose Standard-series (Gen5)
4 vCores with AHB about $0.68, Service Bus Premium about $0.93, App Service P0v3 about $0.10, ACR
Premium about $0.07, private endpoints about $0.05. The foundation it runs on (ALZ-lite about $1.30
plus the datacenter about $1.55) is about **$2.85/hour** on its own, so the kit total while both the
foundation and the archetype are deployed is about **$4.63-$4.66/hour**. The SQL MI can't be
stopped while an MI link is active.

## Public-endpoint exceptions

The archetype is private-only apart from two documented public endpoints, both required for the
app to function:

1. **The web app's front end** -- the only public inbound endpoint; it's the point of the exercise.
2. **Application Insights ingestion** -- stays public; there is no private-endpoint-only ingestion
   path for the workspace-based resource this kit uses.

Separately, the container registry allows **trusted Azure services** to bypass its network rules
(while `publicNetworkAccess` stays off and no other public access is granted), so `az acr import`
of the placeholder image works after the deploy. This is a deliberate, documented exception to "private
backends," not a public endpoint -- it does not open the registry to the internet.

## Governance files and APEX's hash chain

`agent-output/university/04-governance-constraints.json` and `04-policy-property-map.json` are
packaged with every build-tenant identifier redacted: the workload subscription's `subscription_id`
field (2 occurrences), the tenant-root management-group ID (335 + 9 occurrences across the two
files), and the **shared services subscription ID** embedded in `/subscriptions/<id>/...` resource
paths for the hub's private DNS zones and `log-management` (22 occurrences, `04-governance-
constraints.json` only) -- and `discovery_status: "PARTIAL"` set, not because the CoE build
tenant's policies don't apply, but because they're specific to that tenant and wouldn't exist in a
member's. `04-policy-property-map.json`'s `constraints_ref.sha256` (an internal cross-reference
between the two packaged files) is recomputed against the redacted `04-governance-constraints
.json`, so that check still passes.

This redaction, verified against this package with the real validators:

- `validate-policy-property-map.mjs`: **passes** (22 policies, `constraints_ref` recomputed).
- `validate-governance-refs.mjs`: **passes**, unaffected.
- `validate-governance-trace.mjs --through L3`: the L0 gate **fails on `discovery_status: PARTIAL`
  by design** -- this is exactly the mechanism that forces `adapt-archetype` to re-run live
  discovery in the member's tenant before Deploy. The L1 matrix (20 rows) still passes: redaction
  doesn't corrupt the policy-compliance content, only the subscription/tenant identifiers.
- `validate-iac-handoff.mjs` (no `--skip-tree-hash`): **one error**,
  `governance_attestation.l1m_ref.sha256` mismatch (it hashes the now-redacted
  `04-policy-property-map.json`). `tree_hash` over `infra/bicep/university/` is untouched by
  redaction and passes.
- `validate-challenger-findings.mjs --verify-cache`: **already fails on the unmodified source**
  (41 errors, intermediate `-pass*`/base sidecar files going stale as later passes revised the
  underlying documents -- normal APEX multi-pass history, not a redaction effect). Redaction adds
  12 more `supporting bytes changed` errors, for intermediate sidecars whose `supporting_inputs`
  hash the two governance files. The sidecars that actually matter -- the final `-decisions.json`
  files -- carry no `cache_inputs`/`supporting_inputs` hash fields at all, so none of them are
  affected either way.

There is no sanctioned way to refresh `l1m_ref` or the sidecar hashes without re-running the owning
APEX step (Step 6 re-emits `05-iac-handoff.json`; a fresh Step 3.5 Challenger pass refreshes a
sidecar), and this kit never hand-edits a hash to force a check to pass. **These files, and APEX's
whole hash chain, are the CoE's own review evidence** -- proof that this archetype's plan and Bicep
passed a real governance review in the build tenant. They are not, and never become, a per-member
deployment gate (a design choice of this kit). A member's `adapt-archetype` run does a lighter check
instead: live Deny-effect discovery in the member's own tenant, written only to a gitignored
scratch folder, diffed against the packaged policy set by policy definition and resource type. It
stops only if the member's tenant has a genuinely new deny on a resource type this archetype
deploys; it never overwrites these tracked files and never re-emits `05-iac-handoff.json`. The real
gate for a member's deployment is that check plus `preflight.ps1` (read-only) and
`azd provision --preview`.

### ID scan

Before every commit touching `archetype/`, grep it for the tenant ID, the workload and shared
services subscription IDs (`.local/settings.json`) and the signed-in deployer's object ID; expect
zero hits. Built-in Azure policy/role definition GUIDs (public, not tenant-specific) are expected
and fine.

### Run APEX in the dev container, not natively on Windows

APEX's `.gitattributes` forces LF for `*.bicep` but not for `*.bicepparam`; with `* text=auto`, a
native Windows git checkout turns `main.bicepparam`'s line endings to CRLF, which changes its hash
and breaks `tree_hash` (declared vs actual mismatch). This kit's own `.gitattributes`
(`* text=auto eol=lf`) keeps the committed `archetype/` bytes LF, but a member who then clones
*their* APEX repo natively on Windows can reintroduce the problem. Run APEX (and `apex-recall`) in
the dev container or GitHub Codespaces, not natively on Windows; if you must clone on Windows for
some other reason, use `git -c core.autocrlf=false -c core.eol=lf clone ...` and verify `tree_hash`
before relying on it. Follow-up filed upstream: `apex-accelerator`'s `.gitattributes` should add
`*.bicepparam text eol=lf`.

## Azure Hybrid Benefit

SQL MI deploys with `licenseType: 'BasePrice'`, which assumes the subscription has Software
Assurance-eligible SQL Server core licenses to cover it (Azure Hybrid Benefit). This is the kit-wide
default (see `docs/backlog/README.md`). To turn AHB off and pay full license-included pricing
instead, change `licenseType` to `'LicenseIncludedPrice'` in `infra/bicep/university/main.bicep`
(or override it as a deployment parameter) before deploying.

## Validation

What was run in the build tenant, quoted from `docs/backlog/B09-archetype.md` (B09) and the B10 pull
request ([#53](https://github.com/jonathan-vella/apex-factory-hackathon/issues/53)). `TODO` marks a
row with no evidence in the repo.

| What | Result | Source |
|---|---|---|
| `adapt-archetype` prompt, then `azd provision`, then As-Built (environment `m18f06`) | Deployment `m18f06-1791436413` reported `Succeeded` (22m59s, started 05:13:45 UTC) on 2026-10-08, with all 17 expected resources. As-Built ran 17:11 to 17:41 UTC | B09, item 18 |
| `deploy.ps1` fallback | Validated end to end. TODO: no timing is recorded | B09, "Done when" |
| Post-deploy checks (public endpoints, policy compliance, private DNS, MI name resolution, image push, pull and restart, telemetry) | Pass, with two non-blocking gaps: the `alzl-diag-appinsights` compliance-reporting gap and a false negative on the SQL MI port-11000 check | B09, "Done when" |
| Web app on the archetype, after the B10 cutover test | 13 of 13 front-end checks passed with the L5 image and again with the known-good image | #53 |
| Teardown | Done on 2026-10-08 and checked with fresh queries; `rg-management` kept | B09, "Done when"; #53 |
| APEX Deploy (`07b`) against the packaged tree | Not validated: the tree hash no longer matches the handoff | [#52](https://github.com/jonathan-vella/apex-factory-hackathon/issues/52) |
| `write-deployment-summary.ps1` recording Step 6 to 7 in `apex-recall` | TODO: `apex-recall` wasn't installed in the test, so only the manual-command fallback ran | B09; [#52](https://github.com/jonathan-vella/apex-factory-hackathon/issues/52) |
