---
title: Availability zones
description: Nothing pinned or turned on; which services are zone-redundant automatically.
sidebar:
  order: 6
---

The kit never pins an availability zone and never explicitly turns on zone redundancy for any resource. This is deliberate: a two-day lab event doesn't need the added complexity or cost of a zone-resilient design, and the kit's compliance rules forbid pinning zones at all.

## Automatic zone redundancy

Some services the kit deploys are zone-redundant by default, with no configuration from the kit:

- Azure Container Registry is zone-redundant automatically across all tiers in supported regions.
- Azure Service Bus is zone-redundant automatically across all tiers in supported regions.
- New Azure Firewall deployments are zone-redundant automatically in supported regions. Existing firewalls without zone redundancy are being migrated during 2026.
- Public IP addresses created as Standard SKU are zone-redundant by default unless a specific zone is requested (the kit never requests one).

This is the platform's own default behavior, not a setting the kit turns on. The kit leaves zones alone on purpose, so you don't need to configure anything for them in this event.

**Checked against Microsoft Learn on 2026-10-30:** [Container Registry](https://learn.microsoft.com/azure/container-registry/zone-redundancy), [Service Bus](https://learn.microsoft.com/azure/reliability/reliability-service-bus), [Azure Firewall](https://learn.microsoft.com/azure/reliability/reliability-firewall), and [Public IP addresses](https://learn.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku).

## Where to go next

See [Cost](../cost/) for what the deployment costs.
