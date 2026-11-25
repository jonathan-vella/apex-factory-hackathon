---
title: Connect to your VMs
description: Use native Remote Desktop through Azure Bastion from local Windows PowerShell, or connect through your browser.
---

Use your local Windows Remote Desktop client to connect through Azure Bastion to `vm-dev01`, your workstation for all challenges, or `vm-app01`, the source app and SQL Server. Native RDP is the recommended option on Windows. Use [browser-based Bastion](#browser-fallback) if you cannot install local tools or use macOS or Linux.

Run the connection commands below on **your own Windows computer**, not in Azure Cloud Shell or inside a lab VM. Your challenge work still runs on `vm-dev01`; you do not need to clone the kit onto your laptop.

## Before you connect

- Have Windows with **Remote Desktop Connection** (`mstsc`) and the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli-windows) installed. Open a new local PowerShell window after installation.
- Have your tenant ID and workload subscription ID from your private settings or team lead. Do not use the shared services subscription.
- Have the VM's `labadmin` password from the onboarding step, your team lead, or the [lab credentials reference](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/infra/datacenter/README.md#credentials). Do not put the password in a command, screenshot or evidence file.
- The target VM must be running. Your Azure account needs Reader access to the VM, its network interface and `bas-datacenter`. The required Owner access on your workload subscription includes these permissions.

The kit already deploys `bas-datacenter` in `rg-datacenter` with Bastion Standard and native-client support enabled. You do not need to deploy or change anything in Azure to use it. The VMs have no public IPs; do not open public RDP access.

## Set up your local connection tools

In **local Windows PowerShell**, install the Bastion extension:

```powershell
az extension add --name bastion --only-show-errors --output none
```

If it is already installed, update it with `az extension update --name bastion --only-show-errors --output none`.

Sign in to the event tenant and select your workload subscription. Replace the placeholders with your private values:

```powershell
az login --tenant '<tenant-id>' --output none
az account set --subscription '<workload-subscription-id>'
az account show --query name --output tsv
```

Check that the last command names your workload subscription. If browser sign-in is unavailable, use `az login --tenant '<tenant-id>' --use-device-code --output none` and follow your organization's sign-in requirements.

These are **Azure CLI** commands running in PowerShell, not Az PowerShell cmdlets. `Connect-AzAccount` does not sign you in to Azure CLI. The native RDP connection below uses `az network bastion rdp`; you do not need to install the Az PowerShell module.

## Connect to vm-dev01 or vm-app01

In the same **local PowerShell window**, run:

```powershell
$vmName = 'vm-dev01'
$vmId = az vm show --resource-group rg-datacenter --name $vmName --query id --output tsv --only-show-errors
if ($LASTEXITCODE -ne 0 -or -not $vmId) {
    throw 'VM lookup failed. Check your tenant, workload subscription and VM name.'
}
az network bastion rdp --name bas-datacenter --resource-group rg-datacenter --target-resource-id $vmId --only-show-errors
if ($LASTEXITCODE -ne 0) {
    throw 'Bastion RDP failed. Read the error above and use the troubleshooting guidance below.'
}
```

When Remote Desktop asks for credentials, choose **More choices** > **Use a different account** if needed, and enter `labadmin` and the VM password. Use `.\labadmin` if Windows tries your work account instead. Your Azure sign-in authorizes the Bastion connection; the VM uses its local Windows account, not your Microsoft Entra password.

Keep the PowerShell window open while connected: closing it ends the tunnel. On first sign-in to `vm-dev01`, allow up to five minutes for VS Code extensions to install, then return to your onboarding steps.

To connect to **`vm-app01`**, change `$vmName` to `'vm-app01'` and run the connection block again. To keep both VM desktops open, run a separate connection block in a second local PowerShell window, after checking the selected subscription there.

### Reconnect later

Open local PowerShell, confirm your workload subscription with `az account show --query name --output tsv`, and repeat the connection block. Sign in again if Azure CLI requests it. On `vm-dev01`, open PowerShell 7 and run `code C:\src\<your-repo>`; do not clone your repository again. Never stop or deallocate `vm-dev01` during the event.

### Optional shortcut with a local kit copy

If you already have the kit on your Windows computer and use **PowerShell 7.4 or later**, run this from its `factory` folder after installing the Bastion extension and signing in with `az login`:

```powershell
.\scripts\Connect-DatacenterVm.ps1 -SubscriptionId '<workload-subscription-id>' -VmName vm-dev01
```

Use `-VmName vm-app01` for the source server. This existing helper checks VM power state and native-client support before launching the same Azure CLI RDP command. You do not need a local kit copy for the direct commands above.

## Browser fallback

Open the [Azure portal](https://portal.azure.com) on your own computer and select the event directory and your workload subscription. Go to **Resource groups** > **rg-datacenter** > **vm-dev01** (or **vm-app01**) > **Connect** > **Bastion**. Select **Password**, enter `labadmin` and the VM password, and choose **Connect**. Allow portal pop-ups and Bastion clipboard access when prompted.

Browser-based Bastion needs no local Azure CLI. Use it from Windows, macOS or Linux. Do not run native RDP commands in Cloud Shell: they launch a client on your local Windows computer, and Cloud Shell does not support them.

## Troubleshooting

| Problem | What to check |
| --- | --- |
| `az` is not recognized or the Bastion command is missing | Install Azure CLI, open a new local PowerShell window, then install or update the `bastion` extension as above. |
| VM or Bastion resource not found | Check the event tenant and workload subscription. Both VMs and `bas-datacenter` are in `rg-datacenter`, not the shared services subscription. |
| Authorization failed | Confirm your workload subscription access with your team lead. Reader is needed on the VM, NIC and Bastion; do not change tenant policies to connect. |
| VM is stopped | Check its power state in the portal and start your assigned VM before connecting. Do not redeploy the datacenter. |
| Native-client support is reported as disabled | Contact your team lead. The kit enables it during deployment; do not rerun `member` or redeploy an Arc-connected datacenter to repair a connection. Use browser Bastion while the team lead investigates. |
| Windows rejects the credentials | Select a different account, try `.\labadmin`, and confirm the VM password privately with your team lead. Do not use your Azure account password. |
| Connection times out on the local network | Ask your network administrator to check outbound HTTPS and WebSocket access to Bastion and Azure sign-in endpoints. Try browser Bastion; do not add a VM public IP or allow internet access to TCP 3389. |

Microsoft documents the command and prerequisites in [Connect using Bastion and the Windows native client](https://learn.microsoft.com/azure/bastion/connect-vm-native-client-windows).
