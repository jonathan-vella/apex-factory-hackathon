# Lifelines

Lifelines are for coaches and facilitators, not students. A coach decides when a stuck member gets one, then applies it with the member or hands it over. Students don't fetch lifelines themselves, and the playbook and challenge pages don't mention them.

There are five checkpoint branches, `lifeline/L1-net10` to `lifeline/L5-cutover`, plus a known-good image as the last resort. All of them are public in `jonathan-vella/apex-factory-hackathon`.

## What each lifeline contains

The branches hold only what GitHub Copilot produced on the kit's golden path (the B06 v3 run, `spike/b06-upgrade-compare-v3` at `54b5b45`), replayed onto the kit with no hand fixes. Each one also carries the Upgrade agent's scenario state in `.github/upgrades/scenarios/dotnet-version-upgrade/`, with the finished tasks marked complete. So after a switch the member can start the next task with `start_task`.

| Branch | Commit | Checkpoint | Golden-path commits | Next for the member |
|---|---|---|---|---|
| `lifeline/L1-net10` | `7b3a631` | .NET 10 and ASP.NET Core MVC; builds and runs on `vm-dev01` against the source database | `d08dc9d` plan, `bfd8bf7` task 01 | Task 02 |
| `lifeline/L2-blob` | `fb8bcbf` | L1 plus the database task (Entra-only outside Development, SQL authentication in Development) and uploads on Blob | `bd0ecad` task 02, `e9a1003` task 03 | Task 04 |
| `lifeline/L3-servicebus` | `f79d392` | L2 plus Service Bus instead of MSMQ, with the notification service in DI | `4b7fb02` task 04 | Task 05 |
| `lifeline/L4-ready` | `295882d` | L3 plus Key Vault, OpenTelemetry and the CVE audit: C6's code is complete | `e9d21d1` task 05, `c07f747` task 06, `54b5b45` task 07 | Package and C6 configuration (playbook steps 4 and 5) |
| `lifeline/L5-cutover` | `119ea50` | L4 plus the app README's App Service and SQL Managed Instance section: the C7 end state | L5 adds documentation only | C7 go-live (playbook step 5) |

Every lifeline is cut from base commit `3ce1bbf`, the kit with the playbook and skills. L1 and L2 keep notifications in memory, in the app's own process, until task 04. That's how the golden path did it, and they don't survive a restart.

The **known-good image** `ghcr.io/jonathan-vella/contoso-university:known-good` is L5 built with .NET SDK container publishing, also tagged with L5's commit. Its digest is in [versions.md](../versions.md).

## When to hand one out

A lifeline is for a member who is blocked, not slow: they've tried the playbook's hot-spot fixes, and the time box is at risk. The coach decides, and the facilitator guide (B12) owns the handout rules. Give the earliest lifeline that unblocks the member, so they keep as much of their own work as possible.

| Member is stuck on | Give |
|---|---|
| Task 01 (.NET 10) | `lifeline/L1-net10` |
| Tasks 02–03 (database, Blob) | `lifeline/L2-blob` |
| Task 04 (Service Bus) | `lifeline/L3-servicebus` |
| Tasks 05–07 or the gaps | `lifeline/L4-ready` |
| C7 configuration on App Service | `lifeline/L5-cutover` |
| The image won't build or push, and the clock is out | The known-good image |

**Cost in points:** a lifeline caps that challenge's points, but later challenges stay eligible (PRD §5). The scoring rubric in `facilitator/` is the source of truth for the caps (today: C6 and C7), and you record every lifeline there. Student pages don't mention lifelines or caps: you decide, you apply, and you tell the member what it costs. Ordinary hints and coach discussion never trigger a cap.

## How to apply one

Template copies don't include non-default branches, so fetch the lifeline from the upstream repo into the member's repo. On `vm-dev01`, in the member's clone, with the member:

1. Save the member's work, so nothing is lost:

   ```powershell
   git add -A
   git commit -m "wip: before lifeline"
   git push
   ```

2. Fetch the lifeline, switch to it and push it to the member's repo:

   ```powershell
   git fetch https://github.com/jonathan-vella/apex-factory-hackathon.git lifeline/L3-servicebus:lifeline/L3-servicebus
   git switch lifeline/L3-servicebus
   git push -u origin lifeline/L3-servicebus
   ```

   If GitHub refuses the push because the token lacks the `workflow` scope (the lifeline carries the kit's workflow files), run `gh auth refresh -h github.com -s workflow` and push again.

3. Remove leftovers that `git switch` keeps, because old plans and build output steer the agent:

   ```powershell
   git clean -ndx -- app .github     # dry run: read the list
   git clean -fdx -- app .github
   ```

4. Set the user secrets again (playbook, step 2, "Local configuration"). The lifeline's project has its own `UserSecretsId`, so the member's earlier secrets don't apply.
5. Run the app and do the checks for the last task the lifeline contains. Then the member starts the next task in a new chat, in the Local harness.

**The known-good image.** The member's registry has no public access, but `az acr import` runs inside Azure and works because the registry allows trusted Azure services. The archetype gives its deployer the import role:

```powershell
az acr import --name cruniversity<suffix> --source ghcr.io/jonathan-vella/contoso-university:known-good --image contoso-university:known-good
```

Then go live with the tag `known-good` in the playbook's step 5, C7 step 3. The Key Vault secret and the database user are still needed.

## Rebuild the lifelines

Rebuild every lifeline when the base changes: for example after a change to `.github/` that attendees should get, or a new golden path. Later lifelines build on earlier ones, so if one changes, rebuild all the ones after it. Then publish the known-good image again.

```powershell
git switch --detach <new base commit>
git cherry-pick d08dc9d bfd8bf7;          git branch -f lifeline/L1-net10
git cherry-pick bd0ecad e9a1003;          git branch -f lifeline/L2-blob
git cherry-pick 4b7fb02;                  git branch -f lifeline/L3-servicebus
git cherry-pick e9d21d1 c07f747 54b5b45;  git branch -f lifeline/L4-ready
git cherry-pick 119ea50;                  git branch -f lifeline/L5-cutover
git push --force origin lifeline/L1-net10 lifeline/L2-blob lifeline/L3-servicebus lifeline/L4-ready lifeline/L5-cutover
```

The **Build lifelines** workflow builds every pushed `lifeline/*` branch. **Publish known-good image** is a manual workflow that builds `lifeline/L5-cutover` and pushes it to GHCR. Update the commits in the table above and the digest in `versions.md`.
