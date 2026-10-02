# Onboard vm-app01 to Azure Arc: the portal way

The attendee steps for C0, written for B11 to turn into the challenge page. They connect `vm-app01` (Windows Server 2022 with SQL Server 2022 Developer) to Azure Arc, so its SQL Server becomes an Arc-enabled SQL Server, and start the first migration assessment. Times are from the owner's run; see the [report](README.md#timings).

> **Lab only.** Azure VMs aren't normally Arc-enabled: they already have everything Arc offers. The datacenter pretends to be on-premises, so these steps make `vm-app01` look like an on-premises server first ([Evaluate Arc-enabled servers on an Azure VM](https://learn.microsoft.com/azure/azure-arc/servers/plan-evaluate-on-azure-virtual-machine)). Never do this to a customer's Azure VM.

The unattended alternative is `scripts/Connect-DatacenterArc.ps1` (see [the kit script](#the-kit-script-fallback)).

## Before you start

- The datacenter is deployed and `scripts/Test-Datacenter.ps1` passes. **Run it now:** after step 2, run commands stop working on `vm-app01`, and the test's in-VM checks with them.
- `C:\LabTools\arc\Prepare-ArcOnAzureVm.ps1` exists on `vm-app01`. The datacenter deployment places it there.
- Your account has Owner or Contributor on the workload subscription (Arc needs **Azure Connected Machine Resource Administrator** on `rg-datacenter` and **Virtual Machine Contributor** on `vm-app01`, which both cover).

## Steps

| Step | What you do | Time |
|---|---|---|
| 1 | Remove the VM extensions | |
| 2 | Run the prep script on `vm-app01` | |
| 3 | Generate the onboarding script in the portal | |
| 4 | Run it on `vm-app01` | |
| 5 | Check the machine and the SQL Server instance | |

### 1. Remove the VM extensions

Arc's agent can't manage extensions that Azure already installed on the VM, so remove them first. In the Azure portal, open `rg-datacenter` > `vm-app01` > **Settings** > **Extensions + applications**. Select each extension (for example `MDE.Windows`, which Defender for Servers adds if it's on) and select **Uninstall**. Wait until the list is empty.

From Cloud Shell instead:

```powershell
az vm extension list -g rg-datacenter --vm-name vm-app01 --query "[].name" -o tsv
az vm extension delete -g rg-datacenter --vm-name vm-app01 -n <extension-name>
```

### 2. Run the prep script on vm-app01

1. Connect to `vm-app01` through Bastion: `./scripts/Connect-DatacenterVm.ps1 -SubscriptionId <subscription-id> -VmName vm-app01` from Windows, or the portal: `rg-datacenter` > `vm-app01` > **Connect** > **Bastion**. Sign in as `labadmin` with the lab password.
2. Open **Windows PowerShell** as administrator and run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File C:\LabTools\arc\Prepare-ArcOnAzureVm.ps1
   ```

   It sets `MSFT_ARC_TEST`, turns off the Azure guest agent and blocks the Azure Instance Metadata Service (`169.254.169.254` and `169.254.169.253`) in Windows Firewall. If it warns about extension handlers, go back to step 1. It's safe to run again.

From here on, run commands and VM extensions don't work on `vm-app01`, for good.

### 3. Generate the onboarding script in the portal

1. In the Azure portal, search for **Azure Arc**. Under **Infrastructure**, select **Machines**.
2. Select **Onboard/Create** > **Onboard existing machines**.
3. On **Basics**:
   - **Subscription**: your workload subscription. **Resource group**: `rg-datacenter`.
   - **Region**: the datacenter's region (`swedencentral` by default).
   - **Operating system**: Windows.
   - **Connectivity method**: Public endpoint. `vm-app01` reaches Azure through the datacenter's NAT gateway; no proxy.
   - **Authentication**: **Authenticate machines manually** (interactive sign-in).
4. Leave the tags as they are and select **Next**, then **Download**. You get `OnboardingScript.ps1`.

### 4. Run it on vm-app01

1. Copy the script's content to `vm-app01` through the Remote Desktop clipboard, and save it as `C:\LabTools\arc\OnboardingScript.ps1`.
2. Open a **new** Windows PowerShell window as administrator (a new window sees `MSFT_ARC_TEST`) and run:

   ```powershell
   cd C:\LabTools\arc
   powershell -ExecutionPolicy Bypass -File .\OnboardingScript.ps1
   ```

3. Sign in when it asks, with the account you use for the workload subscription. It installs the Azure Connected Machine agent and connects the machine.

### 5. Check the machine and the SQL Server instance

1. On `vm-app01`: `azcmagent show` prints `Agent Status : Connected`.
2. In the portal: **Azure Arc** > **Machines** shows `vm-app01` as **Connected**.
3. Arc connects SQL Server automatically: it installs the **Azure extension for SQL Server** (`WindowsAgent.SqlServer`) on the machine. After a few minutes, **Azure Arc** > **Data services** > **SQL Server instances** shows `vm-app01`, with edition **Developer**. Developer is free.

Next: the migration assessment. Open the SQL Server instance > **Migration** > **Database migration** > **Assess source instance** > **View report**, and use **Run assessment** if there's no result yet.

## The kit script (fallback)

If the portal way doesn't work for you, run this from Azure Cloud Shell or your own computer instead of steps 1–4. It uses your own sign-in, removes the VM extensions, runs the same prep script and connects the agent, unattended:

```powershell
./scripts/Connect-DatacenterArc.ps1 -SubscriptionId '<workload-subscription-id>' -MemberIndex <n> -Location <region>
```

It refuses to run if `vm-app01` is already an Arc machine. If the machine doesn't connect within 20 minutes, it tells you where the log is: `C:\LabTools\logs\Connect-AppArc.log` on `vm-app01`, through Bastion.

## Troubleshooting

- **"This machine is an Azure VM"**: the prep script didn't run, or the onboarding script ran in a window opened before it. Run the prep script, then open a new window.
- **Logs** on `vm-app01`: `C:\LabTools\logs\Prepare-ArcOnAzureVm.log`, and the agent's logs in `C:\ProgramData\AzureConnectedMachineAgent\Log`.
- **No SQL Server instance after 20 minutes**: check the `WindowsAgent.SqlServer` extension under **Azure Arc** > **Machines** > `vm-app01` > **Extensions**.
