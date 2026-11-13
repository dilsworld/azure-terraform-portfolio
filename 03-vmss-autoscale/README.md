# 03 - VM Scale Set with autoscale

A Linux Virtual Machine Scale Set that adds and removes instances based on CPU.

## What it builds
- Resource group, VNet, subnet and NSG
- Linux VM Scale Set
- `azurerm_monitor_autoscale_setting` with paired rules:
  - scale **out** when average CPU is above 90%
  - scale **in** when average CPU is below 10%

## Why it matters
Scale-out and scale-in rules must be paired with sensible thresholds and cooldowns,
otherwise the set "flaps" between sizes. Limits are kept small (1-2 instances)
to control lab cost.
