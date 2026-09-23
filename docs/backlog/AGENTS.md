# Backlog executor protocol

These rules apply when you execute a backlog item from this folder. Ignore them for any other task. The kickoff prompt is:

```text
Execute backlog item BNN. Follow docs/backlog/AGENTS.md.
```

You're the **executor**. The repo owner, [@jonathan-vella](https://github.com/jonathan-vella), is the **owner**.

Runbooks are specs. They say what to build, the decisions that are already made and how to prove the result works. They don't contain the code: you write it.

- **Fixed:** everything the runbook or the [conventions](README.md#conventions) state: names, paths, versions, SKUs, parameters, behaviour, file lists and checks. Don't change them.
- **Yours:** implementation details the runbook leaves open, such as how a script is structured, as long as the result meets every requirement and convention.
- **Ask:** if filling a gap would change behaviour, cost, security, or a contract another item relies on (names, parameters, outputs, file locations), stop and ask.

## 1. Before you start

1. Read this file, then the conventions in [README.md](README.md), then the whole runbook `docs/backlog/BNN-*.md`. Don't run anything until you've read all three.
2. Check the tools every item needs:
   - PowerShell 7: `$PSVersionTable.PSVersion` is 7.4 or later.
   - Git and the GitHub CLI: `gh auth status` shows `jonathan-vella` with the `repo` and `workflow` scopes.
   - From B01 on: Node 24 (`node --version`) and `npm ci` run at the repo root.
   - Items that touch Azure: Azure CLI 2.70 or later, signed in to the build tenant (`az account show` matches `tenantId` in `.local/settings.json`). Bicep 0.30 or later (`az bicep version`).
3. Check that every item in **Depends on** is closed. Issue number N is item BNN, so for B03 run `gh issue view 3 --json state -q .state`. Each one must print `CLOSED`. If one doesn't, stop and ask. B00 has no issue: it's done once the repo exists.
4. Work on a branch created from an up-to-date `origin/main`. A Copilot app session already has its own branch. Otherwise, run `git switch -c bNN-<slug> origin/main`, using the slug from the runbook file name.
5. Run the runbook's **Before you start** checks. If one fails, stop and report it.

## 2. While you work

- Meet the requirements in order. Build only what they ask for: no extra features, files, dependencies or refactors.
- Deliver every file in the runbook's **Deliverables** list, at that path. Add other files only if a requirement needs them, and list them in the PR body.
- **🧑 HUMAN** marks a step for the owner. Show the step's exact instructions, using the ask_user tool if you have it, then wait for the owner's answer. Afterwards, run the step's check if it has one.
- **🔎 VERIFY** marks a fact to check against the linked page before you rely on it. If the page contradicts the runbook, stop and ask. Don't choose between them yourself.
- Commands are PowerShell 7, run from the repo root unless a requirement says otherwise. Don't put `&&` before a PowerShell statement; use `;` or a separate call.
- If a command fails, read the error. Fix an obvious cause (a typo, a missing folder, a wrong path) and retry. If the same failure happens three times, stop and report the command, the error and what you tried.
- **Quarantined packages.** On a Microsoft device, npm and NuGet restores go through the CFS default proxy. The proxy holds new versions in quarantine for a while, and a held version looks like it doesn't exist: npm reports `E404` or `ETARGET`, and NuGet reports `NU1101` or `NU1102`. Don't work around it. Don't change versions, lockfiles or package-manager settings, and never point a package manager at an `ms-feed-*` URL. Stop and tell the owner the package and version. To check a version, open the public [npm-public](https://dev.azure.com/ms-feed-12/1es-public/_artifacts/feed/npm-public) or [nuget-public](https://dev.azure.com/ms-feed-12/1es-public/_artifacts/feed/nuget-public) feed, select **Search Upstream Sources**, and read its status on the **Upstream Versions** tab. Lockfile `resolved` URLs on `ms-feed-*` hosts are expected; leave them.
- Ask first, one question at a time, before you:
  - start an Azure deployment (show the runbook's cost estimate);
  - delete anything you didn't create in this item: Azure resources, files, branches or releases;
  - force-push, rewrite history or change repo settings, unless a requirement does exactly that;
  - do anything the runbook doesn't cover.
- Never commit secrets, passwords, tokens, keys, connection strings that contain a password, tenant IDs, subscription IDs, object IDs or real public IPs. Keep local values in `.local/settings.json`, which is gitignored (format in [README.md](README.md#local-settings)). Reports use placeholders such as `<subscription-id>`.
- Keep runbooks true. If the owner approves a deviation, update this item's runbook in the same PR so that a re-run works. Don't edit other runbooks. List any problems you find in them under **Follow-ups** in the PR.

## 3. Validate for real

Items that build Azure infrastructure are validated by deploying it, not only by linting it.

1. Run the static checks first: `az bicep build`, `az bicep lint` and PSScriptAnalyzer on every script you wrote. All must be clean.
2. Ask before deploying, as above. Deploy into the build subscriptions with the scripts you wrote, the way an attendee would run them.
3. Run the runbook's **Verify** checks against the live resources.
4. Tear down what you deployed at the end of the item, unless the runbook's **Teardown** row says to keep it. Confirm the resource groups are gone.
5. Report the Azure cost: the hours the resources ran, times the runbook's hourly estimate.

## 4. Finish

1. Run the runbook's **Verify** section. From B01 on, also run `npm run check`. Everything must pass.
2. Confirm every box in **Done when**.
3. Commit with the runbook's **Commit message**: Conventional Commits, one line. Extra commits for fixes are fine; the owner squash-merges.
4. Push the branch. Open a **draft** PR titled `BNN: <runbook title>`. The body holds `Closes #N`, the files you delivered, the verification results, the Azure cost, any deviations the owner approved and any follow-ups. Don't mark it ready or merge it: the owner does both.
5. Report back in 10 lines or fewer: what changed, the verification results, any Azure cost incurred and any follow-ups.

B00 is the only exception. It has no issue and no PR, because it creates the repo and pushes `main` directly.
