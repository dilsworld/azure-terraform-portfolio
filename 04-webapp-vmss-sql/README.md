# 04 - Three-tier web platform

A web tier on a VM Scale Set behind a Standard Load Balancer, with an Azure SQL
database reachable only over a Private Endpoint.

## What it builds
- **Network:** VNet with separate `web` and `data` subnets, each with its own NSG
- **Web tier:** Standard public Load Balancer, health probe and HTTP rule in front of
  a Linux VMSS (bootstrapped with cloud-init), autoscaling on CPU
- **Data tier:** Azure SQL server and database, **Private Endpoint** in the data subnet
- **Secrets:** SQL admin password generated with `random_password` and stored in
  **Key Vault**, never written in code
- **Monitoring:** Log Analytics workspace with diagnostic settings for SQL and the LB

## Design decisions
- Database is not exposed publicly; the web tier reaches it privately
- Tiers are split by subnet so NSGs can enforce web -> data only
- Files split by concern (network, compute, database, security, monitoring) as a
  step towards modules (see project 05)
