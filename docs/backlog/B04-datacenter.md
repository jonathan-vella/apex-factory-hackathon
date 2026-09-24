# B04: Build the datacenter kit

| Field | Value |
|---|---|
| Milestone | P1 Skeleton and datacenter |
| Type | Both |
| Depends on | B02, B03 |
| Unblocks | B05, B06 |
| Effort | 1–2 days |
| Cost | About $1.25/hour while running, with AHB on (2 × D8as_v6 at the Linux rate $0.39; 2 × P30 $0.20: the `vm-app01` data disk and the `vm-dev01` OS disk, billed at its P30 performance tier; 1 × P10 OS disk $0.03; NAT gateway and IP $0.05). About $0.48/hour when the VMs are stopped (deallocated). Without AHB, about $2.00/hour |
| Teardown | **Keep** `rg-datacenter`. B05–B07 build on it and B07 deletes it |
| PRD | §2 Datacenter, Dev environment, Hybrid Benefit; §4; §6 Datacenter |

## Outcome

- One command, `scripts/Deploy-Datacenter.ps1`, deploys a member's "on-premises" datacenter into `rg-datacenter`, unattended, in under 60 minutes:
  - `vm-app01`: Windows Server 2022 with IIS running the legacy Contoso University and SQL Server 2022 Developer holding its database, plus MSMQ.
  - `vm-dev01`: Windows 11 Enterprise with the developer tools for the modernization.
  - A private VNet with a NAT gateway for outbound traffic and Bastion Developer for access. Nothing is reachable from the internet.
- `scripts/Test-Datacenter.ps1` proves the datacenter is ready. Attendees run it at T-3.
- Azure Hybrid Benefit is on by default and documented, with how to turn it off.

## Before you start

1. B02 and B03 are closed, and `gh release view legacy-v1 --json assets -q '.assets[].name'` prints `ContosoUniversity-legacy.zip`.
2. `.local/settings.json` has `subscriptionId`, `location` and `memberIndex`.
3. `az group show -n rg-datacenter --subscription <subscriptionId>` fails with "not found". If the group exists, stop and ask.
4. With the values from `.local/settings.json`, `az vm list-skus -l <location> --size Standard_D8as_v6 --query "[0].restrictions[?type=='Location']"` prints `[]`. Restrictions of type `Zone` are fine: the VMs are non-zonal (backlog conventions, **Availability zones**). If the owner chose another size or region for this run, check that instead.

## Requirements

### Design (fixed)

1. Names and addresses follow the backlog conventions, with `n` = `memberIndex`:

   | Resource | Name | Notes |
   |---|---|---|
   | Resource group | `rg-datacenter` | In `location` |
   | VNet | `vnet-datacenter` | `10.10.n.0/24` |
   | Subnet | `snet-servers` | `10.10.n.0/25`, default outbound access **off**, NAT gateway and NSG attached |
   | NSG | `nsg-servers` | No inbound rules from the internet |
   | NAT gateway | `nat-datacenter` | Standard, no zone, with public IP `pip-nat-datacenter` (Standard, static, no `zones` set: it's zone-redundant automatically in regions with zones) |
   | Bastion | `bas-datacenter` | **Developer** SKU: free, no subnet or public IP, one session at a time |
   | App VM | `vm-app01` | Static private IP `10.10.n.4` |
   | Dev VM | `vm-dev01` | Static private IP `10.10.n.5` |

   Child resources use CAF prefixes with the VM name: `nic-vm-app01`, `osdisk-vm-app01`, `disk-data-vm-app01`, `nic-vm-dev01` and `osdisk-vm-dev01`.

2. Both VMs:
   - Size from the `vmSize` parameter, default `Standard_D8as_v6` (AMD, 8 vCPU, 32 GiB). Changing it to a v7 size or another size must need no other change.
   - Non-zonal: no `zones` on the VMs or their disks (backlog conventions, **Availability zones**).
   - Gen2 image, **Trusted Launch** (Secure Boot and vTPM on), disk controller left to the platform default for the size (NVMe on v6 and v7).
   - Admin user `labadmin`, with a generated password (backlog conventions, **Secrets**).
   - Boot diagnostics with managed storage. No public IP. No auto-shutdown.
   - No SQL IaaS Agent extension on `vm-app01`: it conflicts with Arc onboarding in B07.

   Disks, all Premium SSD (`Premium_LRS`):

   | VM | OS disk | Data disk |
   |---|---|---|
   | `vm-app01` | Image default size | One P30 (1,024 GiB), LUN 0, host caching `ReadOnly`, for SQL Server |
   | `vm-dev01` | Image default size (127 GiB), **performance tier P30** | None |

3. Images and licensing (backlog conventions, **Licensing**):

   | VM | Image (publisher:offer:sku:version) | `licenseType` |
   |---|---|---|
   | `vm-app01` | `MicrosoftSQLServer:sql2022-ws2022:sqldev-gen2:latest` | `Windows_Server` |
   | `vm-dev01` | `MicrosoftWindowsDesktop:windows-11:win11-25h2-ent:latest` | `Windows_Client` |

   - The Windows 11 SKU is a parameter (`devImageSku`, default `win11-25h2-ent`). 🔎 VERIFY with `az vm image list --publisher MicrosoftWindowsDesktop --offer windows-11 --sku win11-26h2-ent --all -l <location>`: if a 26H2 Enterprise version now exists, stop and ask whether to move the default. When this runbook was written, `win11-26h2-ent` was listed but had no versions.
   - AHB on `vm-app01` is controlled by a parameter that defaults to on. `vm-dev01` always uses `Windows_Client`: it's needed to run Windows 11 on Azure, not optional.

4. NSG rules: allow what Bastion Developer needs to reach RDP on both VMs, and nothing else inbound beyond the platform defaults. 🔎 VERIFY the required source and ports on [Bastion Developer](https://learn.microsoft.com/azure/bastion/quickstart-developer). Later items add rules for the hub (B08) and MI link (B07).

### Bicep

5. `infra/datacenter/main.bicep`, subscription scope: creates `rg-datacenter` and deploys the rest through modules in `infra/datacenter/modules/`. Parameters: `location`, `memberIndex` (1–20), `vmSize`, `devImageSku`, `enableHybridBenefit` (default `true`), `adminPassword` (secure), `sqlAppPassword` (secure), `scriptsBaseUrl`.
6. `infra/datacenter/main.bicepparam` holds the defaults, with no secrets.
7. Outputs: resource group name, both VM names and private IPs, and the Bastion name.
8. No Azure Verified Modules: plain resources keep the kit easy to read for infra attendees.

### In-VM configuration

9. Configuration runs as VM run commands (`Microsoft.Compute/virtualMachines/runCommands`) defined in Bicep. Each one downloads its script from `scriptsBaseUrl`, which points to raw files in this repo at a git ref (default `main`, so a PR branch can be tested by passing its name). Passwords go in `protectedParameters`, never in `parameters` or URLs.
10. Scripts live in `infra/datacenter/scripts/`, follow the in-VM script conventions (Windows PowerShell 5.1, idempotent, logs in `C:\LabTools\logs`), and never require a reboot to finish. If an installer returns 3010 (reboot required), log it and carry on.
11. **`vm-app01`**, in this order:
    1. Initialize the data disk as `F:` (GPT, NTFS, 64 KB allocation unit, label `SQLData`). Find it as the only raw disk, not by number: on NVMe sizes the numbering differs.
    2. SQL Server: default data, log and backup folders on `F:` (`F:\SQLData`, `F:\SQLLog`, `F:\SQLBackup`); mixed-mode authentication; TCP on port 1433; the **Always On availability groups** feature enabled; startup trace flags `-T1800` and `-T9567`; then restart the service. 🔎 VERIFY the MI link prerequisites on [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation).
    3. Create the empty database `ContosoUniversity` with its files on `F:`, and the SQL login `contosoapp` with the generated `sqlAppPassword`, as `db_owner` of that database.
    4. Windows features: IIS with ASP.NET 4.8, and the MSMQ server feature.
    5. Download `ContosoUniversity-legacy.zip` from the latest `legacy-v1` release of this repo and extract it to `C:\inetpub\ContosoUniversity`. Replace the Default Web Site with a site `ContosoUniversity` on port 80, in an app pool of the same name (.NET CLR v4.0, integrated pipeline, `ApplicationPoolIdentity`).
    6. In the deployed `Web.config` only, set `DefaultConnection` to `Server=10.10.n.4;Database=ContosoUniversity;User ID=contosoapp;Password=<sqlAppPassword>;MultipleActiveResultSets=True;TrustServerCertificate=True`. Leave everything else as it is: the plain-text password and `debug="true"` are deliberate findings.
    7. Create the private queue named by `NotificationQueuePath` in `Web.config` (expected `.\Private$\ContosoUniversityNotifications`), with full control for `IIS AppPool\ContosoUniversity`. Give the same identity Modify on `Uploads\TeachingMaterials`.
    8. Windows Firewall: allow inbound TCP 80 and 1433 from `10.0.0.0/8`.
    9. Warm up the app with a request to `http://localhost/` so `EnsureCreated()` builds the schema and seeds the data. It must return HTTP 200.
12. **`vm-dev01`**, in this order:
    1. Create `C:\src`. The dev VM has no data disk.
    2. Install machine-wide, silently, from the vendors' official download locations: Visual Studio Code (system installer), Git, the GitHub CLI, PowerShell 7, the Azure CLI, Bicep (standalone, on the machine `PATH`), the .NET 10 SDK, the .NET Framework 4.8 Developer Pack, Visual Studio Build Tools (current release) with the web build tools workload and its recommended components, NuGet CLI, and SSMS 22. 🔎 VERIFY the Build Tools workload ID on [Visual Studio Build Tools workload and component IDs](https://learn.microsoft.com/visualstudio/install/workload-component-id-vs-build-tools).
    3. Register a first-logon step for every user that installs these VS Code extensions: GitHub Copilot, GitHub Copilot Chat, GitHub Copilot app modernization for .NET (now two Marketplace extensions: GitHub Copilot modernization for .NET, `ms-dotnettools.vscode-dotnet-modernize`, and GitHub Copilot upgrade, `ms-dotnettools.upgrade-agent`; install both), C# Dev Kit, SQL Server (mssql), PowerShell and Bicep. VS Code extensions install per user, so they can't be installed by a run command running as SYSTEM. 🔎 VERIFY the extension IDs on the Visual Studio Marketplace, and the app modernization extension on [GitHub Copilot app modernization for .NET](https://learn.microsoft.com/dotnet/core/porting/github-copilot-app-modernization/overview).
    4. Write the installed versions to `C:\LabTools\versions.txt`.
13. Don't use winget: it isn't available to SYSTEM in a run command.

### Deploy script

14. `scripts/Deploy-Datacenter.ps1` follows the attendee script conventions. Parameters: `SubscriptionId` (mandatory), `MemberIndex` (1–20, default 1), `Location` (default `swedencentral`), `VmSize` (default `Standard_D8as_v6`), `DevImageSku` (default `win11-25h2-ent`), `ScriptsRef` (default `main`) and a `NoHybridBenefit` switch.
15. It generates `labadmin` and `contosoapp` passwords the first time and saves them in `$HOME/.apex-factory/<subscription-id>/datacenter.json`. A re-run reuses them and converges without changes.
16. Before deploying, it prints what it will deploy, the hourly cost from this runbook, and that AHB is on (or off with `-NoHybridBenefit`) and what that assumes. It doesn't check quota.
17. After deploying, it prints: how to connect with Bastion from the portal, where the passwords are saved, how to stop and start the VMs (`az vm deallocate` / `az vm start`), and how to turn AHB off (`az vm update -g rg-datacenter -n vm-app01 --license-type None`).

### Test script

18. `scripts/Test-Datacenter.ps1` (parameters `SubscriptionId`, `MemberIndex`) checks the live datacenter through `az vm run-command invoke` and reports PASS or FAIL per check, then an overall verdict and exit code:

    | On | Check |
    |---|---|
    | Azure | Both VMs running, with the expected size, `licenseType`, Trusted Launch, no zone and private IP. The disks match requirement 2: `vm-app01` has its P30 data disk, and `vm-dev01` has no data disk and its OS disk at performance tier P30. No public IPs in `rg-datacenter` apart from `pip-nat-datacenter` |
    | `vm-app01` | `http://localhost/` returns 200 and contains "Contoso University"; `F:` exists; SQL data files are on `F:`; `ContosoUniversity` has the app's tables and at least 8 students (the app's seed data); HADR is enabled; trace flags 1800 and 9567 are on; the MSMQ queue exists |
    | `vm-dev01` | `http://10.10.n.4/` returns 200; TCP 1433 on `10.10.n.4` is open; `git`, `gh`, `pwsh`, `az`, `bicep`, `dotnet` (SDK 10), `code`, `msbuild` and SSMS are installed; outbound HTTPS to `github.com` works |

### Documentation

19. `infra/datacenter/README.md`: what the datacenter simulates, a diagram (Mermaid), the resource table, how to deploy and test it, the cost with and without AHB, running and stopped, a clear **Azure Hybrid Benefit** section (what's on by default, the licence assumption, how to turn it off per VM after deployment, and `-NoHybridBenefit`), and the known traps from this runbook that affect attendees.
20. `versions.md`: rows for the two images (with the image version the validation deployed), SQL Server 2022 Developer, VS Build Tools, SSMS, the .NET 10 SDK and Bicep, validated today.

### Validate for real

21. Run the static checks, then deploy with `scripts/Deploy-Datacenter.ps1 -ScriptsRef <this branch>` into the workload subscription (AGENTS.md §3). Record the wall-clock time.
22. Run `scripts/Test-Datacenter.ps1`. Every check passes.
23. Run the deploy script a second time. It completes without errors and without replacing either VM.
24. 🧑 HUMAN: the owner connects to `vm-dev01` through Bastion, signs in as `labadmin`, opens VS Code, confirms the extensions installed at first logon, and browses to `http://10.10.n.4/`. The owner reports what they see.
25. Keep `rg-datacenter` running for B05. Put the stop command in the PR body, so the owner can deallocate the VMs between items.

## Deliverables

- `infra/datacenter/main.bicep`, `infra/datacenter/main.bicepparam`, `infra/datacenter/modules/*.bicep`.
- `infra/datacenter/scripts/*.ps1` (in-VM scripts for `vm-app01` and `vm-dev01`).
- `infra/datacenter/README.md`.
- `scripts/Deploy-Datacenter.ps1`, `scripts/Test-Datacenter.ps1`.
- `versions.md` updated.

## Verify

```powershell
az bicep build --file infra/datacenter/main.bicep --stdout | Out-Null
az bicep lint --file infra/datacenter/main.bicep
'scripts', 'infra/datacenter/scripts' | ForEach-Object { Invoke-ScriptAnalyzer -Path $_ -Recurse }
$s = Get-Content .local/settings.json | ConvertFrom-Json
./scripts/Test-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex; $LASTEXITCODE
npm run check
```

- Build and lint print no warnings. PSScriptAnalyzer prints nothing.
- The test script passes every check and exits `0`.
- The PR body has: deploy wall-clock time, test output (IDs replaced with placeholders), the second-run result, the owner's Bastion check and the cost so far.

## Done when

- [ ] The datacenter deploys unattended in under 60 minutes with one command, and a re-run converges.
- [ ] Every Test-Datacenter check passes.
- [ ] AHB is on by default and documented, with the off switch.
- [ ] The owner confirmed the dev VM experience through Bastion.
- [ ] `rg-datacenter` is still deployed, for B05.

## Commit message

```text
feat: add the datacenter kit
```

## Stop and ask if

- A 26H2 Enterprise image version exists (requirement 3).
- Any 🔎 VERIFY page contradicts this runbook.
- The deployment takes more than 60 minutes, or a VM needs a reboot to finish its configuration.
- The app returns an error page after warm-up.

## Notes and traps

- **NVMe disks:** v6 and v7 sizes are NVMe-only and Gen2-only. Disk numbers inside Windows don't match LUNs, so find the data disk on `vm-app01` by being the only raw disk.
- **OS disk performance tier:** the VM's `osDisk` block has no performance tier property, so `vm-dev01`'s P30 tier is set on the disk itself. 🔎 VERIFY how on [Change the performance tier of a managed disk](https://learn.microsoft.com/azure/virtual-machines/disks-change-performance), including whether the tier can change while the VM runs, and keep the re-run converging.
- **Trusted Launch and NVMe** are both supported by the SQL 2022 and Windows 11 images used here. If you change an image, check both.
- **No default outbound access:** the subnet has default outbound access off, so all outbound traffic goes through the NAT gateway. Without the NAT gateway, downloads in the run commands fail.
- **Run command limits:** long installs (Build Tools, SSMS) can take 20+ minutes. Set each run command's timeout accordingly and split long work into separate run commands so one failure is easy to spot. 🔎 VERIFY the timeout limit on [Managed run commands](https://learn.microsoft.com/azure/virtual-machines/windows/run-command-managed).
- **Run commands re-run only when they change:** Azure doesn't re-execute a managed run command whose properties are unchanged, so a re-deploy would return the old results and never converge. `main.bicep` has a `configRunId` parameter (default `utcNow()`) that it passes to every run command as a plain `RunId` parameter, so every deployment re-runs them all. The scripts log it and skip finished work.
- **Arc comes later:** B07 onboards `vm-app01` to Arc with the Jumpstart pattern, which turns off the Azure guest agent and blocks IMDS. After that, run commands stop working. Everything that needs a run command belongs here, before Arc.
- **Always On without a cluster:** SQL Server 2022 lets you enable the availability groups feature without a Windows failover cluster, which is all MI link needs.
- **Connection string by IP:** the app and later tools use `10.10.n.4`, not the VM name, because name resolution changes once the datacenter uses the hub's DNS.
- **Bastion Developer** allows one session at a time per user, and doesn't work across peering. That's fine: both VMs are in its own VNet. 🔎 VERIFY it's offered in `germanywestcentral` before documenting the fallback region as supported.
- **Windows 11 licensing:** `Windows_Client` declares multitenant hosting rights. Compute is billed at the Linux rate.
