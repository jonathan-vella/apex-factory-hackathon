# university

Bicep archetype for the Contoso University platform: a Linux container web app on App Service, a private Premium
container registry, SQL Managed Instance, Blob storage, a Service Bus queue, Key Vault and workspace-based Application
Insights, placed in the existing vended spoke. One subscription-scope deployment creates `rg-university-<suffix>` and
every workload resource in it. It declares no VNet, subnet, NSG, route table or private DNS zone; those belong to the
landing zone.

## Inputs

Three values are yours; everything else is derived read-only by the preflight hook.

| azd environment value   | Meaning                                                          |
| ----------------------- | ---------------------------------------------------------------- |
| `AZURE_TENANT_ID`       | Entra tenant of the deployment                                   |
| `AZURE_SUBSCRIPTION_ID` | The workload subscription                                        |
| `SUFFIX`                | 4-6 lowercase letters or digits; the only uniqueness in names    |

The preflight hook sets `AZURE_LOCATION` (the hub VNet region), `LOG_ANALYTICS_WORKSPACE_ID`,
`SQLMI_DIRECTORY_IDENTITY_ID` (the shared `id-sqlmi-directory`, B08-owned), `DEPLOYER_OBJECT_ID` and
`DEPLOYER_UPN`. `CONTAINER_IMAGE` is optional; the postprovision hook sets it to the registry copy.

```bash
cd infra/bicep/university
azd env new university-dev
azd env set AZURE_TENANT_ID <tenant-id>
azd env set AZURE_SUBSCRIPTION_ID <subscription-id>
azd env set SUFFIX <suffix>
azd env set AZURE_LOCATION swedencentral
azd provision --preview
azd provision
```

Nothing in this folder contains a tenant, subscription or object ID. Values come from the azd environment through
`readEnvironmentVariable()` in `main.bicepparam`.

## Hooks

Both hooks are PowerShell 7 and use the Azure CLI only. They run on the dev VM, the dev container and Cloud Shell.
The logic lives in standalone scripts that the kit's `archetype/deploy.ps1` can call directly.

| Script                         | Purpose                                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------------------------ |
| `scripts/preflight.ps1`        | Read-only checks and derivation. Fails closed before anything is created.                        |
| `scripts/postdeploy-tests.ps1` | MCR start, routing, private DNS, ACR import and private pull, diagnostics. Never claims telemetry. |
| `scripts/write-deployment-summary.ps1` | Writes `06-deployment-summary.md` from the observed deployment record and test results. Unobserved items are `unverified`; it never claims completion. |
| `scripts/hooks/preprovision.ps1`  | Runs the preflight and writes the derived values to the azd environment.                      |
| `scripts/hooks/postprovision.ps1` | Runs the post-deployment tests, keeps later runs on the registry image, then writes the evidence summary (best effort; a failure only warns). |

## Azure Hybrid Benefit assumption for SQL Managed Instance

The SQL managed instance is deployed with `licenseType: 'BasePrice'`, which applies Azure Hybrid Benefit (ADR-0005).
This rests on an owner assumption: the organization holds eligible SQL Server core licences for the 4 vCores. Nothing
in the deployment verifies that entitlement. At 730 hours per month the Step 2 estimate is about $488.92 with Azure
Hybrid Benefit and $780.82 licence-included (compute and licence).

If you are not entitled to Azure Hybrid Benefit, turn it off before deploying:

1. In `modules/sql-mi.bicep`, change `var licenseType = 'BasePrice'` to `var licenseType = 'LicenseIncluded'`.
2. Run `azd provision`.

For an instance that is already deployed, switch it in place and make the same Bicep change, otherwise the next
`azd provision` sets it back to `BasePrice`:

```bash
az sql mi update --resource-group rg-university-<suffix> --name sqlmi-university-<suffix> --license-type LicenseIncluded
```

Turning it off raises the monthly cost; review the budget before doing so.

## Redundancy and cost notes

- Single zone by design: the App Service plan has one instance with zone redundancy off, SQL MI has zone redundancy off,
  and Storage is `Standard_LRS`. The registry and the Service Bus namespace are zone redundant because their pinned
  modules always send that setting; this is recorded and accepted.
- The SQL MI start/stop schedule (Monday to Friday, 07:30 to 18:30, `W. Europe Standard Time`) takes effect only
  after the MI link is removed. Until then the instance runs around the clock.
- Cost monitoring is inherited from the vending budget. This template creates no budget or Action Group.

## Failure and recovery

ARM does not roll back. If provisioning fails, fix the cause and run `azd provision` again; the template is idempotent.
A partially created SQL managed instance bills about $0.68 per hour (24x7, Azure Hybrid Benefit). Cleanup is never
automatic. After a managed instance is deleted, its virtual cluster can hold `snet-sqlmi` for hours; the preflight stops
with an explanation until it is released.
