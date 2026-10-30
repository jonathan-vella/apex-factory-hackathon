# Platform pipeline (coach page)

GitHub Actions is the only way students deploy the datacenter, the foundation and vending, and remove them again. The kit's scripts are the engine the stages run, and students still run some of them for challenge tasks. They don't run the deploy scripts by hand: a coach does that only as a repair, using the commands on [deploy with scripts](../coach/deploy-with-scripts.md) and in the [C2 answer key](../coach/c02-secure-ai-ready-foundation.md#repair-coaches-only). Students read the [deploy guide](../site/src/content/docs/deploy/index.mdx). This page is for coaches and the event owner. The team lead is called the platform lead in the workflow and scripts (the `Lead` profile).

## What it is

One workflow, `.github/workflows/platform.yml`, is installed in each attendee's repo by `Import-Kit.ps1`. It runs the kit's own scripts with a managed identity, `id-factory-pipeline`, that GitHub signs in with OIDC (no stored secret). Its stages are `whatif`, `member`, `foundation`, `vending` and `teardown`. The `member` stage has an input, `no-hybrid-benefit`, for a member who holds no eligible Windows Server licenses (`gh workflow run platform.yml -f stage=member -f members=<index> -f no-hybrid-benefit=true`). Every step pipes its output through `scripts/Write-RedactedOutput.ps1`, so the run log shows each GUID as `<id:abcd>` (its first four characters).

| Profile | Whose repo | Identity lives in | Owner granted at | Stages |
|---|---|---|---|---|
| Member | The member's own | The member's workload subscription | That subscription only | `whatif`, `member`, `teardown` |
| Lead | The team lead's | The shared services subscription | Tenant Root (a sandbox management group in a test lab) | all |

The profile is a repository variable, `PIPELINE_PROFILE`, that setup writes. A member pipeline refuses the `foundation` and `vending` stages.

## Accepted risk

The identity can create management groups, assign policy and roles, and is Owner on subscriptions. Anyone who can run a workflow in its environment can use it. We accept that for a short-lived lab in a non-production tenant, and we say so up front.

Controls, in the order they apply:

1. **The credential is bound to one environment in one repo**, with the repo's immutable OIDC subject. Other repos, branches and environments can't sign in as the identity.
2. **The environment accepts only the listed branches** (`main` by default).
3. **A required reviewer approves each gated stage**, where the repo's plan offers it (public repos, and paid plans). On a private repo on a free plan there is no reviewer: write access to the repo is the gate, so the repo must stay private and the writers few. The setup script says which case applies.
4. **A fail-closed guard** (`Assert-PipelineGuard.ps1`) runs before every login. It refuses any subscription that isn't on the allowlist or is on the deny list, and any management-group prefix that isn't the allowed one. An empty allowlist refuses everything.
5. **Identifiers are environment secrets**, masked in logs, and the steps redact every GUID that still reaches the output (`<id:abcd>`). The kit repo is public and so are its Actions logs, so never put a subscription, tenant or object ID in a variable or echo it. Delete any run whose log leaked one.
6. **Two-principal teardown.** The identity removes the resources; an admin then removes the identity and its roles with `Remove-PlatformPipeline.ps1`. The workflow never removes its own roles.

Accepted lab risk: the Arc step passes the pipeline identity's ARM token to `vm-app01` in a protected run command and a temporary file. The token is valid for about an hour, and for a lead it carries Owner at Tenant Root. The owner accepts this because it is a lab and the VM is reachable only through Bastion with MFA. There is no scoped identity for it.

In a same-tenant test lab the management-group prefix is a procedural boundary, not an authorization wall: the identity could, by its roles, reach any subscription it was granted. Don't point a test lab at a tenant that holds a live lab.

Before the event, the tenant owner approves the pipeline for the tenant, names who runs the finalizer, and sets the date.

## Who can run what

| Person | Can do | Needs |
|---|---|---|
| Member | Run `whatif`, `member` and `teardown` in their own repo | Write access to their own repo, Owner on their own workload subscription at setup |
| Team lead | Run every stage in their own repo | Admin of that repo, Owner at Tenant Root at setup (or at the sandbox group and the subscriptions) |
| Event owner | Confirms each team's roster and approves the tenant risk | The roster and the tenant decision |
| Privileged Role Administrator | Runs `Grant-SqlMiDirectoryRead.ps1` once per team | Booked for T-7 |

## What stays manual

No pipeline does these. Put an owner and a date on each.

- **The Graph grant**, after ALZ-lite and before C7. Only a Privileged Role Administrator can run it.
- **Elevated access to Tenant Root** for the team lead (a Global Administrator turns on access management for Azure resources and grants Owner).
- **The portal Arc assessment** and `vm-dev01` setup (both part of the readiness check).
- **Creating the subscriptions** and placing them under the tenant's management group.
- **Removing the identity and its roles** (`Remove-PlatformPipeline.ps1`) and the access listed in [Cleanup](cleanup.md).

## Approved cleanup at T+2

Follow [Cleanup](cleanup.md)'s preservation checklist first. Members run `gh workflow run platform.yml -f stage=teardown` in their own repos. The lead's **full** command is:

```bash
gh workflow run platform.yml -f stage=teardown -f members=all -f confirm-team-teardown=true -f include-management=true
```

Omit `include-management` only for owner-approved tenant reuse; deleting the directory identity removes its Graph grants and a later event needs the grant again. A lead's one-member repair uses `-f members=<index>` without team confirmation. Full cleanup waits for all member scopes to succeed before Team scope. Allow about 20 minutes without an archetype, up to about 2 hours with SQL MI; do not cancel while Azure releases the subnet.

Team teardown is **tested**, not a future promise: B24's [full CI-lab teardown](https://github.com/jonathan-vella/apex-factory-hackathon/actions/runs/40912814521) removed the two-member lab, and the [later push-path test](https://github.com/jonathan-vella/apex-factory-hackathon/actions/runs/41013408710) passed idempotently against that already-removed lab. The latter is not another fresh lifecycle test. Pipeline finalization then verified removal of temporary identities, roles, groups and GitHub configuration.

The named admin finalizes each repo with `Remove-PlatformPipeline.ps1` after the stage: member profile in each member repo, default lead profile in the lead repo. Keep repo-admin and Azure role-removal permissions until its verification succeeds, then remove temporary human access.

## Cost

An idle pipeline costs nothing. Runs use hosted runners: a 45-minute member run and a foundation run (measured at about 11 minutes on the pipeline; plan 15 to 25) are well inside free minutes on a public repo. A private repo on a free plan has 2,000 minutes a month, so a team of 5 running the member stage once each (about 45 minutes each) uses about 225. Each datacenter bills about $1.55 an hour while it runs and the firewall about $1.30 an hour, as in the [cost estimate](cost-estimate.md).

## What was tested, and what wasn't

Tested live in a test tenant:

- Member profile from a fresh private repo on a free plan, on a never-used subscription: setup, preflight with provider and feature registration, datacenter, 46 of 46 checks, Arc, the evidence artifact. The identity held Owner on that one subscription only.
- Lead profile with a sandbox parent management group: `whatif`, `foundation`, the member stage for two members in parallel, and vending for two members in order.
- Lead profile with **Owner at Tenant Root and no parent group**, in the owner's own tenant, with **three members**: `whatif`, `foundation` (about 11 minutes, twice, as measured on the pipeline; plan 15 to 25 for an event, as in the guide), three datacenters at once (37 to 44 minutes), vending (62 minutes: each member vended in turn, then all six VMs restarted at once, then the probes in parallel, against 112 minutes when each member was finished before the next started), and `teardown` of three members in parallel then the team (about 45 minutes), then the finalizer. Each cycle ended with the queries showing nothing left.
- `teardown`: members, then the team including `rg-management`, then the finalizer, in both labs.
- The guard, with 12 scenarios and no Azure calls.

Not tested, and not promised:

- **Vending of the members in parallel.** The vend itself runs one member at a time by design, because each run updates the shared firewall policy. Only the restarts and the probes run in parallel.
- **A member run with a required reviewer in a private repo.** Free plans have none.
- **A real event tenant.** The Tenant Root path ran in the owner's own tenant, where the account holds elevated access. An event tenant (for example CSP with delegated access) can differ, so keep the preflight's management-group check as a gate.
- **More than three members** in one lead run. Three ran in parallel and in order without trouble; the numbering (address ranges, firewall priorities) is built for 20.

## What the tests found

Two problems showed up only at Tenant Root or on a second run, and are fixed. First, ARM can't authorize the ALZ-lite policies deployment for a pipeline identity at a group the same template creates, whatever the parent: the script now creates the three groups first everywhere (a person with elevated access hides it). Second, in one subscription state (every Defender for Cloud plan on) Arc connected `vm-app01` but never installed the Azure extension for SQL Server, so no SQL instance appeared; the Arc script now installs it after 5 minutes. If you see Arc **Connected** but no SQL Server instance after 5 minutes on an older copy of the kit, install the `WindowsAgent.SqlServer` extension from the portal (Azure Arc > Machines > `vm-app01` > Extensions)

## If a run fails

Read the log, fix the cause and run the stage again: the scripts are idempotent. A run that sits queued for a long time usually lost its runner: cancel and re-run it.

**Repair (coaches only).** If a student is stuck after two attempts and the run can't be repaired in time, a coach can run the same script by hand, from the commands on [deploy with scripts](../coach/deploy-with-scripts.md) and in the [C2](../coach/c02-secure-ai-ready-foundation.md#repair-coaches-only) answer key. It is the same code the stage runs. Never rerun Arc, and never redeploy a datacenter after Arc.
