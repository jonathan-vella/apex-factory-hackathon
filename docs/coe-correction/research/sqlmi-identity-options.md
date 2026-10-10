# SQL MI hackathon delivery: what broke, what is risky, and the proportionate way forward

Research date: 9 October 2026.

## Executive conclusion

**Keep Azure SQL Managed Instance and leave APEX behavior unchanged.** Neither changing the database product nor adding an accelerator exception framework is necessary to understand or address this problem.

There are two separate questions:

1. **Can the existing hackathon operate?** The published, previously approved baseline remains operationally usable subject to its documented risks, adoption requirements and known issues. The current investigation did not change its infrastructure code or deploy a new identity configuration. That is not an approval of the newer draft.
2. **Can the current CoE correction pass APEX unchanged?** Not while its current independent review contains an unresolved must-fix. Recording acceptance, changing a decision flag, restoring an old review selection or using a different harness does not legitimately clear that gate.

For the next event, the least disruptive choice is to use the existing pinned and validated kit, retain the documented telemetry self-grant, and leave the source-repackaging work explicitly incomplete. For a durable correction that preserves participant-led provisioning, the strongest practical candidate is **SQL MI's own system-assigned identity plus an event-admin batch directory-permission step**. It removes the portable shared-identity assignment path without introducing policy enforcement across every possible resource type. A facilitator-controlled deployment using the existing shared identity is an alternative when preserving that identity is more important than participant self-service.

These technical alternatives are proposals, not authorized changes. The user's latest instruction to retain the existing architecture remains in force. The honest immediate state is therefore: preserve the baseline and draft, document adopter responsibilities, and do not claim the current #52/#60 draft approved.

## 1. Constraints and scope

Confirmed constraints:

- SQL MI stays.
- APEX behavior, accelerator validators and review evidence must not be modified to make the current result pass.
- The kit author documents adoption requirements. Adopting teams obtain their own tenant authorization, designate cleanup responsibility and verify teardown.
- Generated artifacts must follow their owning APEX stages. Human approval gates and independent review remain required.
- No infrastructure, Graph grants or role assignments are changed by this research.

This report evaluates workshop practicality, not a requirement to make a short-lived lab production-grade. However, a workshop label does not change what an Azure identity can technically access.

The research used pinned repository files, current issue bodies, official Microsoft documentation and read-only evidence from the preserved native VS Code workspace. It did not perform live Azure permission enumeration, negative attachment tests or deployment tests.

## 2. What actually happened

### The approved source was not broken

At CoE commit `9a2019046992696a73e9f6b28cbaeac074d2413a`, the saved state has:

- Step 4 complete at `2026-10-07T13:20:43Z`.
- `plan_status=APPROVED`.
- Step 5 complete.
- Selected Plan review `challenge-findings-plan-pass3.json`, SHA-256 `a4bf264eff8c07072bf8c8fff5fac11d00084830c5a7e2535b308de226a3a2ea`. [R1]

That review reports zero findings and explicitly says:

> "Previously accepted or deferred identity findings were not re-raised. No unresolved comprehensive findings remain." [R2]

This matters: the previous reviewer did acknowledge the historical dispositions. It is inaccurate to say we have no evidence that it considered them. It is equally inaccurate to infer that this sentence implemented a technical attachment restriction.

The earlier pass7 had already identified the same issue, `569fbf8e`, and the owner recorded a rejection/accepted-risk disposition on 7 October. Its threat description closely matches the present finding. [R3, R4]

### The correction changed the review baseline

The owner authorized reopening Step 4 for:

- #52: script fixes, the deployment-summary lifecycle interface and a fresh handoff.
- #60: Monitoring Metrics Publisher for the member/deployer on Application Insights. [R5, R6]

The native Planner then set the plan to DRAFT, revised the plan and contract, regenerated the dependency diagram, and obtained fresh independent reviews. This correctly invalidated the old review against the changed plan bytes.

Pass8 re-raised historical concerns. After scoped clarifications, pass9 retained only the shared-identity must-fix. It explains that Graph application permissions are exercised as the service identity, not bounded by the member's normal directory visibility or delegated token. The current state remains Step 4 in progress, `plan_status=DRAFT`; no generated infrastructure changes or CodeGen completion have been established. [L1, L2]

**Root cause of the delivery blockage:** a fresh independent review applied a different substantive disposition to an unchanged inherited risk while reviewing the new plan. This is a review/approval disagreement, not a new SQL MI outage, a changed Graph grant or a new exposure caused by #60.

### Harness and environment failures were separate

The earlier use of Copilot CLI instead of APEX's native VS Code harness introduced missing-tool and handoff-control problems. Windows line endings and path serialization also caused misleading hash/state errors. Those issues were diagnosed separately; Linux checks passed after the environment was corrected.

They do not explain away pass9. The later native VS Code run had functioning Bicep/Azure tools and a named independent reviewer. Switching back to CLI or removing validation is not a remedy.

## 3. Why APEX cannot simply "accept and continue" today

The canonical review protocol both preserves unchanged user decisions and states that unresolved blockers remain blocking despite previous acceptance, rejection or deferral. It defines `must_fix` around deployment failures or security breaches. [R7]

The runtime completion gate explicitly rejects a review with a nonzero must-fix count or an individual must-fix finding:

> "unresolved must_fix findings; decisions are not closure evidence" [R8]

Gate 3 requires approved Plan reviews, and the Planner approval contract does not provide a general owner-risk-acceptance escape hatch. [R9, R10]

There is semantic tension between the historical clean confirmation, which deliberately did not re-raise accepted identity findings, and the newer upheld must-fix. That is useful diagnostic evidence. It does **not** create a supported exception flag.

Consequently:

- Do not rewrite pass9, its severity, count or hashes.
- Do not select stale pass3 to approve changed plan bytes.
- Do not repeat unchanged reviews until one gives the desired result.
- Do not treat a numbered review filename as proof of review freshness or eligibility.
- Do not change accelerator enforcement: the user rejected that scope.

A genuine review error could be corrected through the independent review process with new, material evidence. The present record already includes historical acceptance and a second independent adjudication. No newly verified control has been supplied to warrant another identical loop.

## 4. What the identity is for

The kit's `Grant-SqlMiDirectoryRead.ps1` grants three Microsoft Graph application permissions to `id-sqlmi-directory` once during team/event preparation:

- `User.Read.All`
- `GroupMember.Read.All`
- `Application.Read.All`

The script describes their use for SQL MI's Entra principal resolution, including creating the application's contained database user during C7. It is an event-preparation administrator action, not an attendee directory-administration exercise. [R11]

The SQL MI module uses both a system-assigned and user-assigned identity and sets the shared UAMI as the primary identity. It already explicitly pins `databaseFormat: 'SQLServer2022'`. The workload remains GP Gen5, four vCores, 64 GB, Entra-only authentication, private networking and Azure Hybrid Benefit. [R12]

Microsoft documents that SQL MI requires an instance identity for Entra authentication, supports either system-assigned or user-assigned identity, and permits granular Graph application permissions instead of the broader Directory Readers role. System-assigned identity still requires directory permissions; switching identity type does not eliminate that requirement. [M1]

The application identity is separate. It authenticates to SQL MI and other services; SQL database roles control its database permissions. The directory identity is used by the SQL service to resolve Entra principals, not as a shared application password.

## 5. The concrete exposure, not just "best practice"

Vending grants:

1. Owner on the participant's workload subscription. [R13]
2. Managed Identity Operator on the shared directory identity in the separate shared-services scope. [R14]

Microsoft explains that a user with permission to assign an identity can associate it with another resource and exercise that identity's permissions from code on the resource. [M2]

The resulting path is:

`member resource-write rights + shared UAMI assignment rights -> another compatible compute resource -> service-identity Graph tokens -> tenant-directory read`

The workload subscription boundary does not restrict the directory scope of those Graph permissions. The impact is unauthorized or unintended directory-information access and reconnaissance using the shared service identity. It is not automatically tenant takeover, directory modification, mailbox access, password disclosure or database access.

The precise permissions and target resources currently accessible to each participant have not been inventoried live. The repository proves the intended grants and supplies a plausible access path, not that it has been exploited.

A dedicated lab tenant, trusted participants and short duration reduce business exposure. They do not enforce "SQL MI only" attachment. Normal member-directory visibility and app-only Graph authorization are not interchangeable. [R3, M2]

## 6. Ownership: kit author versus adopting team

The reusable kit should specify:

- What identity is created, why it needs directory read and who can attach it.
- That directory exposure is tenant-wide, not limited to workload subscriptions.
- The administrator permissions and approval needed before using the kit.
- Whether the event permits the documented residual risk.
- Teardown ordering and evidence requirements.
- The fact that production adoption needs a separate security assessment.

Each adopting team supplies actual tenant approval, participants, dates, cleanup owner and eventual evidence. The kit author must not invent those values.

For a shared identity, cleanup cannot be purely per-member: one member must not delete it while another SQL MI still depends on it. The adopting team needs an accountable coordinator for shared resources. A user acting as a team administrator can fulfill that role, but subscription Owner alone does not establish authority to approve tenant-wide directory permissions. [R11, M1, M2]

The prior rehearsal intentionally retained the shared identity. Future final teardown is an obligation, not evidence that deletion already happened. Deletion also cannot undo directory information already retrieved, and permission/token caches can delay effective revocation. [L2, M2]

## 7. SQL MI-preserving alternatives

| Option | Attendee experience | Technical effect on attachment finding | Main trade-off |
|---|---|---|---|
| Keep current shared UAMI and document risk | Unchanged | Does not remediate it; current APEX draft stays blocked | Lowest operational change, unresolved approval |
| Use approved baseline for an event | Existing workflow and known workarounds | Does not close the new draft's finding | A valid baseline is not approval of new corrections |
| Trusted event operator provisions/attaches shared UAMI; members have no assignment rights on it | Bootstrap moves to event operator | Removes the documented participant-controlled attachment grant if effective rights are verified | Must separate operator from attendee roles and test reruns |
| SQL MI system-assigned identity; event administrator grants Graph permissions per MI | Participant-led resource provisioning can remain | Removes transferable shared-UAMI path | Per-MI admin checkpoint, propagation and recreation handling |
| Dedicated per-member UAMI, still assignable by the member | Mostly unchanged | Does not eliminate use of its directory permissions on other resources | Smaller shared blast radius, same portable authorization issue |
| Temporary/JIT UAMI assignment rights | Small workflow change | Reduces duration; does not prevent misuse while rights exist | Cannot honestly claim an enforced target-type boundary |
| Management-group deny policy | Potentially unchanged | Conditional on coverage and non-bypassability | Alias coverage, other writable scopes and live negative tests |
| Dedicated lab tenant only | Mostly unchanged | Reduces exposed data; does not remove attachment path | Useful adoption constraint, not guaranteed APEX clearance |

No option is implemented or promised to receive a particular reviewer verdict.

### A. Existing shared identity with trusted event provisioning

This is the smallest change to the identity topology:

- Retain the existing UAMI and its prepared Graph permissions.
- Do not grant participants assign rights on that shared identity.
- Use a trusted adopting-team operator to provision the identity-bearing SQL MI, or perform a tightly controlled attachment stage.
- Leave participants free to modernize applications and work in their workload subscriptions.

This does not require a permanent broker service. A manual event-preparation step or a bounded operator script can be sufficient. The operator belongs to the adopting team; it need not be the kit author.

However, it is **not** a one-line role-removal fix. Current preflight derives SQL admin and data-role principals from the signed-in deployer, rejects service-principal deployment, and explicitly requires shared-identity assignment permission. `main.bicep` then uses that same principal for SQL admin and member data roles. A facilitator deploying unchanged code would receive those roles instead of the attendee. [R15, R16]

Therefore this option needs an owning requirements/plan revision to separate:

- Who executes infrastructure provisioning.
- Who is SQL Entra admin and receives attendee data roles.
- Who has permission to associate the shared identity.

It must test redeploy behavior. Do not assume that removing assignment permission after initial creation leaves every subsequent ARM/Bicep update working; service/provider behavior needs exact validation.

Nor does making the facilitator the initial SQL administrator create a permanent security boundary while the participant retains broad workload Owner rights. Control-plane rights to change SQL MI configuration, administrator settings or update policy must be considered separately. This option removes the documented shared-UAMI attachment grant; it must not be advertised as eliminating every way a powerful participant could exercise directory access through SQL MI itself.

### B. SQL MI system-assigned identity with a batch administrator checkpoint

This is the cleaner repeatable choice when preserving attendee self-service is important:

- Keep SQL MI.
- Use its resource-bound system-assigned identity for directory operations.
- An authorized event administrator grants the documented Graph permissions to each approved MI principal.
- Attendees proceed with C7 after permission propagation and a readiness check.
- Deleting/recreating an MI results in a new principal and requires a new grant checkpoint.

The source already enables a system-assigned identity, so the architectural change is not the introduction of an unfamiliar service. It is changing which SQL MI identity performs directory operations and removing the shared-UAMI assignment dependency. [R12, M1]

A system-assigned identity cannot simply be attached to an attendee VM as a reusable UAMI. Its lifecycle follows the MI. This addresses the reviewed portability scenario, while preserving the Graph directory-read purpose. It does not narrow those Graph permissions to lab directory objects or guarantee that every possible SQL-admin capability is harmless. [M1, M2]

The event preparation checkpoint should be batched and idempotent, accept an explicit approved MI inventory, and use principal IDs rather than display-name guesses. It should not sweep every identity in a tenant or grant broad Directory Readers merely for convenience.

Creation/Entra-admin ordering is a real implementation dependency, not merely a theoretical caveat. Microsoft states that SQL MI's directory permissions must be assigned before setting its Entra administrator. A system identity only exists after resource creation, whereas a prepared UAMI can be authorized before creation. Consequently the current single-resource create with Entra admin cannot simply be changed to SMI and presumed equivalent: staged provisioning/admin configuration needs rehearsal and owning approval. Do not remove Entra-only authentication casually to work around sequencing; preserve its intended outcome through a reviewed staged design. [M1, M2, M4]

### C. Why a broad deny-policy project is not the easiest answer

An inherited management-group restriction can resist a workload subscription Owner if the participant has no power to alter the parent policy. But:

- The rule must target the specific shared identity, not all user-assigned identities; App Service legitimately needs its application identity.
- Alias availability varies by resource provider and API version. A universal identity-ID policy expression has not been verified. [M3]
- All participant-writable target scopes matter, not only the lab's management group.
- A deny affects matching requests; it does not automatically remove existing attachments.
- Positive MI tests, negative attachment tests and update-path coverage are required.

That is disproportionate if one resource-bound identity or a facilitator bootstrap can remove the specific path.

### D. Additional SQL-engine boundary to preserve, not a new baseline defect

Official documentation exposes a distinct possible directory-access path: `sp_invoke_external_rest_endpoint` can invoke Microsoft Graph using a managed-identity credential. This means "a SQL MI identity cannot be attached to another VM" is not proof that a SQL administrator can never exercise its directory permissions. The documentation describes authenticated HTTP calls and returned results; it does not establish that the procedure discloses a raw bearer token. [M5]

For SQL MI, this feature requires the SQL Server 2025 or Always-up-to-date update policy and is disabled by default. Enabling it requires server configuration permission; invocation and credentials have their own permissions. Microsoft's SQL Database defaults must not be projected onto SQL MI. [M5]

**The source already uses `SQLServer2022`, so this is not a newly enabled feature in our baseline and no extra "pin 2022" fix is needed.** Preserve and verify that existing pin. Moving to newer update policies is an irreversible configuration change, and a template pin alone is not an immutable restriction against a sufficiently privileged resource owner changing configuration. [R12, M6]

This residual must be scoped accurately during any proposed remediation: SMI fixes portability, not every possible tenant-directory access path. Avoid escalating the current task into a speculative redesign of all SQL-administrator capabilities. First verify the actual engine policy, admin permissions and intended participant trust model.

### Cost and workshop practicality

Neither principal alternative requires replacing SQL MI, adding another MI per participant beyond the existing workload, or running a permanent broker service. The main additional burden is operator time, staged provisioning, permission-propagation waits and repeatable tests. No pricing estimate is asserted here; existing SQL MI/runtime charges remain separate from the identity choice.

## 8. Recommended course

### Immediate recovery: protect progress, do not force the draft

1. Preserve the native DRAFT, plan/contract/diagram changes, pass8/pass9 and decision history. Do not reset it or copy old approval state over it.
2. Keep the published approved baseline separately identifiable by its exact commit and package pin.
3. If an event must run before remediation is authorized, use that existing delivery only within its documented adoption/risk requirements. Do not label it newly remediated or mark #52/#60 closed.
4. Keep #60's documented member self-grant until the permanent role assignment is actually generated and tested.
5. Leave #52's source handoff/hash reconciliation openly incomplete. An operational `azd` path does not validate an APEX source hash by proxy. [R5, R6]
6. Advance independent content work such as B15 when its kit-edit scope is correctly authorized; do not make it wait for this identity disagreement.

### Durable release: change the lab design, not APEX

If the next approved scope is technical remediation:

- **Prefer system-assigned SQL MI identity plus a batched event-admin grant checkpoint** for a scalable, participant-led hackathon.
- **Prefer trusted event-operator provisioning with the existing UAMI** if avoiding per-MI Graph grants is paramount and facilitator provisioning is acceptable.
- Do not introduce a policy framework or broker service before a minimal script/manual checkpoint has been shown insufficient.

Return the chosen change to its requirements/architecture owner, then Governance, Planner, independent Challenger, CodeGen and live validation. The reviewer must assess real new controls, not a requested severity downgrade.

The practical validation spike should test one alternative on one representative MI, not overhaul the whole workshop. Test the participant workflow, one prohibited attachment attempt, and one redeploy before expanding. For SMI, the first go/no-go is the creation -> directory grant -> Entra-admin sequence. For facilitator provisioning, it is correct attendee role assignment plus rerun behavior without attendee UAMI assignment rights. If either requires substantially more infrastructure, stop and compare the other rather than growing an orchestration platform.

If the owner maintains "no architecture or permission change for now," the immediate recovery plan is still valid, but the corrected CoE draft remains blocked. The report does not invent a way to satisfy mutually incompatible requirements.

## 9. Proof required before calling a technical alternative fixed

Minimum acceptance evidence:

1. SQL MI remains the required tier/configuration and retains private-network and Entra-only outcomes.
2. The participant can complete the intended C7 principal-creation/application-login flow.
3. The participant cannot associate the directory-enabled identity with a controlled VM or app using any effective/inherited permission in the intended adoption scope.
4. No new path grants the participant reusable credentials or arbitrary attachment authority through an operator script.
5. Redeploy, rollback and MI recreation are handled honestly; permission readiness is tested rather than assumed.
6. Event-admin responsibilities are documented as adopter obligations, not kit-author values.
7. Shared resources are not deleted while consumers remain; system-identity recreation requires reauthorization.
8. The updated APEX plan has fresh independent evidence, legitimate human approval and a new handoff. Historical reviews remain historical.

No live negative tests were run during this research, so none of these alternatives is an attested current control.

## 10. What to stop doing

- Stop asking the same reviewer to accept the same unchanged finding.
- Stop designing accelerator exceptions after the user rejected accelerator changes.
- Stop moving APEX execution between harnesses to escape missing capabilities or gates.
- Stop conflating directory risk acceptance with a deployment authorization or technical closure.
- Stop treating "all responsibilities belong to attendees" as proof that prerequisites have been met. The responsibilities belong to the adopting team and its authorized tenant administrator.
- Stop requiring a reusable kit author to supply actual adopter dates, identities and future cleanup evidence.
- Stop equating a cached old approval with approval of changed artifacts.

## 11. Sources and evidence

### Pinned repository sources

- **[R1]** CoE baseline state, commit `9a201904...`: [00-session-state.json](https://github.com/jonathan-vella/apex-factory-coe/blob/9a2019046992696a73e9f6b28cbaeac074d2413a/agent-output/university/00-session-state.json). Sections: `steps.4`, `steps.5`, `decisions.plan_status`, `review_selections.4`.
- **[R2]** Same commit: [challenge-findings-plan-pass3.json](https://github.com/jonathan-vella/apex-factory-coe/blob/9a2019046992696a73e9f6b28cbaeac074d2413a/agent-output/university/challenge-findings-plan-pass3.json). `challenge_summary`, zero counts and cache artifact SHA.
- **[R3]** Same commit: [challenge-findings-plan-pass7.json](https://github.com/jonathan-vella/apex-factory-coe/blob/9a2019046992696a73e9f6b28cbaeac074d2413a/agent-output/university/challenge-findings-plan-pass7.json). Finding `569fbf8e`, evidence and impact.
- **[R4]** Same commit: [challenge-findings-plan-decisions.json](https://github.com/jonathan-vella/apex-factory-coe/blob/9a2019046992696a73e9f6b28cbaeac074d2413a/agent-output/university/challenge-findings-plan-decisions.json). Entries `569fbf8e`, `57f85f8d`, `92079f7c`.
- **[R5]** [Hackathon issue #52](https://github.com/jonathan-vella/apex-factory-hackathon/issues/52). Source-script port, live validation, lifecycle and packaging requirements; issue remains open at research time.
- **[R6]** [Hackathon issue #60](https://github.com/jonathan-vella/apex-factory-hackathon/issues/60). Member telemetry role omission and existing self-grant workaround; issue remains open at research time.
- **[R7]** Accelerator commit `ce671634...`: [adversarial-review-protocol.md](https://github.com/jonathan-vella/apex-accelerator/blob/ce671634c23d88e54ca33bf712c1b74fe3fcd6b0/.github/skills/apex-azure-defaults/references/adversarial-review-protocol.md), especially lines 19-21, 139, 276, 374-403 and 502-506.
- **[R8]** Same accelerator commit: [complete_step.py](https://github.com/jonathan-vella/apex-accelerator/blob/ce671634c23d88e54ca33bf712c1b74fe3fcd6b0/tools/apex-recall/src/apex_recall/commands/complete_step.py), function `_challenger_findings_invalid`, must-fix check around lines 133-137 and strict review verification.
- **[R9]** Same accelerator commit: [workflow-graph.json](https://github.com/jonathan-vella/apex-accelerator/blob/ce671634c23d88e54ca33bf712c1b74fe3fcd6b0/.github/skills/apex-workflow-engine/templates/workflow-graph.json), node `gate-3`, precondition `plan-readiness`.
- **[R10]** Same accelerator commit: [iac-planner-approval-gate.md](https://github.com/jonathan-vella/apex-accelerator/blob/ce671634c23d88e54ca33bf712c1b74fe3fcd6b0/.github/skills/apex-iac-common/references/iac-planner-approval-gate.md), mandatory must-fix treatment and supported confirmation-selection semantics.
- **[R11]** Kit commit `7460ed93...`: [Grant-SqlMiDirectoryRead.ps1](https://github.com/jonathan-vella/apex-factory-hackathon/blob/7460ed935c3bc0463af3ab3f82efbcf878fa14f8/scripts/Grant-SqlMiDirectoryRead.ps1), description and Graph app-role grant loop.
- **[R12]** CoE baseline: [sql-mi.bicep](https://github.com/jonathan-vella/apex-factory-coe/blob/9a2019046992696a73e9f6b28cbaeac074d2413a/infra/bicep/university/modules/sql-mi.bicep), identity and SQL MI properties.
- **[R13]** Kit pinned source: [workload-subscription.bicep](https://github.com/jonathan-vella/apex-factory-hackathon/blob/7460ed935c3bc0463af3ab3f82efbcf878fa14f8/infra/foundation/vending/modules/workload-subscription.bicep), `memberOwner` subscription assignment.
- **[R14]** Same kit commit: [sqlmi-identity-operator.bicep](https://github.com/jonathan-vella/apex-factory-hackathon/blob/7460ed935c3bc0463af3ab3f82efbcf878fa14f8/infra/foundation/vending/modules/sqlmi-identity-operator.bicep), identity-scoped member Managed Identity Operator.
- **[R15]** CoE baseline: [preflight.ps1](https://github.com/jonathan-vella/apex-factory-coe/blob/9a2019046992696a73e9f6b28cbaeac074d2413a/infra/bicep/university/scripts/preflight.ps1), lines 242-261 and 333-350: signed-in user restriction, identity assign permission and deployer outputs.
- **[R16]** CoE baseline: [main.bicep](https://github.com/jonathan-vella/apex-factory-coe/blob/9a2019046992696a73e9f6b28cbaeac074d2413a/infra/bicep/university/main.bicep), deployer parameters and module role/SQL administrator wiring.

### Official platform documentation

- **[M1]** [Managed identities in Microsoft Entra for Azure SQL](https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-azure-ad-user-assigned-managed-identity?view=azuresql), sections "Permissions", "Permissions for SMI", and identity creation/update. The SID/TYPE no-validation exception here is expressly Azure SQL Database-only; it is not established as a SQL MI workaround.
- **[M2]** [Managed identity best-practice recommendations](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/managed-identity-best-practice-recommendations), sections on identity choice, assignment permission, lifecycle and permission/token caching. This page also explains why prepared shared identities reduce administrative overhead; UAMI use itself is not inherently wrong.
- **[M3]** [Azure Policy property aliases](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure-alias), provider/API-specific mapping and discovery requirements.
- **[M4]** [Directory Readers role in Microsoft Entra ID for Azure SQL](https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-directory-readers-role?view=azuresql#assign-the-directory-readers-role), SQL MI directory authorization prerequisite before Entra-admin configuration.
- **[M5]** [sys.sp_invoke_external_rest_endpoint](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-invoke-external-rest-endpoint-transact-sql?view=sql-server-ver17), sections "Allowed endpoints", "Credentials" and "Permissions": Graph endpoint, managed identities, SQL MI engine-policy availability and default-disabled behavior.
- **[M6]** [Update policy in Azure SQL Managed Instance](https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/update-policy?view=azuresql), policy configuration, deployment defaults and irreversible upgrade constraints.

### Local, not-yet-committed evidence

- **[L1]** Native preserved workspace `/workspaces/coe-linux-source/agent-output/university/challenge-findings-plan-pass9.json`; read-only verification reported current valid cache, finding `569fbf8e`, one must-fix and zero other findings. This is local draft evidence, not a public GitHub commit.
- **[L2]** Native workspace `00-session-state.json`, README and handoff, plus read-only executor reports on 9 October. State: Step 4 in progress/DRAFT, canonical Bicep routing; historical Step 5 completion does not authorize new CodeGen. The documentation records accepted lab risk without gate clearance.
- **[L3]** Transcripts from the native VS Code sessions on the original device. They are not kept in this repo; the revision, adjudication and documentation steps they show are summarized in `docs/coe-correction/README.md`.

## 12. Confidence and limits

High confidence: original selected review behavior; current APEX must-fix enforcement; intended Owner/MIO grants; SQL MI's current identity shape; distinction between subscription permissions and service-identity directory authorization.

Medium confidence: which alternative is operationally cheapest for this specific cohort. That depends on whether attendees must personally run all provisioning and whether adopting teams can schedule an Entra administrator checkpoint.

Not yet verified: current effective permissions; existing unintended identity attachments; exact ARM redeploy requirements after removing member assignment rights; system-identity creation/admin sequencing under the chosen API; end-to-end C7 results for either proposed design; independent review acceptance of a changed design.

The correct next engineering experiment is a minimal SQL MI-preserving proof, not an accelerator rewrite. If no technical change is authorized, preserve the working baseline, document its residual risk and keep the revised draft honestly blocked.
