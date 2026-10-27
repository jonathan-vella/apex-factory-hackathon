# Workflow rules

Rules for changing the platform pipeline in this folder (`platform.yml`, `platform-smoke.yml`) and the actions in
`.github/actions/`. Read the root [AGENTS.md](../../AGENTS.md) first, especially the **event order**.

## What the pipeline is

GitHub Actions orchestrates the kit's own scripts with OIDC and a user-assigned managed identity. `platform.yml` is the only
entry point. Its `stage` input follows the event: `whatif` (the lead's ALZ-lite what-if, a member's preflight), `foundation`
(ALZ-lite, T-7), `member` (datacenter, `Test-Datacenter`, Arc, T-3), `vending` (T-1), `all` (whatif, foundation, member, vending, in
that order). The design and backlog are in `docs/backlog/B16` to `B20`; the research is in issue #96.

## Rules

- **Stage order is the event order**: foundation (T-7), then member (T-3), then vending (T-1). Never put vending before member or foundation. Check [facilitator/guide.md](../../facilitator/guide.md) before changing any order.
- **Every job lives in `platform.yml`.** A reusable workflow (`uses:` a workflow) gets empty environment secrets, so it can't log in. Share steps through composite actions, which take secrets as inputs.
- **Identifiers are environment secrets, never variables.** Tenant, client, subscription, roster. Only `LOCATION`, `MG_PREFIX`, `PARENT_MG` and `DENIED_MG_PREFIXES` are variables. Logs are public.
- **Every job starts with `./.github/actions/platform-session`**: it masks every ID, reads the roster, runs the guard and logs in. Do not log in any other way. Call it again before a step that runs longer than the token lives (a long deployment, Arc).
- **The guard fails closed** (`scripts/Assert-PipelineGuard.ps1`): subscription allowlist and deny list, and the management-group prefix. Don't weaken it, and keep `test/Assert-PipelineGuard.Tests.ps1` green.
- **Pass values through `env:`**, never interpolate `${{ }}` into a `run:` script. Use `permissions` with the minimum (`contents: read`, `id-token: write`). No `pull_request_target`.
- **Scripts run from `KIT_DIR`**: `.` in the kit repo, `factory` in an attendee's repo. `Import-Kit.ps1` rewrites the `KIT_DIR: .` line, so keep it exactly that. Keep `Test-PipelineSetup.ps1` and the importer in step when you add a file.
- **Gated stages use the `gh-lab` environment.** The reviewer approves. Never approve a gate for an action the owner hasn't authorized.
- Actions are pinned by major version, like the repo's other workflows. Run `actionlint`.

## Testing a change

`workflow_dispatch` only works for a workflow on the default branch, so test from a branch named `ci-test/<stage>-<n>` (for example `ci-test/member-1`): a push runs that stage. Point the branch at a commit that is already on your feature branch, so that `github.sha` stays reachable (the VMs download their scripts by that SHA). Then:

1. Find the run by workflow name `Platform` (the smoke workflow also exists, on `ci-test/smoke-*`). A trigger can lag by several minutes.
2. Approve the environment gate only for what is authorized. Runs behind another run in the same concurrency group stay pending.
3. Read the log for the failure, fix, push, and run again on a new `ci-test/` branch.
4. **Delete every `ci-test/*` branch when you finish, and delete any run whose log printed an identifier** (`gh run delete`).

## Facts learned the hard way

- Under a parent management group other than Tenant Root, ARM can't authorize a nested deployment at a group the same template creates, so `Deploy-AlzLite.ps1` creates the groups first. A first-time what-if there can't run.
- The repo issues immutable OIDC subject claims (`repo:owner@<id>/repo@<id>:environment:...`). Read the subject from `actions/oidc/customization/sub`.
- A new subscription can lack the `Microsoft.Network/AllowBringYourOwnPublicIpAddress` feature; public IP creation then fails.
- A `pwsh` step returns the exit code of the last native command: end with an explicit `exit`.
- `az policy assignment create --policy` takes the bare definition GUID here.

## Settled design

Two profiles (owner, 2026-10-21). The **member profile** runs in each member's own repo (identity in their own workload subscription, Owner there only; preflight and member stages) and replaces the C0 terminal commands. The **platform lead profile** runs in the lead's repo (identity Owner at Tenant Root, roster of the whole team; foundation and vending, and member for any index). Backlog B21 builds the member profile; B22 re-sequences the event docs. Don't change the C2 points or the rubric without the owner's decision.
