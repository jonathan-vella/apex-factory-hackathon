# B00: Create the repo, milestones and issues

| Field | Value |
|---|---|
| Milestone | P1 Skeleton and datacenter |
| Type | Both |
| Depends on | — |
| Unblocks | B01, B02 |
| Effort | 30 minutes |
| Cost | None |
| Teardown | Not applicable |
| PRD | §7 |

## Outcome

- `jonathan-vella/apex-factory-hackathon` exists on GitHub as a public template repo, and `main` holds the files in the local kit folder.
- Five milestones and 13 issues exist. Issue #N tracks backlog item BNN.

This item is the exception to the normal flow. It runs in the local folder before the repo exists, pushes `main` directly and has no issue or PR.

## Before you start

Run these from the local kit folder, for example `C:\repos\apex-factory-hackathon`:

1. `docs/backlog/README.md`, `docs/backlog/AGENTS.md` and this runbook exist.
2. `git rev-parse --is-inside-work-tree` fails, because the folder isn't a git repo yet. If it prints `true`, stop and ask.
3. `gh auth status` shows `jonathan-vella` with the `repo` and `workflow` scopes.
4. `gh repo view jonathan-vella/apex-factory-hackathon` fails with "Could not resolve to a Repository". If it succeeds, stop and ask.
5. `git config user.name` and `git config user.email` both print a value.

## Requirements

### Secret scan

1. Before the first commit, scan every file that will be committed (everything not ignored by `.gitignore`) for GUIDs, GitHub tokens (`ghp_…`, `github_pat_…`), storage and Service Bus keys (`AccountKey=`, `SharedAccessKey=`), SAS signatures (`sig=`) and private key headers. The only GUID allowed is the all-zero GUID. Any other hit stops the item.

### Repo

2. Initialize git with `main` as the default branch and make one commit that contains exactly the folder's files: `.gitattributes`, `.gitignore`, `.markdownlint-cli2.mjs`, `LICENSE`, `README.md` and everything under `docs/`. Anything else stops the item.
3. Create the repo and push `main`:
   - public;
   - description: `Partner Modernization Factory: a challenge-based Azure migration and modernization hackathon kit for partners. Modernize today. Enable AI tomorrow.`
   - homepage: `https://factory.apexops.pro`.
4. Configure the repo: template on, wiki off, squash merge only (merge commits and rebase merges off), auto-merge on (Dependabot uses it from B01), and delete branches after merge.
5. Don't add labels, projects, rulesets or branch protection. They aren't part of v1.

### Milestones

6. Create one milestone per roadmap phase. The title is the **Phase** column of the [roadmap](../roadmap.md) table and the description is its **Goal** column. The titles must be exactly:
   - `P1 Skeleton and datacenter`
   - `P2 Spikes`
   - `P3 Build`
   - `P4 Content`
   - `P5 Pilot and v1.0`

### Issues

7. Create one issue per row of the **Items** table in [README.md](README.md#items), B01 to B13, in ID order, from that table's data rather than from the runbook files, so the table stays the single source for titles, milestones and dependencies:
   - Title: `BNN: <Title>`.
   - Milestone: the one whose title starts with the row's Milestone value (`P1` → `P1 Skeleton and datacenter`).
   - Body: a link to `docs/backlog/BNN-<slug>.md` if the runbook exists, otherwise the text `Runbook: to be written.`; the dependencies as issue references (`B04` → `#4`, and `B00` → `B00 (done)`); and the kickoff prompt from [README.md](README.md#how-to-run-an-item) in a `text` code block.
8. Issue #N must be item BNN. Create them in order before anything else takes a number, check each returned number, and stop if one doesn't match. Re-running the step must skip issues that already exist, not duplicate them.
9. Don't commit the helper script you use for steps 7–8. If you write one, keep it in `$env:TEMP`.

### Copilot app

10. 🧑 HUMAN: In the GitHub Copilot app, open `jonathan-vella/apex-factory-hackathon` as a repository project, so that each later item runs in its own session and branch.

## Deliverables

- The GitHub repo `jonathan-vella/apex-factory-hackathon` with one commit on `main`.
- Five milestones and issues #1–#13.
- No new files in the repo.

## Verify

```powershell
$repo = 'jonathan-vella/apex-factory-hackathon'
git log --oneline
gh repo view $repo --json isTemplate,hasWikiEnabled,squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed,autoMergeAllowed,deleteBranchOnMerge
gh api "repos/$repo/milestones?state=all" --jq '.[].title'
gh issue list --repo $repo --state open --limit 50 --json number,title,milestone --jq 'sort_by(.number) | .[] | "\(.number) \(.title) [\(.milestone.title)]"'
```

- `git log` shows one commit.
- `isTemplate`, `squashMergeAllowed`, `autoMergeAllowed` and `deleteBranchOnMerge` are `true`; the other three are `false`.
- The five milestone titles match requirement 6.
- The issue list shows #1–#13. Each title starts with its item ID and each milestone matches the Items table.

## Done when

- [ ] The secret scan found nothing.
- [ ] The repo is public, a template, squash-merge only, with auto-merge on, no wiki, and branches deleted after merge.
- [ ] `main` has one commit with the docs.
- [ ] The five milestones exist.
- [ ] Issues #1 to #13 exist, each in the right milestone, with the right dependencies.

## Commit message

```text
docs: add PRD, roadmap and backlog
```

## Stop and ask if

- The repo already exists, or the folder is already a git repo.
- The secret scan finds anything.
- The first commit would include unexpected files.
- An issue gets a number that doesn't match its item.

## Notes and traps

- Issue numbers match item numbers only because B00 creates all the issues before any PR exists. PRs and issues share one number sequence.
- If the push fails with an authentication error, push through the GitHub CLI credential helper (`gh auth git-credential`).
- `gh issue create` prints progress to stderr and the issue URL to stdout. Read the number from the URL.
- Runbooks written after B00 reach `main` through normal docs PRs. Their issues already exist, so no issue needs to change when a runbook lands, apart from replacing `Runbook: to be written.` with the link.
