# C5 answer key: Deploy the CoE archetype with APEX (coach)

> [!WARNING]
> Coach material. This page has the answers to C5. Attendees run APEX's `/apex-adapt-archetype` flow themselves in `C:\src\<your-repo>` on `vm-dev01`.

`Import-Kit.ps1` sets `*.bicepparam text eol=lf` in `.gitattributes` and `Install-DevTools.ps1` installs `node` 24 LTS and `azd` on `vm-dev01`, so `/apex-adapt-archetype` and `azd provision` run cleanly on `vm-dev01`.

## Expected evidence

**Timing cues:** the first 30 minutes are the coach demo; use **APEX demo script** in the Coach sidebar. By halfway through member work, expect the reviewed preview and one provisioning run. Use the MI wait for starting C6 and running As-Built.

- The member's own repo (`C:\src\<your-repo>` on `main` on `vm-dev01`) with `agent-output/university/06-deployment-summary.md` and the `agent-output/university/07-*.md` As-Built suite committed on `main` (with any raw subscription/tenant IDs redacted).
- `az resource list -g rg-university-<suffix> -o table` showing App Service, ACR, SQL MI, Storage (Blob), Service Bus, Key Vault and Application Insights, with `publicNetworkAccess` set to `Disabled` on data backends.

## Model answer

1. The member's repo and the archetype are already in place in `C:\src\<your-repo>` from `Import-Kit.ps1`. If the archetype is missing, run `./factory/archetype/Import-Archetype.ps1 -Ref main` from `C:\src\<your-repo>`.
2. Sign in to `azd` on `vm-dev01` (`azd auth login --use-device-code`) and run `/apex-adapt-archetype` in agent mode: it reads tenant ID, subscription ID and suffix from `factory/.local/settings.json`, confirms the spoke that vending created before the event exists (`rg-spoke`, `vnet-spoke`, `snet-app`, `snet-pe`, `snet-sqlmi`), runs its lightweight governance check, and stops at `azd provision --preview`.
3. Review the skill's preview. Switch from chat to PowerShell 7 in `C:\src\<your-repo>\infra\bicep\university` and run the page's preflight in that shell before deployment; it exports process variables. If inputs or templates changed since the skill's preview, rerun and review `azd provision --preview` in the same shell. Run `azd provision` there only after accepting the reviewed changes.
4. Run agent `08-As-Built` to produce the `agent-output/university/07-*.md` deployed-state documentation suite, and commit `agent-output/university/` on `main`.
5. Confirm no public endpoints beyond the web app's front end and Application Insights ingestion (the member's `publicNetworkAccess` queries on Storage, Key Vault, Service Bus and ACR all return `Disabled`), naming convention followed, and the web app identity's six role assignments present: AcrPull, Key Vault Secrets User, Storage Blob Data Contributor, Service Bus Data Sender, Service Bus Data Receiver and Monitoring Metrics Publisher.
6. SQL MI licensing. The archetype prices SQL MI with Azure Hybrid Benefit (`licenseType` is `'BasePrice'` in `infra/bicep/university/modules/sql-mi.bicep`). A member without eligible licences changes `var licenseType = 'BasePrice'` to `'LicenseIncluded'` in that file **before** `azd provision`.

## Business outcome check

The outcome is repeatable provisioning. Check that `06-deployment-summary.md` and the `07-*.md` As-Built record describe the resources the resource listing shows.

## Common mistakes

- Treating `azd provision --preview`'s partial output as a failure — it only lists resource types `azd` has display names for; SQL MI, the managed identity, role assignments and the maintenance schedule are created even though the preview doesn't name them.
- Skipping the As-Built step because the deployment "obviously worked" — As-Built produces the `07-*.md` artifacts used in C10.
- Trying to run `/apex-adapt-archetype` for a member who hasn't been vended yet — it fails fast with a clear "spoke not found" message. A preflight that stops with "cannot be read" or a missing `assign/action` permission on `id-sqlmi-directory` means vending ran without the member's `-MemberPrincipalId`: the team lead re-runs vending with it.

## Reset

`azd down --purge` then redeploy from the member's repo if something needs a clean restart. **It deletes `rg-university-<suffix>` including the SQL managed instance and, after C7, the migrated database**, so only use it before C7, and tell the member first. After the managed instance is deleted, its SQL virtual cluster keeps holding `snet-sqlmi` for a while, and the preflight stops with "a SQL virtual cluster from a deleted managed instance still holds snet-sqlmi" until Azure releases it (this can take hours). So prefer fixing forward over `azd down` when you can, and if you do tear down, expect to wait before redeploying. The governance check and spoke vending don't need to be redone.
