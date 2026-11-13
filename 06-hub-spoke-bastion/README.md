# 06 - Hub-and-spoke with Azure Bastion

A hub VNet holding shared services, with two peered spoke VNets for workloads.
Admin access is through Azure Bastion only.

## What it builds
- **Hub VNet** with `AzureBastionSubnet` and an Azure Bastion host
- **Two spoke VNets** (defined in a `locals` map, built with `for_each`), each with a
  workload subnet and a Linux VM with no public IP
- **Bidirectional VNet peering** hub <-> each spoke
- **NSGs** on workload subnets allowing SSH only from the Bastion subnet

## Design decisions
- Shared services live once in the hub; workloads stay isolated in spokes
- No public IPs on workload VMs, so Bastion is the only management path
- Adding a spoke is one new entry in the map

## Next step
Add Azure Firewall to the hub with route tables forcing spoke traffic through it.
