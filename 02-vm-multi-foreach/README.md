# 02 - Multiple VMs with for_each

Deploys several Ubuntu 22.04 VMs from a single map in `locals`, each with its own
public IP, NIC and NSG.

## What it builds
- Resource group, VNet and subnet
- One VM, NIC, public IP and NSG per entry in `local.vms`
- SSH allowed only from a single trusted /32 address

## Design decisions
- **for_each over a map, not count:** adding or removing a VM only touches that VM;
  with `count`, removing one from the middle forces others to be rebuilt
- **SSH keys only:** password authentication disabled
- **Standard SKU public IPs:** closed by default until an NSG allows traffic

## Usage
Create `terraform.tfvars` with `my_ip = "<your-ip>/32"`, then init, plan, apply.
