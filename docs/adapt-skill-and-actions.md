# Adapt skill on the Copilot harness, and deploying with GitHub Actions

Status 2026-10-20. The skill is live: `Import-Archetype.ps1` copies it and protects it from the weekly upstream sync.

## Why

The migrated APEX (jonathan-vella/apex, merged 2026-10-20) drops VS Code prompt files. Its entry points are manual
skills under `.github/skills/`, and the validator requires every skill name to be `apex-<name>` and to match its
directory. The archetype's `adapt-archetype.prompt.md` therefore became a skill called `apex-adapt-archetype`.

## What changed from the prompt

`archetype/.github/skills/apex-adapt-archetype/SKILL.md` replaces the prompt.

| Change | Reason |
|---|---|
| Frontmatter: `name`, `description`, `argument-hint`, `user-invocable: true`, `disable-model-invocation: true` | Same shape as APEX's other manual skills (`apex-workflow-start`, `apex-debug-log-export`) |
| "VS Code built-in agent mode" becomes "the built-in `agent` owner" | VS Code Local isn't the harness any more. A skill can't select the agent, so it asks the member to confirm the owner and stops if it is an APEX workflow agent |
| Inputs through native `ask_user`, read from `factory/.local/settings.json` with a command first | The file is gitignored, so the `read` tool may skip it. The member answers one "Use these?" question |
| Governance discovery points at the `apex-azure-governance-discovery` skill | The migrated APEX has that skill. The old prompt said "the same calls 04g uses" |
| `user.type` must be `user` | `preflight.ps1` rejects a service principal (see below) |
| Links the accepted lab risks | Members should see them before `azd provision` |
| Flow unchanged | `azd env new`, set the three values, derive the region, `preflight.ps1` and `azd provision --preview` in one shell, then stop |

Tested 2026-10-20 in a repo created from the migrated template, on the Copilot harness in VS Code: the skill appeared
as `/apex-adapt-archetype`, read the settings, found no new Deny policy, passed preflight and stopped at the preview
with 12 resources to create. `validate:skills` passes.

Left as it was: `archetype/infra/bicep/university/scripts/write-deployment-summary.ps1` and
`archetype/agent-output/university/.gitignore` still say "prompt". They sit in byte-checked folders, so they change only
through a re-emit from the CoE repo. The B09, B11 and B14 runbooks are specs and keep their original wording.

## Deployment options

All three start from the same template. Only the first works today.

| Option | What it takes | Status |
|---|---|---|
| **azd from the terminal** (current) | The member runs `azd provision` after the preview. Hooks run `preflight.ps1` and the post-deploy tests | Works. The skill stops at the preview and doesn't deploy |
| **`deploy.ps1`** (az deployment sub create) | Same inputs, no azd | Works as the fallback. Same signed-in-user assumption |
| **GitHub Actions with azd** | `azd pipeline config` creates a workflow and a federated credential for a service principal | **Blocked by the design**, see below |

## Why GitHub Actions isn't a drop-in

Read from the CoE branch `fix/university-52-60-wip`. This is analysis, not a test: I haven't run `azd pipeline config`
or a workflow.

- **`preflight.ps1` rejects anything but a signed-in user** (line 243: "service principals are not supported"). It
  derives `DEPLOYER_OBJECT_ID` and `DEPLOYER_UPN` from `az ad signed-in-user show`. The `preprovision` hook runs it, so
  an OIDC service principal fails before any resource is created.
- **The deployer is also the participant.** `main.bicep` makes that user the SQL Managed Instance's Entra admin and
  gives them the data-plane roles (Storage, Service Bus, Key Vault, ACR and, since #60, Monitoring Metrics
  Publisher). A pipeline would need those assigned to the member, not to the service principal.
- **The pipeline identity needs its own rights:** the deployment and role-assignment rights on the subscription (the
  template assigns roles), Managed Identity Operator on `id-sqlmi-directory`, and subnet join on `snet-sqlmi`. A
  member who is Owner can grant these, but creating the federated credential needs rights to register an app in the
  tenant, and I don't know whether members have them.
- **Runner reach:** the post-deploy tests use ARM, the app's Kudu endpoint, public HTTPS and `az acr import`, which I'd
  expect to work from a hosted runner. They don't reach the private endpoints. Unverified. The repo `azure-gh-runners`
  has a self-hosted runner option if that turns out wrong.

### What it would take

Separate the provisioner from the participant: `preflight.ps1` would accept a pipeline principal when the participant's
object ID and UPN are supplied (for example as repository variables), and it would check the pipeline identity's rights
instead of the signed-in user's. That changes the plan (the deployer contract), so the CoE project reopens at Step 4:
a new Plan review, a new risk authorization and re-emitted code. It would also invalidate the signed records for
pass10. That is why I'd do it after #52 and #60 are finished, not inside them.

## Decisions for you

1. **Sequence:** finish #52 and #60 first and add GitHub Actions as its own APEX change afterwards (my recommendation),
   or fold it into the current correction and redo the Step 4 review and signatures.
2. **azd or something else:** azd is the simplest route to Actions here, because `azd pipeline config` generates the
   workflow and credentials. Plain `az deployment sub create` would need a hand-written workflow.
3. **Who runs the pipeline:** members in their own repos, or the platform lead for everyone. The first needs members
   to be able to register an app.
