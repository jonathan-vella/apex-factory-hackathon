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

This is the platform's own default behavior, not a setting the kit turns on — don't add explicit zone configuration to any Bicep template in this kit, even to "make it more resilient." If a future requirement needs zone pinning, that's an explicit owner decision, not something to add silently.
