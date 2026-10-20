---
title: Availability zones
description: Nothing pinned or turned on; which services are zone-redundant automatically.
sidebar:
  order: 3
---

The kit never pins an availability zone and never explicitly turns on zone redundancy for any resource. This is deliberate: a two-day lab event doesn't need the added complexity or cost of a zone-resilient design, and the kit's compliance rules forbid pinning zones at all.

## Automatic zone redundancy

Some services the kit deploys are zone-redundant by default, with no configuration from the kit:

- Azure Container Registry (Premium SKU) replicates automatically within a region's availability zones.
- Azure Service Bus (Premium SKU) is zone-redundant by default in regions that support it.
- Public IP addresses created as Standard SKU are zone-redundant by default unless a specific zone is requested (the kit never requests one).

This is the platform's own default behavior, not a setting the kit turns on. The kit leaves zones alone on purpose, so you don't need to configure anything for them in this event.

## Where to go next

See [Cost](../cost/) for what the deployment costs.
