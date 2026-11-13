# 01 - Single Linux VM

The baseline: everything needed to run one Ubuntu VM in Azure, written by hand
to learn how the pieces fit together.

## What it builds
- Resource group, VNet and subnet
- Network security group associated with the NIC
- Public IP, network interface and Linux VM (SSH key authentication)

## What it taught me
How Azure networking objects relate: the VM attaches to a NIC, the NIC sits in a
subnet and carries the public IP, and the NSG controls what reaches it.
