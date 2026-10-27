# Platform pipeline (coach page)

The kit can run its deployments from GitHub Actions instead of a terminal. This is optional: the scripts stay the supported path, and a coach should be able to run an event with no pipeline at all. Students read [the student guide](../site/src/content/docs/guides/platform-pipeline.md). This page is for coaches and the event owner.

## What it is

One workflow, `.github/workflows/platform.yml`, is installed in each attendee's repo by `Import-Kit.ps1`. It runs the kit's own scripts with a managed identity, `id-factory-pipeline`, that GitHub signs in with OIDC (no stored secret). Its stages are `whatif`, `member`, `foundation`, `vending` and `teardown`.

| Profile | Whose repo | Identity lives in | Owner granted at | Stages |
|---|---|---|---|---|
| Member | The member's own | The member's workload subscription | That subscription only | `whatif`, `member`, `teardown` |
| Lead | The platform lead's | The shared services subscription | Tenant Root (a sandbox management group in a test lab) | all |

The profile is a repository variable, `PIPELINE_PROFILE`, that setup writes. A member pipeline refuses the `foundation` and `vending` stages.

## Accepted risk

The identity can create management groups, assign policy and roles, and is Owner on subscriptions. Anyone who can run a workflow in its environment can use it. We accept that for a short-lived lab in a non-production tenant, and we say so up front.

Controls, in the order they apply:

1. **The credential is bound to one environment in one repo**, with the repo's immutable OIDC subject. Other repos, branches and environments can't sign in as the identity.
2. **The environment accepts only the listed branches** (`main` by default).
3. **A required reviewer approves each gated stage**, where the repo's plan offers it (public repos, and paid plans). On a private repo on a free plan there is no reviewer: write access to the repo is the gate, so the repo must stay private and the writers few. The setup script says which case applies.
4. **A fail-closed guard** (`Assert-PipelineGuard.ps1`) runs before every login. It refuses any subscription that isn't on the allowlist or is on the deny list, and any management-group prefix that isn't the allowed one. An empty allowlist refuses everything.
5. **Identifiers are environment secrets**, masked in logs. The kit repo is public and so are its Actions logs, so never put a subscription, tenant or object ID in a variable or echo it. Delete any run whose log leaked one.
6. **Two-principal teardown.** The identity removes the resources; an admin then removes the identity and its roles with `Remove-PlatformPipeline.ps1`. The workflow never removes its own roles.

In a same-tenant test lab the management-group prefix is a procedural boundary, not an authorization wall: the identity could, by its roles, reach any subscription it was granted. Don't point a test lab at a tenant that holds a live lab.

Before the event, the tenant owner approves the pipeline for the tenant, names who runs the finalizer, and sets the date.

## Who can run what

| Person | Can do | Needs |
|---|---|---|
| Member | Run `whatif`, `member` and `teardown` in their own repo | Write access to their own repo, Owner on their own workload subscription at setup |
| Platform lead | Run every stage in their own repo | Admin of that repo, Owner at Tenant Root at setup (or at the sandbox group and the subscriptions) |
| Event owner | Captures the roster at T-14 and approves the tenant risk | The roster and the tenant decision |
| Privileged Role Administrator | Runs `Grant-SqlMiDirectoryRead.ps1` once per team | Booked for T-7 |

## What stays manual

No pipeline does these. Put an owner and a date on each.

- **The Graph grant**, after ALZ-lite and before C7. Only a Privileged Role Administrator can run it.
- **Elevated access to Tenant Root** for the platform lead (a Global Administrator turns on access management for Azure resources and grants Owner).
- **The portal Arc assessment** (C0 task 5) and `vm-dev01` setup (C0 task 7).
- **Creating the subscriptions** and placing them under the tenant's management group.
- **Removing the identity and its roles** (`Remove-PlatformPipeline.ps1`) and the access listed in [Cleanup](cleanup.md).

## Cost

An idle pipeline costs nothing. Runs use hosted runners: a 45-minute member run and a 10-minute foundation run are well inside free minutes on a public repo. A private repo on a free plan has 2,000 minutes a month, so a team of 6 running the member stage once each (about 45 minutes each) uses about 270. Each datacenter bills about $1.55 an hour while it runs and the firewall about $1.30 an hour, as in the [cost estimate](cost-estimate.md).

## What was tested, and what wasn't

Tested live in a test tenant:

- Member profile from a fresh private repo on a free plan, on a never-used subscription: setup, preflight with provider and feature registration, datacenter, 46 of 46 checks, Arc, the evidence artifact. The identity held Owner on that one subscription only.
- Lead profile with a sandbox parent management group: `whatif`, `foundation`, the member stage for two members in parallel, and vending for two members in order.
- Lead profile with **Owner at Tenant Root and no parent group**, in the owner's own tenant, with **three members**: `whatif`, `foundation` (about 11 minutes, twice), three datacenters at once (37 to 44 minutes), vending (62 minutes: each member vended in turn, then all six VMs restarted at once, then the probes in parallel, against 112 minutes when each member was finished before the next started), and `teardown` of three members in parallel then the team (about 45 minutes), then the finalizer. Each cycle ended with the queries showing nothing left.
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

Read the log, fix the cause and run the stage again: the scripts are idempotent. A run that sits queued for a long time usually lost its runner: cancel and re-run it. If a student is stuck after two attempts, use the manual scripts, which are the same code.
