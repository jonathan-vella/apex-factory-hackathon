# Partner Modernization Factory site review

**Site:** <https://factory.apexops.pro/> (65 pages) · **Source:** `jonathan-vella/apex-factory-hackathon`, branch `main` · **Reviewed:** 29 October 2026 · **Brief:** `factory-site-review-prompt.md` (v2.1)

Companion files: `factory-site-review-findings.md` (all findings with evidence), `factory-site-copilot-spec.md` (backlog-style spec for GitHub Copilot) and `factory-site-copilot-issues.md` (one issue per theme).

## 1. Verdict

**Not ready to share yet, but close.** The site is deep, specific and well wired: none of its 450 internal links or anchors is broken, all 85 outside links load, and points and time boxes agree across the rubric, `challenges.json`, the challenge pages and the coach sheets. What holds it back is a short list of serious problems with clear fixes:

1. Two documented recovery paths make a **team lead's run delete the whole team's environment** (P0).
2. The pages **disagree about who helps before day one**: several send people to a coach who isn't on duty, and the event owner never appears.
3. **Prerequisites that block T-14** (dedicated tenant and subscriptions, GitHub plan, Copilot policies, Owner at Tenant Root timing, cost) aren't on Requirements.
4. **C2's evidence names a policy assignment that doesn't exist**, and one component shows C2 as a 35-point team challenge.
5. The **Coach section can't run both days on its own**, and the page-to-page links walk attendees into coach answer keys.

**280 findings:** 2 P0, 24 P1, 86 P2 and 168 P3 (227 defects, 53 suggestions). Most P3s are one-line fixes.

### Ratings by dimension

Rule: 🔴 a P0 or five or more P1s · 🟠 any P1 or ten or more P2s · 🟢 neither.

| Dimension | Rating | P0 | P1 | P2 | P3 | Why |
|---|---|---:|---:|---:|---:|---|
| Completeness | 🔴 Red | 0 | 9 | 22 | 25 | Prerequisites that block T-14 are missing from Requirements; the Coach section still depends on files that are only on GitHub; Tear down has no safety checklist. |
| Accuracy | 🔴 Red | 2 | 11 | 30 | 34 | Two command paths delete a whole team's environment; a scored policy name doesn't exist; one component shows wrong points; vending recovery advice is wrong. |
| Navigation | 🟠 Amber | 0 | 1 | 6 | 19 | No broken links, but the pager walks attendees into coach answer keys and past the end of the journey; several links run one way. |
| Cohesion | 🟠 Amber | 0 | 1 | 13 | 27 | The pages disagree about who helps before day one, and the same facts (agenda, durations, member index, prompts) live in several copies. |
| Order | 🟢 Green | 0 | 0 | 6 | 11 | Three different "start here" orders; How it works sits between Step 4 and Tear down; prompt numbers don't follow the challenges. |
| Clarity | 🟢 Green | 0 | 0 | 5 | 28 | Writing is clear and specific; the issues are naming (tech lead vs team lead, requirement vs task) and missing shells or day/time lines. |
| Audience | 🟠 Amber | 0 | 2 | 3 | 4 | Coach pages are public by design, but the pager and search route attendees into them; one coach page shows the wrong audience banner. |
| Hygiene | 🟢 Green | 0 | 0 | 1 | 20 | Alt text and diagrams are in place; small items such as absolute links, one shared meta description and hand-copied figure markup. |

### What already works

- **Link integrity.** 450 internal links and their anchors, across all 65 pages including the 16 generated coach pages: none broken. Redirects for the retired module URLs work (spot-checked on the live site).
- **Outside links.** All 85 load (opened 29 October 2026); five now land on a different page (LEAD-05).
- **Scoring data.** 45 team + 125 member = 170 base points with a shared 30-point bonus cap, and the same per-challenge minutes, in the rubric, `challenges.json`, the challenge pages and the coach sheets. Only `JourneyMap.astro` disagrees (START-01).
- **Technical accuracy where it matters most.** The learning path matches Learn and Partner Center (all 12 exams, retirement dates, specialization tables). Arc and MI link facts and the ALZ-lite resources and policies match Learn, the Bicep and `Prepare-MiLinkSource.ps1`.
- **Outside claims.** 150 checked against Microsoft Learn, GitHub Docs and Partner Center; 103 confirmed, and every one that wasn't is a finding.
- **Safety rails.** Identifiers stay out of the repo and the Actions logs, lab provisioning is IaC only, and the pipeline separates the lead and member profiles.
- **Reader comforts.** Search works, the 404 page helps, the Starlight pages show a last-updated date and an edit link, and every diagram has alt text.

### Top 12 issues

| # | Issue | Sev | Findings | Fix |
|---:|---|---|---|---|
| 1 | Following "start over" or the Arc troubleshooting steps in the **team lead's** repo deletes every teammate's datacenter, then the hub, policies and management groups. In the lead repo an empty `members` input means the whole roster, and the team teardown job ignores the filter. | P0 | DEP-01, CRF-01, DEP-02, CRF-09 | Decided: make the workflow fail closed in the lead repo (named members, a confirm input for team teardown) and show team leads their own command lines. |
| 2 | Vending recovery is wrong: "re-run vending for that member index only". The stage stops at the first unready member, so earlier members are never restarted, exempted or probed and later ones aren't vended. | P1 | DEP-03, CRF-07, START-07 | Re-run vending for all members (it's safe to repeat); filter only for members phase 3 names. |
| 3 | Pre-event problems are routed to a coach ("If a check fails, tell your coach."), but no coach is on duty before day one. The event owner, who books the Privileged Role Administrator and owns escalation, appears on no page. | P1 | START-02, DEP-04, CRF-08, START-05 | Member → team lead → event owner, everywhere before day one; add the event owner to Roles. |
| 4 | Requirements omits what blocks T-14: a dedicated non-production tenant and empty subscriptions (the kit turns off paid Defender plans subscription-wide), the GitHub plan for environments, Copilot policies (MCP servers are off by default) and Owner at Tenant Root by T-14. | P1 | START-03, START-04, DEP-05, DEP-09 | Add one row per requirement, with who to ask and by when. |
| 5 | C2, its coach sheet and the rubric name `alzl-deny-public-acr`; the Bicep assigns `alzl-deny-pna-acr`, so the denial members capture never matches the evidence coaches check. | P1 | CHA-01, CRF-02 | Rename in the three files. |
| 6 | C2's exemptions table (and C4's, and the Policy clean badge) assumes `rg-datacenter` breaks a policy; the repo's own validation says it breaks none, so the table is normally empty. | P1 | CHA-02 | Decided: accept "none needed" as evidence, with one deferred-work entry. |
| 7 | The kit-at-a-glance journey shows C2 as Team, 120 minutes, 35 points (totals 825 minutes and 190 points) because `JourneyMap.astro` hard-codes data. | P1 | START-01 | Render it from `challenges.json` and add it to the content check. |
| 8 | The pager at the foot of the last Prompts page leads to `/coach/`, the coach answer keys; search lists the coach Lifelines page first for "lifeline". | P1 | LEAD-01, LEAD-09 | Move the Coach group last, set `next: false` on About, keep coach pages out of search. |
| 9 | The Coach section can't run both days on its own: the Day 1 curveball, the APEX demo script, the scoring rules and badges are only on GitHub, and Lifelines is missing from the sidebar and the C6 sheet. | P1 | CRF-03, CRF-04, CRF-05, CRF-06 | Render those files as coach pages; add Lifelines to the sidebar and C6. |
| 10 | C5's recovery for a lost terminal runs `./scripts/preflight.ps1` with no arguments, which fails in a new terminal; C5 never mentions that SQL MI deploys with Hybrid Benefit. | P1 | CHA-04, CHA-03 | Pass `-TenantId -SubscriptionId -Suffix`; add a licence check before deploying. |
| 11 | Prompt 07 saves C3's triage evidence to a relative path that lands in the kit clone on `vm-dev01-work`, a branch assessors don't read. | P1 | GDE-01 | Give the full path in the member's repo on `main`. |
| 12 | Tear down has no "before you delete" checklist (unpushed `vm-dev01-work` commits are lost with `vm-dev01`) and says about 20 minutes per member, while deleting each SQL Managed Instance and its virtual cluster can take up to about 90 minutes. | P1 | DEP-06, DEP-15, DEP-13, DEP-14 | Add the checklist, the real duration, who the admin is and the right CLI input. |

**Verify before the event:** Microsoft Learn (25 September 2026) says the GitHub Copilot upgrade dashboard isn't available in VS Code, yet C3, prompts 01 and 02 and the playbook depend on its tabs (GDE-02, CHA-16). Re-test on the current extension and pin the version you validate.

### Quick wins (each under an hour)

- Rename `alzl-deny-public-acr` to `alzl-deny-pna-acr` in `c02-secure-ai-ready-foundation.mdx`, `coach/c02-secure-ai-ready-foundation.md` and `facilitator/scoring-rubric.md` (CHA-01, CRF-02).
- Correct C2 in `JourneyMap.astro` (START-01).
- Reword the C2 coach sheet's bonus line so the coach index stops showing "None listed" (CRF-10).
- Move the Coach group to the end of the sidebar and set `next: false` on About (LEAD-01).
- Add Lifelines to the Coach sidebar (CRF-17).
- Replace pre-event "tell your coach" / "ask your coach" on Requirements, Troubleshooting, the ALZ-lite and GitHub Copilot upgrade guides, and in `Initialize-Settings.ps1`'s prompt (START-02, DEP-04, CRF-08, GDE-09, GDE-10, DEP-33).
- Add `-f members=<your index>` to every command a team lead might copy for `member` or `teardown` (DEP-02, CRF-09).
- Fix the playbook's two `#set-up-vm-dev01` links to `#33-set-up-vm-dev01` (GDE-41, CHB-11).
- Give prompt 07 the full evidence path (GDE-01).
- Link Tear down from C10 and Event overview, and Cost from Requirements (START-08, START-09, CRF-30).
- Update the five redirected Learn links (LEAD-05, CHA-07, CHB-24, CHB-42, CHA-31).

## 2. Themes: the root causes

Each theme is one GitHub issue in `factory-site-copilot-issues.md` and one block of requirements in the spec.

### T01 Lead-repo safety: teardown, members filter, vending reruns

- **What's wrong:** In the team lead's repo, an empty `members` input means "every member on the roster". Several pages show only the member form of `member` and `teardown`, and the `teardown-team` job runs after any lead teardown, even a filtered one. Vending's stop-at-first-failure behaviour is described as if it were per member.
- **Why it matters:** A team lead who follows the page can wipe the team's datacenters and the foundation days before the event, or leave teammates unvended on the morning of day one.
- **Fix:** Guard the workflow (no team teardown when `members` is set), show the lead's command lines next to the member's, and describe vending reruns as all-member.
- **Findings:** P0: CRF-01, DEP-01 · P1: CRF-07, CRF-09, DEP-02, DEP-03 · P2: CRF-13, CRF-27, DEP-07, START-07 · P3: DEP-20

### T02 Support model and roles before and during the event

- **What's wrong:** AGENTS.md is clear: before day one the team lead is the first contact and there's no coach on duty. Requirements, Troubleshooting, two guides, a script prompt and leftover run-summary text still send people to a coach, and the event owner (who confirms rosters and books the Privileged Role Administrator) isn't on any page. "Tech lead" differs from "team lead" by one word and isn't defined.
- **Why it matters:** People wait for help that won't come, and nobody owns the T-7 Graph grant booking.
- **Fix:** One escalation path (member → team lead → event owner) on every pre-event page; add the event owner and the tech lead to Roles and the glossary; remove readiness-approval leftovers.
- **Findings:** P1: CRF-08, DEP-04, START-02, START-05 · P2: CRF-14, DEP-16, DEP-19, GDE-09, GDE-10, START-15 · P3: CHA-33, DEP-29, START-35, START-38

### T03 Prerequisites, tenant commitments and cost up front

- **What's wrong:** Requirements covers accounts and tools, but not the commitments a partner has to secure weeks ahead: a dedicated non-production tenant with empty subscriptions (the kit moves them under a Deny-policy management group and turns off paid Defender plans), the GitHub plan that environments and secrets need on private repos, Copilot org policies (MCP servers, Copilot CLI, models), Owner at Tenant Root by T-14, Hybrid Benefit eligibility, Docker licensing and the cost.
- **Why it matters:** These are the slow approvals. Discovering them at T-14 or T-7 pushes the event.
- **Fix:** Turn each into a Requirements row with who grants it and by when; date the cost figures and link them.
- **Findings:** P1: DEP-05, START-03, START-04 · P2: CRF-11, CRF-24, CRF-25, CRF-26, DEP-09, DEP-10, START-09, START-10, START-11, START-12, START-13, START-14 · P3: CRF-40, DEP-31, DEP-34, DEP-35, START-17, START-37

### T04 Single source of truth for facts and data

- **What's wrong:** Facts are copied instead of referenced: `JourneyMap.astro` hard-codes challenge data, About keeps its own copy of the agenda (minus the breaks), durations differ between pages and script output, the member index range is 1–5 on some pages and 1–20 on others, prompts copy the playbook's tables, and the templates exist twice.
- **Why it matters:** Copies drift, and they already have.
- **Fix:** Render from `challenges.json` and `facilitator/agenda.md`, keep one timing table, link instead of copying, and extend the content-invariants check to cover components.
- **Findings:** P1: START-01 · P2: CHA-05, CHA-14, CHB-06, GDE-03, GDE-04, GDE-13 · P3: CHA-23, CHA-37, CHB-18, CHB-21, CHB-25, CHB-40, CHB-43, DEP-22, DEP-30, DEP-33, DEP-43, DEP-44, GDE-27, START-20, START-23, START-26, START-36

### T05 Navigation and information architecture

- **What's wrong:** No link is broken, but the structure works against the journey: three different "start here" orders, How it works between Step 4 and Tear down, the Coach group between Prompts and Reference (so the pager leads into answer keys), prompts numbered out of challenge order, landing pages all called "Overview", one-way links between challenges and the guides and prompts that serve them, and Tear down, Cost and Troubleshooting each linked from one or two places.
- **Why it matters:** Readers who follow "Next" get lost or spoiled; readers who need help can't find it from where they are.
- **Fix:** Adopt the proposed sidebar (section 3), override `next`/`prev` at section boundaries, and make every guide–challenge and prompt–challenge link two-way.
- **Findings:** P1: LEAD-01 · P2: CRF-30, DEP-08, DEP-17, GDE-06, GDE-07, GDE-11, LEAD-02, START-06, START-16 · P3: CHA-22, CHA-24, CHA-32, CHA-35, CHA-36, CHA-39, CHB-11, CHB-20, CHB-23, CHB-24, CHB-42, CHB-45, DEP-36, DEP-39, GDE-25, GDE-26, GDE-31, GDE-32, GDE-33, GDE-41, GDE-42, GDE-43, GDE-44, LEAD-03, LEAD-09, START-19, START-30, START-33

### T06 Coach section: run both days from the site

- **What's wrong:** Coach pages are generated from `coach/` and `facilitator/agenda.md`, but the scoring rules, badges, curveballs, APEX demo script and most of the facilitator guide stay on GitHub. Lifelines is reachable only from the coach index and C7. The loader drops C2's bonus and the readiness page's audience note.
- **Why it matters:** A coach running the day from the site misses the Day 1 curveball and can't award badges or apply the bonus cap.
- **Fix:** Render the missing facilitator files as coach pages, reorder the Coach sidebar around the day, and fix the two loader bugs.
- **Findings:** P1: CRF-03, CRF-04, CRF-05, CRF-06 · P2: CRF-10, CRF-12, CRF-15, CRF-16, CRF-17, CRF-18, CRF-19, CRF-20, CRF-22, CRF-31, GDE-14 · P3: CHA-34, CHA-47, CHB-35, CHB-39, CRF-32, CRF-33, CRF-34, CRF-35, CRF-36, CRF-37, CRF-38, CRF-44, CRF-45, CRF-46, CRF-47, CRF-48, LEAD-04, LEAD-07, START-18, START-29

### T07 Challenge evidence, scoring and recovery paths

- **What's wrong:** Individually small, together significant: a policy name that doesn't exist, an exemptions table that's normally empty, evidence paths that land on the wrong branch, recovery steps that fail in a new terminal, a C8 verdict rule that contradicts the script, templates missing the columns the rubric scores, and missing day/time lines on C4 to C10.
- **Why it matters:** Members lose points for doing the right thing, and coaches can't sign off consistently.
- **Fix:** Fix each page against its rubric row and script, and give every challenge the same header: day, start time, time box, scope, points.
- **Findings:** P1: CHA-01, CHA-02, CHA-03, CHA-04, CRF-02, GDE-01 · P2: CHA-06, CHA-08, CHA-09, CHA-10, CHA-11, CHA-12, CHA-13, CHA-15, CHA-17, CHA-18, CHA-19, CHA-20, CHB-01, CHB-02, CHB-03, CHB-04, CHB-07, CHB-08, CRF-23, CRF-28, DEP-11, DEP-12, DEP-18, GDE-05, GDE-12 · P3: CHA-26, CHA-27, CHA-28, CHA-29, CHA-30, CHA-40, CHA-43, CHA-45, CHA-46, CHA-48, CHA-49, CHB-12, CHB-15, CHB-16, CHB-17, CHB-19, CHB-26, CHB-27, CHB-29, CHB-32, CHB-34, CHB-36, CHB-37, CHB-38, CHB-41, CHB-44, DEP-21, DEP-23, DEP-24, DEP-27, DEP-28, DEP-38, DEP-42, GDE-21, GDE-22, GDE-40, START-28

### T08 Tear down and clean-up

- **What's wrong:** Tear down is the thinnest page: no Who/When, no checklist, no verification, a "tick box" for a CLI input, a default that contradicts `cleanup.md`, and a duration that ignores SQL MI deletion. Getting Started never mentions T+2.
- **Why it matters:** Irreversible deletes with unpushed work, or resources left running and billing.
- **Fix:** Rebuild the page around a pre-delete checklist, real durations, named people and a final check, and link it from C10 and Event overview.
- **Findings:** P1: DEP-06 · P2: CRF-21, DEP-13, DEP-14, DEP-15, START-08 · P3: CRF-43, DEP-40, DEP-41

### T09 Product freshness and outside links

- **What's wrong:** Microsoft Learn has moved on in places: the upgrade dashboard isn't in VS Code, the agent starts with `@upgrade`, Upgrade Assistant is deprecated, App Insights "Transaction search" is now Search, the OpenTelemetry distro guidance changed, and five links redirect. Time-sensitive pages carry no "validated on" date.
- **Why it matters:** Instructions that worked in the dry run fail on event day.
- **Fix:** Re-test the Copilot upgrade path, update the references, and add a validated-on date to every time-sensitive page.
- **Findings:** P2: CHA-07, CHA-16, CHB-05, GDE-02, GDE-08, GDE-15, GDE-16 · P3: CHA-31, CHA-38, CHA-42, CHB-13, CHB-14, CHB-22, CHB-31, CRF-39, DEP-25, DEP-26, GDE-17, GDE-18, GDE-19, GDE-20, GDE-23, GDE-24, GDE-30, GDE-38, LEAD-05, START-34

### T10 Terminology, style and glossary

- **What's wrong:** The writing is clear; the problems are naming. Challenge items are "requirements" on the pages and "tasks" in the progress bar, playbook and coach sheets. GHCP and GitHub Copilot alternate in titles. The glossary misses about 40 acronyms and product names the site uses. Vale doesn't run on the coach and facilitator sources.
- **Why it matters:** Small frictions that add up for first-time attendees.
- **Fix:** One term per concept, a fuller glossary, and Vale on every rendered source.
- **Findings:** P2: CRF-29 · P3: CHA-21, CHA-25, CHA-41, CHA-44, CHB-09, CHB-10, CHB-28, CHB-30, CHB-33, CRF-41, CRF-42, DEP-32, DEP-37, GDE-28, GDE-29, GDE-34, GDE-35, GDE-36, GDE-37, GDE-39, LEAD-06, LEAD-08, START-21, START-22, START-24, START-25, START-27, START-31, START-32, START-39, START-40, START-41

## 3. Proposed information architecture

No URL has to change. Everything below is sidebar order and labels in `site/astro.config.mjs`, `sidebar.order` and `next`/`prev` in page frontmatter, plus one content move (the day agendas from About into Event overview). The site hasn't been shared, so if you do rename a page, add a redirect and update every internal link.

| Group (position now → proposed) | Current order | Proposed order |
|---|---|---|
| Getting started (1 → 1) | Overview · The customer story · The kit at a glance · Event overview · Requirements · Roles | Overview · Event overview (now holding the day agendas) · Roles · Requirements · The kit at a glance · The customer story |
| Deploy, relabelled "Before the event" (2 → 2) | Overview · Step 1 (T-14) · Step 2 (T-7) · Step 3 (T-3) · Step 4 (T-1) · How it works · Tear down | Deploy overview · How it works · Step 1 (T-14) · Step 2 (T-7) · Step 3 (T-3) · Step 4 (T-1) |
| Challenges (3 → 3) | Overview · C1 to C10 | Challenges overview · C1 to C10 |
| After the event (new → 4) | — | Tear down (T+2); the URL stays `/deploy/tear-down/` |
| Guides (4 → 5) | Overview · Azure Arc and the MI link · ALZ-lite · GitHub Copilot upgrade · APEX · Partner learning path | Guides overview · ALZ-lite · GitHub Copilot upgrade · APEX · Azure Arc and the MI link · Partner learning path |
| Prompts (5 → 6) | Overview · VS Code: 00 · 01 · 02 · 03 · 04 · 05 · 06 · 07 · Copilot app (best effort) | Prompts overview · VS Code: Prerequisites · Assess and plan (C3) · Triage findings (C3) · Run a task (C6) · Troubleshoot (C6) · CVE scan (C6) · App Service check (C6) · Acceptance pack (C8) · Copilot app (best effort) |
| Reference (7 → 7) | Overview · Availability zones · Azure Hybrid Benefit · Cost · Glossary · Naming and IP plan · Troubleshooting | Reference overview · Troubleshooting · Glossary · Cost · Naming and IP plan · Azure Hybrid Benefit · Availability zones |
| About (8 → 8) | Overview | About, with `next: false` |
| Coach (6 → 9, last) | Overview · Automation map · Deploy with scripts (manual path) · Two-day agenda · Readiness gate · C1 to C10 (Lifelines not listed) | Coach overview · Two-day agenda · Readiness check · C1 to C10 · Lifelines · Scoreboard and badges · Curveballs · APEX demo script (the last three moved from `facilitator/`) · Automation map · Repair: deploy with scripts |

| Change | Why | Findings |
|---|---|---|
| Getting started: logistics before context; align the home call to action and every "Next" line to the same order | Three pages give three different reading orders; the time-critical items (who does what, what to request by T-14) come last | START-16, START-06, START-30 |
| Move the Day 1 and Day 2 agendas from About into Event overview (or render them from `facilitator/agenda.md`) | The agenda is on About, as a second copy that already lost the breaks | START-18, START-20 |
| How it works before Step 1; Tear down in its own "After the event" group | Step 4's pager leads to How it works instead of the challenges; Tear down is a T+2 task | DEP-36, LEAD-02, START-08 |
| Guides in order of first use | The ALZ-lite guide serves T-7 and C2 but is listed after the Arc guide (C3, C7) | GDE-32 |
| Prompts in order of use, with the challenge in the label and no repeated "VS Code:" prefix (change `sidebar.order` only) | Prompt 07 serves C3 but is listed after C8's acceptance pack | GDE-33, GDE-39 |
| Coach group last; `next: false` on About; distinct labels for each landing page | The pager walks attendees from the last Prompts page into the coach answer keys; every landing page is called "Overview" | LEAD-01, LEAD-03 |
| Coach pages in the order of the day, with Lifelines and the facilitator material that is now GitHub-only | Coaches need the agenda and readiness check first and can't reach Lifelines, scoring rules or curveballs from the sidebar | CRF-17, CRF-18, CRF-03, CRF-04, CRF-05 |
| Explicit pager links at the boundaries: Step 4 → Challenges overview, C10 → Tear down, Tear down → none | The journey should end at T+2, not in Guides | LEAD-02, CHA-24 |
| Label every coach page title "(coach)" (decided; search stays as it is) | Searching "lifeline" lists the coach answer key first | LEAD-09 |

The legacy redirects for `/modules/*` and `/challenges/c00-ready-to-hack/` still work. As the site was never shared, you can keep them (harmless) or drop them to simplify `astro.config.mjs`.

## 4. Traceability matrix

Built from the link graph of the source. → means the page links to it; ← means it links to the page. Every coach sheet links to its challenge; challenges don't link to coach sheets, by design.

| Step or challenge | Guides | Prompts | Reference | Templates | Scripts and stages | Gaps |
|---|---|---|---|---|---|---|
| Step 1 Repo and preflight (T-14) | ← APEX, GitHub Copilot upgrade | — | → Azure Hybrid Benefit, Troubleshooting | `templates/README.md` | `Import-Kit`, `Initialize-Settings`, `Initialize-PlatformPipeline`, `Test-PipelineSetup`; `whatif` stage | How it works not linked from 1.5 (DEP-36); index assigned after members need it (DEP-08) |
| Step 2 Foundation and Graph grant (T-7) | ↔ ALZ-lite | — | → Troubleshooting | — | `foundation` stage; `Grant-SqlMiDirectoryRead` | Who books the role holder (GDE-09); no ready-to-run block for them (DEP-18) |
| Step 3 Datacenter and workstation (T-3) | → GitHub Copilot upgrade; ← Arc and MI link | ← 00 Prerequisites | → Azure Hybrid Benefit | — | `member` stage; `Test-Datacenter`; `Get-PipelineEvidence` | No link to Troubleshooting or Cost (CRF-30) |
| Step 4 Vending (T-1) | ← ALZ-lite | — | — | — | `vending` stage; `Deploy-Vending`; `New-DatacenterExemptions`; `Test-Connectivity` | No link to Troubleshooting (DEP-39); pager leads to How it works (LEAD-02) |
| C1 Define the opportunity | ← learning path | — | — | `opportunity-canvas.md` | — | — |
| C2 Secure, AI-ready foundation | ← ALZ-lite, Arc and MI link, learning path | — | — | — | `Test-Connectivity`; APEX `validate:iac-security-baseline` | Doesn't link the ALZ-lite guide or Naming and IP plan (GDE-07, CHA-32); policy name (CHA-01) |
| C3 Assess the source | ↔ GitHub Copilot upgrade; ← Arc and MI link | → 01, 07 (neither links back) | — | — | — | Doesn't link the Arc guide (GDE-07); prompt 07 evidence path (GDE-01) |
| C4 Choose target states | ← learning path | — | — | `adr.md`, `deferred-work-register.md` | — | Exemptions table usually empty (CHA-02) |
| C5 Deploy the CoE archetype | ↔ APEX | — | → Naming and IP plan | — | `azd provision`; archetype `preflight.ps1` | No Azure Hybrid Benefit link (CHA-03); recovery fails in a new terminal (CHA-04) |
| C6 Modernize with GHCP | ↔ GitHub Copilot upgrade | → overview, 02, 03, 04, 05 (none link back) | — | — | — | Coach sheet has no lifelines (CRF-06); per-task evidence unnamed (CHB-01) |
| C7 Migrate and go live | ↔ Arc and MI link | — | — | `cutover-rollback-runbook.md`, `deferred-work-register.md` | MI link via Arc portal | No rollback after cutover (CHB-03); Day 2 Graph-grant check (CHB-02) |
| C8 Validate the pattern | → GitHub Copilot upgrade | ↔ 06 | — | `acceptance-handover.md` | `Test-Acceptance.ps1` | ACCEPT rule contradicts the script (CHB-04) |
| C9 Optimize the DB | → GitHub Copilot upgrade | — (no C9 prompt) | — | — | `db/perf-kit` | No prompt page for C9 (GDE-40, CHB-35) |
| C10 Package and hand over | ← ALZ-lite, learning path | — | — | `acceptance-handover.md`, `ai-readiness-gap-register.md`, `factory-kit-checklist.md` | — | No link to Tear down (START-08); register lacks Owner and Next step (CHB-07) |
| Tear down (T+2) | — | — | — | — | `teardown` stage; `Remove-PlatformPipeline` | Only the Deploy overview links here (DEP-40) |

## 5. Fact table

Canonical values, where they come from, and where the site drifts. ✅ consistent · ⚠️ drifts in places · ❌ wrong somewhere a reader will act on it.

| Fact | Canonical value | Source of truth | Status |
|---|---|---|---|
| Team size | 3 to 5 people, team lead included | AGENTS.md | ✅ |
| Subscriptions | 1 shared services + 1 workload per member (5 people → 6) | AGENTS.md | ✅ |
| Member index | Assigned by the team lead; scripts accept 1 to 20; teams use 1 to 5, lead is 1 | scripts, Step 1 | ⚠️ 1–5 and 1–20 both shown (DEP-43, START-27); prompt says "from your coach" (DEP-33); needed before it's assigned (DEP-08) |
| Pre-event gates | T-14 repo and preflight · T-7 foundation and Graph grant · T-3 datacenter, Arc, vm-dev01 · T-1 vending · T+2 teardown | AGENTS.md, facilitator/agenda.md | ⚠️ Getting Started overview misorders them (START-06); Owner at Tenant Root needed at T-14 (DEP-09) |
| Help before day one | Team lead, then event owner; no coach on duty | AGENTS.md, Roles, Deploy overview | ❌ Requirements, Troubleshooting, two guides and a script prompt say coach (T02) |
| Readiness | Checked automatically by the vending stage; no sign-off gate | AGENTS.md | ⚠️ workflow header, run summary and C5 coach sheet mention approval (DEP-16, CRF-14) |
| Day 1 opening | 08:30 kickoff (30 min) · C1 09:00 · C2 09:45 | facilitator/agenda.md | ✅ pages agree; the About copy drops the breaks (START-20) |
| Points | 45 team + 125 member = 170; bonus capped at 30; 200 maximum | facilitator/scoring-rubric.md | ❌ JourneyMap totals 190 (START-01) |
| C2 | Member · 45 min · 15 points · up to 5 bonus | rubric, challenges.json | ❌ JourneyMap: Team, 120 min, 35 points (START-01); coach index: bonus "None listed" (CRF-10) |
| Time boxes C1 to C10 | 45 · 45 · 60 · 45 · 90 · 180 · 120 · 45 · 60 · 60 = 750 min | rubric, challenges.json | ⚠️ JourneyMap totals 825 (START-01); C4 to C10 give no day or start time (CHA-40, CHA-45, CHB-15) |
| ACR deny assignment | `alzl-deny-pna-acr` | infra/foundation/alz-lite/modules/policies.bicep | ❌ C2, coach C2 and rubric say `alzl-deny-public-acr` (CHA-01) |
| Region | swedencentral; fallback germanywestcentral | settings, facilitator/guide.md | ⚠️ Step 1 hard-codes it (DEP-30); who chooses is unclear (START-38) |
| Bastion | Standard | AGENTS.md, Bicep | ✅ |
| SQL Managed Instance | General Purpose, 4 vCores, Hybrid Benefit (`BasePrice`) | archetype `sql-mi.bicep` | ⚠️ C5 never mentions the licence choice (CHA-03) |
| Teardown time | About 20 min per member without an archetype; with SQL MI, up to about 2 hours (the script waits up to 3) | Learn, teardown script | ❌ Tear down says about 20 minutes per member (DEP-15) |
| Stage durations | One table, linked from every step | — | ⚠️ member stage 35–45, 35–60 or about 45 minutes depending on the page (DEP-22) |
| Cost | $3.38/h per member running; $1.30/h per team from T-7 | facilitator/cost-estimate.md (reconciled 8 Oct 2026) | ⚠️ no date on the page (CRF-24); no-Hybrid-Benefit delta overstated (CRF-11) |
| VS Code | Latest stable; 1.139.0 validated | versions.md | ⚠️ Requirements says 1.100 or newer; custom agents need 1.106 (START-10) |
| Challenge items | "Requirements" | challenge pages | ⚠️ "tasks" in the progress bar, playbook and coach sheets (CHA-21, CHB-10) |
| Team lead | Team lead (the workflow and scripts say "platform lead") | AGENTS.md | ⚠️ Roles doesn't mention the alias (START-41); "tech lead" undefined (START-15) |

## 6. Persona journeys

Each walk follows the site from the home page, in the order the persona would read it. Numbers in brackets are findings.

### Attendee (member)

1. **Home and Getting started.** "Start with the requirements" skips Event overview and Roles, while the Getting Started overview says to start with the customer story and the sidebar starts there too (START-16).
1. **Requirements.** "If a check fails, tell your coach", but no coach is on duty before day one (START-02). Nothing about the Copilot policies the preflight checks, the dedicated tenant, Docker licensing or cost (START-03, START-04, START-12, START-09).
1. **Step 1.** Your member index is needed in 1.4, but the team lead assigns it in 1.5, and the script asks for it "from your coach" (DEP-08, DEP-33).
1. **Step 3.** Solid for members. After a failed run the lab password file isn't created (DEP-12); the after-Arc recovery doesn't say you'll need vending again (DEP-07).
1. **Step 4.** Start your VMs, but nothing says to wait until `vm-app01` shows Connected in Azure Arc before telling your team lead (DEP-11). The pager then sends you to How it works, not C1 (LEAD-02).
1. **C1 to C5.** No "Next" line after C3, C4 and C5 (CHA-39). C2's evidence names a policy you'll never see (CHA-01). Prompt 07 saves your C3 triage to a branch assessors don't read (GDE-01). C5's recovery fails in a fresh terminal (CHA-04).
1. **C6 to C10.** The upgrade dashboard the prompts rely on may not open in VS Code (GDE-02). C7 has no path back after cutover (CHB-03). C8 says ACCEPT is fine with explained UNKNOWNs; the script disagrees (CHB-04). C10's gap register has no Owner or Next step column, which the rubric scores (CHB-07).
1. **After C10.** The pager goes to the Guides overview and nothing points to Tear down at T+2 (LEAD-02, START-08). Following "Next" from the last Prompts page opens the coach answer keys (LEAD-01).

### Team lead

1. **Roles.** Explains your job, but not the event owner you escalate to (START-05), or that the workflow and scripts call you the platform lead (START-41).
1. **Step 1.** Pipeline setup needs Owner at Tenant Root at T-14, not T-7 (DEP-09), and the setup script then suggests running the foundation straight away (DEP-17).
1. **Step 2.** Who books the Privileged Role Administrator is unclear (GDE-09), and the role holder gets no ready-to-run block (DEP-18).
1. **Step 3 in your own repo.** The documented command without `-f members` runs for the whole roster (DEP-02, CRF-09). "Start over" deletes every teammate's datacenter and the foundation (DEP-01, CRF-01).
1. **Step 4.** If one member isn't ready, vending stops for everyone after them; the page says to re-run for that member only (DEP-03, CRF-07).
1. **Day 2, 08:30.** The Graph-grant check the agenda gives you isn't on the C7 page (CHB-02).
1. **T+2.** No checklist before the irreversible teardown, no named admin, a "tick box" for a CLI input, and a default that contradicts the facilitator clean-up guide (DEP-06, DEP-14, DEP-13).

### Coach

1. **Coach sidebar.** Starts with the automation map and the manual repair path; the agenda and readiness check come later, and Lifelines isn't listed (CRF-18, CRF-17).
1. **Day 1.** The agenda has no 10:15 curveball row and the C2 sheet doesn't mention it (CRF-03). The APEX demo script isn't on the site (CRF-04). The guide promises a live ALZ portal demo the agenda doesn't schedule (CRF-22, GDE-14).
1. **Scoring.** Rules, badges, the bonus cap and the scoreboard formula are on GitHub only (CRF-05); C2's bonus shows "None listed" (CRF-10); C2 sign-off checks for a policy name members can't produce (CRF-02).
1. **Day 2.** The C6 sheet has no lifelines guidance (CRF-06). Coach sheets have no previous/next links (CRF-48).
1. **Readiness page.** Shows team leads the generic "don't read ahead" banner (CRF-12) and uses four names for one concept (CRF-19).

## 7. Decisions

All fifteen were decided on 29 October 2026, together with a code-change rule: docs, sidebar configuration, frontmatter and text-only string edits, with the teardown guard as the only logic change. The spec applies them.

| # | Decision | Findings | Recommendation | Decided (29 Oct 2026) |
|---:|---|---|---|---|
| 1 | Change `platform.yml` so the team teardown never runs when `members` is set (a pipeline change: lab test and your approval) | DEP-01, CRF-01 | Yes. Also consider an explicit confirm input for team teardown. | Fail closed: in the lead repo, `member`, `teardown` and `all` need named members; team teardown needs `members=all` and a confirm input |
| 2 | C2 and C4 exemptions: plant a deliberate violation in `rg-datacenter`, or accept "no exemptions needed" as evidence | CHA-02 | Accept "none needed, and here's why" as evidence; it teaches the same lesson with less to break. | As recommended |
| 3 | GitHub plan for the partner org (environments and their secrets on private repos) | DEP-05 | Confirm on a free-plan org, then state the plan on Requirements. | GitHub Free works: owner-tested on private repos |
| 4 | Is the Copilot CLI policy required? (`versions.md` says "Not used"; the preflight asks for it) | START-03 | Drop it from the preflight if nothing uses it. | Optional, only for the playbook's CLI path |
| 5 | Upgrade dashboard in VS Code: re-test, then choose the fallback wording | GDE-02, CHA-16, CHB-14 | Re-test now and pin the validated extension version in `versions.md`. | Pin the validated versions and add one fallback line; owner re-tests before the dry run |
| 6 | Live ALZ portal demo: schedule it or remove the promise | CRF-22, GDE-14 | Remove it from the guide unless a coach owns the slot. | Fold into the 08:30 kickoff (slides or a short recording) |
| 7 | APEX Deploy path 07b: supported at events or not | GDE-13 | Say "not supported at events" in `archetype/README.md`. | As recommended |
| 8 | Tear down default for `include-management` | DEP-13 | Follow `cleanup.md`: delete unless the tenant is reused. | As recommended |
| 9 | Who books the Privileged Role Administrator | GDE-09 | The event owner (as `facilitator/guide.md` says); the team lead confirms the slot. | The team lead books; the event owner handles escalations |
| 10 | Docker Desktop licensing: note only, or a supported alternative | START-12 | Add the licence note; name an alternative only if you've tested it. | As recommended |
| 11 | Rollback after cutover | CHB-03 | Say plainly that the Arc experience has no reverse migration, then either document the SQL Server 2022 failback route you have tested or mark rollback after cutover out of scope. | Out of scope at the event; say so |
| 12 | Curveball scoring: the team lead runs it, each member is scored | C1–C5 reviewer note | Confirm and say so on C2 and the coach sheet. | As recommended |
| 13 | OpenTelemetry: keep the Azure Monitor distro or move to the Microsoft OpenTelemetry distro Learn now recommends | CHB-13 | Keep for this event; note the change for the next version. | As recommended |
| 14 | Templates: keep two identical copies (attendee and team) or one | C6–C10 reviewer note | One copy, imported to both places by `Import-Kit.ps1`. | Keep both copies and fix both (no code change) |
| 15 | Coach pages in site search | LEAD-09 | Keep them out of search; coaches use the sidebar. | Label coach page titles "(coach)" |

## 8. Method and coverage

- **Scope.** All 65 pages: 49 Markdown and MDX pages, and 16 coach pages generated from `coach/` and `facilitator/`. Plus the site configuration and components, and the scripts, workflows, Bicep, templates and facilitator files they reference: 282 files from `main`, read on 29 October 2026.
- **Reviewers.** Six parallel reviews, one per slice (Getting started; Deploy; C1 to C5; C6 to C10; Guides and Prompts; Coach and Reference), all working to the same brief, persona walks and severity scale. The lead reviewer added live-site checks, merged the results and removed duplicates by theme.
- **Automated checks.** Every internal link and anchor resolved from source, including the coach-page link rewriting; all 85 outside links opened in a browser; terminology counted across the site; points and time boxes compared across the rubric, `challenges.json`, components and pages.
- **Live site.** Navigation, the prev/next pager, search, the 404 page, redirects and the coach index, in a desktop browser.
- **Source of truth.** The live site and current repo come first, and code beats prose. AGENTS.md and the facilitator files settle order, timings, roles and points. Microsoft Learn settles outside facts. `docs/archive` is history.
- **Not covered.** Running the pipeline or deploying anything; mobile layout and dark mode; screen-reader testing; the artwork inside the diagram SVGs; the app's runtime behaviour (upload limit, notification polling), which was checked only against the playbook.

## 9. Files in this review

- `factory-site-review-prompt.md`: the reusable review brief (v2).
- `factory-site-review-report.md`: this report.
- `factory-site-review-findings.md`: all 280 findings with evidence and fixes, plus the 150 outside-claim checks.
- `factory-site-copilot-spec.md`: backlog-style spec (B24) for GitHub Copilot.
- `factory-site-copilot-issues.md`: ten issue bodies, one per theme, each assignable to Copilot.

Suggested home in the repo: `docs/review/2026-10-29/`. The spec and issues refer to that path.
