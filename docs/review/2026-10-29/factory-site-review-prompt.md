# Review prompt: Partner Modernization Factory site

**Version:** v2.1 (refined with owner answers; used for the 29 October 2026 review) · **Owner:** Jonathan Vella · **Date:** 29 October 2026

Reusable: give this prompt to any capable reviewer (human or AI) to rerun the review before each release of the kit.

---

## 1. Role

Act as a four-person review panel and label every finding with the lens that found it:

1. **Information architect.** Structure, navigation, ordering, findability.
2. **Senior technical editor.** Clarity, consistency, Microsoft Writing Style Guide as enforced by the repo's Vale rules.
3. **Azure and GitHub Copilot solution architect.** Technical correctness of every step, command, service, SKU and claim.
4. **First-time attendee.** A partner infra engineer who has never seen the kit and must succeed using only the site.

## 2. What you are reviewing

| Item | Detail |
|---|---|
| Live site | <https://factory.apexops.pro/> (Astro Starlight, 65 pages; not yet shared with anyone) |
| Sidebar groups | Getting Started · Deploy · Challenges · Guides · Prompts · Coach · Reference · About |
| Source repo | `github.com/jonathan-vella/apex-factory-hackathon` |
| Page source | `site/src/content/docs/**` (Markdown and MDX) |
| Generated pages | Coach pages: `site/src/pages/coach/index.astro` and `[slug].astro`, loaded by `site/src/lib/coach-loader.ts` from the repo's `coach/` and `facilitator/` folders. Home page components: `site/src/components/` |
| Challenge metadata | `site/src/data/challenges.json`; task tracker `site/src/scripts/progress.js` |
| Navigation and redirects | `site/astro.config.mjs` (sidebar groups, autogenerate, redirects); custom 404 in `site/src/pages/404.astro` |
| Assets the pages point to | `scripts/`, `infra/`, `templates/`, `facilitator/`, `coach/`, `archetype/`, `db/perf-kit/`, `test/`, `.github/workflows/`, `.github/actions/`, `.github/skills/`, `.github/modernization/`, `versions.md` |
| Rules every fix must follow | `AGENTS.md`, Vale (Microsoft style plus the InfraOps vocabulary), markdownlint, Prettier, `npm run check` (content invariants, node tests, lint), PR rules in `AGENTS.md` |

## 3. Source of truth (owner decision, 29 Oct 2026)

1. **The live site and the current repo are the truth.** Code and configuration (scripts, workflows, Bicep, `challenges.json`, `astro.config.mjs`) beat prose.
2. **Current repo docs** settle order, timings, roles and points: `AGENTS.md` (order of events and rules), `facilitator/guide.md` and `facilitator/agenda.md` (order and timings), the facilitator scoring rubric (points), `coach/` (coach content).
3. **Microsoft Learn** settles external facts. Record the date of every check.
4. **`docs/archive/` (PRD, roadmap, backlog) is history.** Never report the site for drifting from it. Use it only to understand intent.

Flag a page when it contradicts another page, the current repo, or Microsoft Learn.

## 4. Personas to walk end to end

| Persona | Journey |
|---|---|
| **Attendee (member)** | Home → Getting Started → Requirements → Deploy steps 1 to 4 (T-14 to T-1) → C1 to C10 → tear-down |
| **Team lead** | Everything a member does, plus the foundation and Graph grant (T-7), vending (T-1), the team challenges and tear-down (T+2) |
| **Coach** | Run both days from the Coach section alone: agenda, readiness gate, per-challenge sheets, lifelines, sign-off, the manual deploy path |

The event owner is out of scope except where their actions block one of these three.

## 5. What "good" looks like

1. An attendee gets from the home page to a green preflight, through Deploy steps 1 to 4 and through C1 to C10 without outside help, except where the site says to ask the team lead (before day one) or a coach (event days).
2. A team lead knows exactly what they own, when, and what blocks whom.
3. A coach can run both days from the Coach section alone.
4. Every fact (team size, subscriptions, T-minus gates, time boxes, points, roles, regions, SKUs, IP ranges, versions) is stated once, consistently, and matches the repo.

## 6. Review dimensions and checks

### 6.1 Completeness

- Every **challenge page** has: outcome, scope (team or member), owner role, time box, prerequisites and dependencies, inputs, ordered tasks, evidence and success criteria, points and badges, lifeline or recovery path, and links to its coach page, guide, prompts, reference pages and templates.
- Every **Deploy step** has: who, when (T-minus), prerequisites, the exact workflow stage or command, expected output, verification, troubleshooting, and a link to tear-down.
- Every **coach page** has: what to sign off, expected evidence, common failures, lifeline, timing cues.
- No TODO, TBD, placeholder or "coming soon" text, and no empty sections.
- Every file, script, workflow, template, prompt and branch a page names exists in the repo.
- Gaps: anything an attendee needs but cannot find (cost, cleanup, access requests, support path, what to do when falling behind).

### 6.2 Accuracy (three levels, all in scope)

1. **Site consistency.** Every number, name and rule matches across pages (build the fact table in section 8).
2. **Scripts and IaC.** Script names, parameters, workflow stages and inputs, file paths, resource names, SKUs and IP ranges on the pages match the scripts, workflows and Bicep.
3. **Microsoft Learn** (dated). Azure service names and SKUs, Azure Arc and the MI link (requirements, ports, cutover), SQL MI, Bastion, Service Bus, App Service, Container Registry, GitHub Copilot app modernization features, exam codes and status on the learning path, Azure Hybrid Benefit, availability zones and cost statements.

Flag statements that will date quickly and pages without a last-validated date.

### 6.3 Navigation and findability

- Walk each persona's journey. Record every dead end, back-track and "where do I go next?" moment.
- Sidebar: group order, page order inside each group, labels versus page titles versus URLs, groups collapsed by default.
- In-page: previous and next links, next-step calls to action, the challenge task tracker, the "On this page" contents, anchors.
- Search (Ctrl+K): "preflight", "vending", "MI link", "lifeline", "points", "tear down", "cost" land on the right page.
- Zero broken links or anchors, the redirects in `astro.config.mjs`, and the custom 404 page.

### 6.4 Cohesion: how everything ties together

- **Traceability matrix:** for each Deploy step and each challenge C1 to C10, its guide, prompts, coach page, reference pages, templates, scripts or workflows, and rubric entry. Flag missing and one-way links.
- **One name per concept**: for example team lead versus platform lead, member versus attendee, coach versus facilitator, foundation versus ALZ-lite, GHCP versus GitHub Copilot. The glossary covers every acronym used.
- **Duplicated facts** that can drift: list each one and name the page that should own it.
- The Contoso University story reads as one narrative from opportunity to hand-over.

### 6.5 Order and sequencing

- Sidebar order versus the real timeline (pre-work, Day 1, Day 2, T+2) and versus dependencies. Guides and prompts appear in the order they are used.
- Inside each page: prerequisites before steps, verification after each step, cleanup last.
- Nothing is used before it is created. The hard dependencies in `AGENTS.md` hold on every page: ALZ-lite and each datacenter before vending, `Test-Datacenter` before Arc, the Graph grant after ALZ-lite and before C7, vending after `vm-dev01` setup, vending before the archetype.
- Time boxes add up to the two-day agenda.

### 6.6 Clarity, tone and style

- Microsoft Writing Style Guide as enforced by Vale; US English to match the site; second person; sentence-case headings; short sentences.
- Instructions are unambiguous and testable. Every command is copy-pastable and names its shell.
- Student pages never offer running the deploy scripts by hand (that path is coach-only).

### 6.7 Audience separation

- Coach material is public by design (honor system). Do not flag that. Do flag where attendees are routed into coach answer keys by accident, or where a coach page does not say who it is for.

### 6.8 Technical hygiene and accessibility

- Page titles and descriptions, one H1 per page, heading hierarchy, alt text, descriptive link text, Mermaid diagrams render and have a text alternative, last-updated dates, edit links work.

## 7. Method

Run the deterministic checks first; they are cheap and they anchor the reading.

1. **Mirror the source.** Read the site from the repo, not the rendered HTML: `site/src/content/docs/**`, the coach sources (`coach/`, `facilitator/agenda.md`, `facilitator/automation-map.md`), components, `challenges.json`, and every script, workflow, Bicep file and template a page names.
2. **Check every link and anchor from source.** Include the coach pages (apply `coach-loader.ts`'s link rewriting), trailing slashes, redirects and absolute links to the site's own domain. Open every outside link and note the ones that now redirect elsewhere.
3. **Compare data across copies.** Points, time boxes, scope and day for each challenge in the rubric, `challenges.json`, components (for example `JourneyMap.astro`), challenge pages and coach sheets; the agenda against every page that repeats it.
4. **Walk the live site** for what source can't show: the prev/next pager at every section boundary, search for common questions, the 404 page, redirects and the generated coach index.
5. **Read every page in full** (split the site into slices and review them in parallel when there are many pages), walking the three persona journeys.
6. **Check scripts and IaC** for every command, parameter, input, stage and resource name the pages use; for commands a team lead copies, check what they do in the lead profile.
7. **Check outside facts** against Microsoft Learn, GitHub Docs and Partner Center; cite and date each check.
8. **Merge, remove duplicates and group findings into root-cause themes**; each theme becomes one GitHub issue.

## 8. Output (Markdown only)

1. **Executive summary.** Readiness rating (red, amber, green) per dimension with the rule used, what already works, the top issues, quick wins and the owner decisions.
2. **Themes.** Root causes, each with what's wrong, why it matters, the fix and its findings.
3. **Findings register.** One row per finding: ID · severity · dimension · persona affected · page URL · source file · evidence (short quote) · problem · recommended fix · effort (S, M, L).
   - **P0** blocks the event or a persona's journey.
   - **P1** likely to cause failure, rework or confusion.
   - **P2** quality issue.
   - **P3** polish.
4. **Recommended information architecture.** Current versus proposed sidebar and page order. Restructuring is allowed; every internal link and anchor must still resolve, and every moved URL gets a redirect.
5. **Traceability matrix.**
6. **Fact table.** Fact · value on each page · correct value · source of truth.
7. **Persona journey notes.**
8. **GitHub Copilot hand-off** (section 9).

## 9. GitHub Copilot hand-off

Two artefacts:

1. **A backlog-style spec** in the same shape as the archived backlog items (field table, Outcome, Before you start, numbered Requirements with 🔎 VERIFY markers, Deliverables, Verify, Done when, Commit message, Stop and ask if, Notes and traps), executed under the backlog executor protocol.
2. **One GitHub issue body per theme**, each assignable to the Copilot coding agent, each pointing at the spec's requirement numbers.

Both must:

- Tell Copilot to follow `AGENTS.md`, Vale, markdownlint and Prettier, and to pass `npm run check` before each pull request; draft PRs only.
- Separate **fix now** from **needs owner decision**. Copilot must not make owner decisions.
- Require zero broken links: update every internal link when a page moves, and add a redirect in `astro.config.mjs`.
- Never change code, scripts or Bicep to match the docs without asking: when prose and code disagree, the spec says which one changes.

## 10. Rules for the reviewer

- Every finding has a URL and a short quoted piece of evidence.
- Anything that cannot be verified is marked **Needs owner confirmation**, not reported as a defect.
- Keep defects and suggestions apart.
- Do not report intentional design decisions as defects; report only their side effects.
- Recommend the smallest fix that solves the problem.
