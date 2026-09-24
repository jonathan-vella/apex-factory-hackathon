# B11: Write the challenges, module contracts and templates

| Field | Value |
|---|---|
| Milestone | P4 Content |
| Type | Agent |
| Depends on | B07, B08, B09, B10 |
| Unblocks | B12 |
| Effort | 3–4 days |
| Cost | None |
| Teardown | Not applicable: nothing is deployed |
| PRD | §3; §5; §7 Deliverables 4 |

## Outcome

- The site has the attendee content: getting started with the pre-work (C0), the eleven challenges C0–C10, the eight module contracts, guides and reference pages.
- `templates/` has the attendee templates and the team repo template.
- `coach/` has an answer key per challenge.
- The content checks enforce the challenge contract: 11 challenges and 200 base points.

## Before you start

1. B07, B08, B09 and B10 are closed. Read their reports and READMEs: the content is built from what they validated, not from the PRD alone.
2. `npm run check` passes on `main`.

## Requirements

### Challenge contract

1. One page per challenge in `site/src/content/docs/challenges/`, named `cNN-<slug>.md`, with these time boxes and points. Team points count once per team; member points are averaged across the kickoff roster.

   | ID | Title | Scope | Minutes | Points |
   |---|---|---|---|---|
   | C0 | Ready to hack | Member | 150 (pre-work) | 10 member |
   | C1 | Define the opportunity | Team | 45 | 10 team |
   | C2 | Secure, AI-ready foundation | Team | 120 | 35 team |
   | C3 | Assess the source | Member | 60 | 15 member |
   | C4 | Choose target states | Team + member | 45 | 15 team + 10 member |
   | C5 | Deploy the CoE archetype with APEX | Member | 90 | 15 member |
   | C6 | Modernize with GHCP | Member | 180 | 30 member |
   | C7 | Migrate and go live | Member | 120 | 20 member |
   | C8 | Validate the pattern | Member | 45 | 10 member |
   | C9 | Optimize the DB with GHCP | Member | 60 | 10 member |
   | C10 | Package, hand over, review AI readiness | Team | 60 | 20 team |

   Totals: 975 minutes including C0, 200 base points (80 team, 120 member). Bonus points (up to 30) come from badges and bonus tasks and aren't part of the base contract.
2. Fill in `challengeContract` and the three expected totals in `scripts/check-content-invariants.mjs` from this table, so the check fails if a page's time box or points drift.

### Challenge pages

3. Each challenge page has the same sections: **Goal**, **Scope and time box**, **Points**, **Inputs** (what earlier challenges hand over), **Your tasks** (what to achieve, not click-by-click steps: it's a challenge), **Evidence** (what the coach checks for sign-off, matching the rubric), **Hints** (collapsible, progressively more specific), **Lifeline** (which one, if any, and its point cap), **Bonus** (optional tasks and their points) and **Learn more** (public Microsoft Learn and product links only).
4. Content follows the PRD §5 outcomes and what the B06–B10 reports validated. In particular:
   - C0: run the preflight, deploy the datacenter, onboard `vm-app01` to Arc (portal way, with the kit script as fallback), run the first Arc migration assessment, and confirm the legacy app with `scripts/Test-Datacenter.ps1`. Include the AHB note and how to stop the VMs.
   - C2: the coach's live portal ALZ demo (what a full ALZ adds), then the platform lead deploys ALZ-lite into the shared services subscription and runs vending for every member, then exemptions and probes.
   - C5: copy `archetype/` into the member's APEX repo and run the `deploy-archetype` prompt; the fallback script.
   - C6: the playbook and skills from B10, with the model guidance.
   - C7: the MI link flow from B07, including the go/no-go on the read-only replica and the abort path.
   - C8: the acceptance pack: smoke, load and security checks, including an upload and a notification round-trip over private endpoints.
   - C9: the perf kit workload against the MI, Query Store before and after.
5. Pages don't reveal answers that are in `coach/`. Hints stop short of the full solution.

### Modules

6. One contract page per module in `site/src/content/docs/modules/` (`m0-…` to `m7-…`), with: the challenges it covers, prerequisites, the bootstrap for running it standalone (for example ALZ-lite, the archetype deploy, a lifeline branch or the perf kit reset), exit evidence, reset steps, time box and a "last validated" date.

### Getting started, guides and reference

7. Getting Started: how the event runs (two days plus pre-work, T-14 and T-3 gates), teams and roles (platform lead, members, coach), what attendees need (the preflight's manual checks), and the pre-work page that points to C0.
8. Guides: GitHub Copilot app modernization on the dev VM (including the Copilot CLI alternative), APEX for this kit, Azure Arc and MI link, and ALZ-lite.
9. The **ALZ-lite** guide explains the two-subscription model (one shared services subscription per team, one workload subscription per member), the management groups, what the platform lead needs (rights at Tenant Root to create management groups and move subscriptions), the fixed values (region `swedencentral`, fallback `germanywestcentral`; hub `10.100.0.0/16`; Azure Firewall Standard with DNS proxy; Defender for Cloud on Foundational CSPM only, free, with paid plans noted as an AI-readiness gap for C10), and how it compares with the full portal ALZ the coach demos.
10. Reference: naming and IP plan (from the backlog conventions), Azure Hybrid Benefit (every resource, what's on, how to turn it off), availability zones (nothing pinned or turned on; which services are zone-redundant automatically), cost per member and per team (running and stopped), glossary, and troubleshooting from the B04–B10 traps that affect attendees.

### Templates

11. `templates/attendee/`: opportunity canvas (with the six modernization dimensions), ADR template, deferred-work register, cutover and rollback runbook, acceptance and handover, AI-readiness gap register, and factory-kit checklist. Each is a Markdown file with instructions in comments and headings to fill in.
12. `templates/team/`: the starting content of a team repo: a README explaining the folders, one folder per challenge for evidence, and copies of the templates the team uses.

### Coach answer keys

13. `coach/cNN-<slug>.md` for every challenge except C9, which B05 wrote: the expected evidence, a model answer or reference solution, common mistakes, and what earns partial credit.

### Style

14. Every page passes Vale at error level and the content checks. Only public links. No Microsoft-internal content (PRD §9).

## Deliverables

- `site/src/content/docs/challenges/c00-…md` to `c10-…md`, and the section index updated with the challenge table.
- `site/src/content/docs/modules/m0-…md` to `m7-…md`.
- Pages under `getting-started/`, `guides/` and `reference/`.
- `templates/attendee/*.md`, `templates/team/**`.
- `coach/c00-…md` to `coach/c10-…md` (except C9).
- `scripts/check-content-invariants.mjs` updated.

## Verify

```powershell
npm run check
Push-Location site; npm run build; npm run lint:code; npm run lint:prose; Pop-Location
node scripts/check-internal-links.mjs
```

- Everything passes. `npm run check` reports 11 challenges, 975 minutes and 200 base points.

## Done when

- [ ] Eleven challenge pages, eight module contracts, and the getting-started, guides and reference pages exist.
- [ ] Templates and coach answer keys exist.
- [ ] The content checks enforce the contract, and CI passes.

## Commit message

```text
docs: add challenges, module contracts and templates
```

## Stop and ask if

- An earlier report contradicts the PRD on something a challenge depends on.
- A challenge can't be done in its time box according to the spike timings.

## Notes and traps

- **Time boxes overlap on the day:** ALZ deploys during C1 and C3, and the MI provisions during C6. The minutes are per challenge, not the agenda. B12 writes the agenda.
- **Scoring rules** (roster lock, lifeline caps, badges) live in the rubric, which B12 writes. Challenge pages link to it rather than repeating it.
- The content checks scan `coach/` too, for retired names only. Coach files are public, on the honor system.
