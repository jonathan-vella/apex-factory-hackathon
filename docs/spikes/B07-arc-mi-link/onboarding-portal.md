# Onboard vm-app01 to Azure Arc

The attendee page for C0, written for B11 to turn into the challenge page. One script connects `vm-app01` (Windows Server 2022 with SQL Server 2022 Developer) to Azure Arc, so its SQL Server becomes an Arc-enabled SQL Server, ready for the migration assessment. Onboarding is automated: there are no manual portal steps (owner decision, 2026-10-02). The time it takes is in the [report](README.md#timings).

> **Lab only.** Azure VMs aren't normally Arc-enabled: they already have everything Arc offers. The datacenter pretends to be on-premises, so the script first makes `vm-app01` look like an on-premises server ([Evaluate Arc-enabled servers on an Azure VM](https://learn.microsoft.com/azure/azure-arc/servers/plan-evaluate-on-azure-virtual-machine)). Never do this to a customer's Azure VM.

## Before you start

- The datacenter is deployed and `scripts/Test-Datacenter.ps1` passes. **Run it first:** after onboarding, run commands stop working on `vm-app01`, and the test's in-VM checks with them.
- PowerShell 7.4 or later and the Azure CLI, signed in with `az login` to the member's tenant. Azure Cloud Shell has both. Run from the root of your copy of the kit repo.
- Your account has Owner or Contributor on the workload subscription. Onboarding needs **Virtual Machine Contributor** on `vm-app01` and **Azure Connected Machine Resource Administrator** on `rg-datacenter`, and both roles cover them.

## Run it

```powershell
./scripts/Connect-DatacenterArc.ps1 -SubscriptionId '<workload-subscription-id>' -MemberIndex <n> -Location <region>
```

`-Location` is the datacenter's region (`swedencentral` by default). The script runs unattended and returns when the SQL Server instance shows in Azure, or after 20 minutes with a pointer to the log.

## What the script does

1. Refuses to run if `vm-app01` is already an Arc machine, or if its guest agent is already off.
2. Removes the VM extensions from `vm-app01` (for example `MDE.Windows`, which Defender for Servers adds), because Arc's agent can't manage extensions that Azure installed.
3. Sends one run command that stages the rest and returns. It passes your Azure Resource Manager access token as a protected parameter (no service principal) and registers a one-time task on `vm-app01` that starts a minute later. Turning off the guest agent ends any run command, so the task does the rest:
   - runs `C:\LabTools\arc\Prepare-ArcOnAzureVm.ps1`, which the datacenter deployment placed there: it sets `MSFT_ARC_TEST`, turns off the Azure guest agent and blocks the Azure Instance Metadata Service (`169.254.169.254` and `169.254.169.253`) in Windows Firewall;
   - installs the Azure Connected Machine agent and connects it to `rg-datacenter` with your token.
4. Waits for the Arc machine to be **Connected**, then for Arc to connect SQL Server automatically: the **Azure extension for SQL Server** (`WindowsAgent.SqlServer`) installs and reports the instance.

From then on, run commands and VM extensions don't work on `vm-app01`. Reach it through Bastion.

## Check it

1. **Azure Arc** > **Machines** shows `vm-app01` as **Connected**.
2. **Azure Arc** > **SQL Server instances** shows `vm-app01`, edition **Developer**. Developer is free, whatever the licence type shows.
3. On `vm-app01` (through Bastion), `azcmagent show` prints `Agent Status : Connected`.

Next: the migration assessment. Open the SQL Server instance > **Migration** > **Database migration** > **Assess source instance** > **View report**, and use **Run assessment** if there's no result yet.

## Troubleshooting

- **The script refuses to run** because `vm-app01` is already an Arc machine: it's done. Check with `az resource show -g rg-datacenter -n vm-app01 --resource-type Microsoft.HybridCompute/machines --query properties.status`.
- **The script refuses because the guest agent is off**: an earlier run got as far as the prep script. Run commands can't reach `vm-app01` any more. Read the log (next item); if the onboarding didn't finish, ask a coach to redeploy `vm-app01`.
- **No connection after 20 minutes**: connect to `vm-app01` through Bastion (`./scripts/Connect-DatacenterVm.ps1 -SubscriptionId <subscription-id> -VmName vm-app01`, or the portal: `rg-datacenter` > `vm-app01` > **Connect** > **Bastion**) and read `C:\LabTools\logs\Connect-AppArc.log` and `C:\LabTools\logs\Prepare-ArcOnAzureVm.log`. The agent's own logs are in `C:\ProgramData\AzureConnectedMachineAgent\Log`.
- **No SQL Server instance after 20 minutes**: check the `WindowsAgent.SqlServer` extension under **Azure Arc** > **Machines** > `vm-app01` > **Extensions**.
