# Private-endpoint probe from `vm-dev01`

Run on 2026-09-25 at 08:46 (UTC+2) with `az vm run-command invoke` on `vm-dev01`, right after the spike resources deployed. Each hostname must resolve to `snet-pe-spike` (`10.10.1.128/27`) and connect on TCP 443, plus 5671 (AMQP) for Service Bus. The ACR data endpoint is included because image pushes use it.

| Hostname | Private IP | In `snet-pe-spike` | Port | Connects |
|---|---|---|---|---|
| `stuni<suffix>b06.blob.core.windows.net` | `10.10.1.136` | ✅ | 443 | ✅ |
| `sbns-uni-<suffix>-b06.servicebus.windows.net` | `10.10.1.135` | ✅ | 443 | ✅ |
| `sbns-uni-<suffix>-b06.servicebus.windows.net` | `10.10.1.135` | ✅ | 5671 | ✅ |
| `cruni<suffix>b06.azurecr.io` | `10.10.1.134` | ✅ | 443 | ✅ |
| `cruni<suffix>b06.swedencentral.data.azurecr.io` | `10.10.1.133` | ✅ | 443 | ✅ |
| `kv-uni-<suffix>-b06.vault.azure.net` | `10.10.1.132` | ✅ | 443 | ✅ |

Deployed settings, checked with `az`:

- Storage: `Standard_LRS`, public network access `Disabled`, shared key access off, no zones.
- Service Bus: Premium, 1 MU, public network access `Disabled`, local auth off, zone-redundant automatically (not set by the template).
- ACR: Premium, public network access `Disabled`, admin user off, no zone setting.
- Key Vault: RBAC authorization, public network access `Disabled`, soft delete on, purge protection off.
- Private DNS zones: all four in `rg-spike-b06`, each with one link to `vnet-datacenter`. All four private endpoints are `Approved`.
- Owner roles: Storage Blob Data Contributor, Azure Service Bus Data Sender and Receiver, AcrPush, Key Vault Secrets Officer.
