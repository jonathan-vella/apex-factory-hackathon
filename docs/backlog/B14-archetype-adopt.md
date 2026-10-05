# B14: Build the archetype adoption agent

| Field | Value |
|---|---|
| Issue | #40 (B14 onwards, the issue number isn't the item number) |
| Milestone | P3 Build |
| Type | Both |
| Depends on | B09 |
| Unblocks | — (not needed for v1; the hackathon keeps B09's `deploy-archetype` prompt) |
| Effort | 4–6 days elapsed, including the owner's test sessions |
| Cost | About $4.63/hour while the foundation and archetype are deployed, the same as B09 |
| Teardown | Delete everything this item created: the archetype resources, the test policy assignment, the foundation if this item deployed it (B09's Teardown row), and the test repo |
| PRD | §2 Archetype; §6 CoE archetype |

## Outcome

- The CoE repo, [`jonathan-vella/apex-factory-coe`](https://github.com/jonathan-vella/apex-factory-coe), has a recipe catalogue. Its first recipe is the `university` project that B09 built.
- An adoption agent pulls a recipe into a user's own APEX repo and asks questions to fit it to the user's Azure environment, policy, workload and SKUs. It routes every change through APEX's own step owners, so that reviews and approvals stay valid.
- If the user changes only environment values, they deploy with APEX Deploy (step 6) without re-running any step.

## Before you start

1. B09 is closed. Read `archetype/README.md` and the B09 PR's gap table.
2. `gh repo view jonathan-vella/apex-factory-coe` works, and you can push to it.

## Requirements

### Recipe catalogue (CoE repo)

1. `recipes/university.json` describes the `university` project in place: its project slug, the `apex-accelerator` commit it was built with, the CoE repo commit, IaC tool, completed steps, prerequisites (vended spoke, ALZ-lite DNS policies), environment inputs (tenant ID, subscription ID, suffix), public exceptions, hourly cost, and a **variability** map. For each knob (region, each service's SKU, the main NFRs), the map gives its default and the earliest APEX step it reopens, or `environment` if it reopens none. It points at `agent-output/university/` and `infra/bicep/university/` and doesn't copy them.
2. `recipes/README.md` documents the recipe fields and how to add a recipe.
3. Add `recipes/` and `agents/` to `EXCLUDE_PATHS` in `.github/workflows/weekly-upstream-sync.yml`, so the upstream mirror doesn't delete them.

### Adoption agent (CoE repo)

4. `agents/archetype-adopt.agent.md`, in VS Code custom agent format, installed by the user at user level (`~/.copilot/agents/`). It must not be installed into a repo's `.github/agents/`: upstream sync deletes files there, and APEX's agent validators may reject it. 🔎 VERIFY the frontmatter fields and user-level location against [Custom agents in VS Code](https://code.visualstudio.com/docs/agent-customization/custom-agents).
5. **Select and import:** list the recipes in the CoE repo and show the chosen recipe's description, cost and prerequisites. Then copy its project files, at the recorded CoE commit, into the user's repo under the **same project slug**. Refuse to overwrite an existing project.
6. **Compatibility:** compare the recipe's `apex-accelerator` commit with the user's repo and report any drift. Then run APEX's validators on the import (challenger findings with `--verify-cache`, SKU manifest, IaC handoff, artifacts) and report what's stale before asking anything.
7. **Discover first, then ask:** prefill tenant, subscription, signed-in user, region and spoke from Azure. Ask only for what discovery can't supply, batching independent questions, with every answer defaulting to the recipe's value. Cover four areas: the Azure environment, Azure Policy, the workload and its NFRs, and SKUs.
8. **Route, don't edit:** environment values go into `04-environment-manifest.json`. For every other change, find the earliest affected step from the recipe's variability map:
   - Policy always reopens step 3.5 (live governance discovery).
   - SKU changes become a new SKU manifest revision.
   - NFR changes become a step-1 revision.

   Reopen that step with `apex-recall`, then hand off to the step's own APEX agent with the change. The agent never edits reviewed artifacts or Bicep itself. It never rewrites review hashes, tree hashes or validation verdicts, and never marks a step complete. 🔎 VERIFY the `apex-recall` commands and the APEX agent names at the recipe's commit.
9. **Provenance:** record the recipe ID and both commits in the project's decision log, through `apex-recall`, never by hand-editing `00-session-state.json`.
10. **Finish:** run `npm run validate:all`, confirm the workflow state shows step 6 next, and offer the handoff to APEX Deploy, then As-Built.
11. CoE `README.md`: an **Adopt an archetype** section that covers installing the agent, running it and the cost of each kind of change.

### Validate for real

12. Make sure a vended spoke exists for member 1. If B09's foundation is still deployed, ask the owner whether to reuse it. Otherwise deploy it the way B09 did (ALZ-lite, datacenter, vending), with approval first.
13. 🧑 HUMAN: the owner creates a private test repo from `apex-accelerator`, installs the agent and runs it for three scenarios. After each one, you check the result with the validators and `apex-recall`:

    | Scenario | Change | Expected |
    |---|---|---|
    | A: environment only | Tenant, subscription, suffix | No step reopened; APEX Deploy applies it; the web app answers on HTTPS |
    | B: extra deny policy | You assign the built-in "Require a tag on resources" deny policy (tag `costCenter`) to the workload subscription first | Step 3.5 reopens and reports the blocker; the fix reaches steps 4–5; what-if is clean |
    | C: SKU change | App Service plan P0v3 → P1v3 | SKU manifest revision 2; steps reopened from the variability map; what-if shows only the SKU change |

14. Record each scenario's elapsed time and which steps reopened.
15. Tear down (Teardown row) and query each item to confirm it's gone.

### Records

16. `versions.md`: the `apex-accelerator` commit the agent was tested with, validated today.

## Deliverables

- CoE repo: `recipes/university.json`, `recipes/README.md`, `agents/archetype-adopt.agent.md`, `README.md`, `.github/workflows/weekly-upstream-sync.yml`. Open a PR there and link it from this item's PR.
- This repo: `versions.md`.

## Verify

- In a fresh repo with only the recipe imported, `npm run validate:all` passes.
- `apex-recall` shows steps 1–5 complete and step 6 next after scenario A, and the expected reopened steps after B and C.
- The PR body has the scenario table with times, reopened steps and results, plus the Azure cost.

## Done when

- [ ] The catalogue and agent are merged in the CoE repo.
- [ ] All three scenarios pass.
- [ ] Everything is torn down.

## Commit message

```text
feat: add the archetype adoption agent and recipe catalogue
```

## Stop and ask if

- Something can't be done through APEX's step owners or `apex-recall`, and you'd have to edit reviewed artifacts or hashes.
- APEX's validators reject the imported recipe before any change, which means B09's output or the pin is stale.
- Scenario B's blocker can't be resolved without breaking a backlog convention.

## Notes and traps

- **Hashes:** challenger reviews are tied to the bytes they reviewed, and APEX Deploy is tied to a hash of the Bicep tree. Any direct edit fails validation or ships unreviewed changes.
- **Project slug:** paths inside reviews and the IaC handoff include the slug, so renaming a project breaks them. Treat a rename as a new step-1 run.
- **APEX drift:** upgrading APEX can invalidate imported reviews, because they hash APEX's checklists and protocol. Keep the recipe and the user's repo on the same `apex-accelerator` commit.
- **Governance:** the recipe's policy constraints describe the CoE's tenant, not the user's. Always rediscover.
- **Secrets:** recipes ship no tenant, subscription or object IDs. Environment manifests hold placeholders only.
