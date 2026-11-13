# Azure Terraform Portfolio

Hands-on Azure infrastructure built with Terraform, progressing from a single VM
to modular multi-environment platforms, hub-and-spoke networking, AKS and hybrid
monitoring with Azure Arc. Built in my own Azure subscription (UK South).

| # | Project | What it demonstrates |
|---|---|---|
| 01 | [Single VM](01-vm-single) | Core building blocks: RG, VNet, subnet, NSG, public IP, Linux VM |
| 02 | [Multiple VMs with for_each](02-vm-multi-foreach) | Refactoring repeated resources into a map-driven `for_each` |
| 03 | [VM Scale Set with autoscale](03-vmss-autoscale) | VMSS, CPU-based scale-out/scale-in rules |
| 04 | [Three-tier web platform](04-webapp-vmss-sql) | Load balancer, VMSS, Azure SQL via Private Endpoint, Key Vault, Log Analytics |
| 05 | [Same platform as modules](05-webapp-vmss-sql-modules) | Reusable modules, separate prod/test deployments, remote state |
| 06 | [Hub-and-spoke with Bastion](06-hub-spoke-bastion) | Hub VNet, peered spokes, Azure Bastion, NSGs allowing SSH only from Bastion |
| 07 | [AKS cluster](07-aks-cluster) | System/user node pools, autoscaling, Azure CNI Overlay + Cilium, Entra ID RBAC, Container Insights |
| 08 | [Azure Arc monitoring](08-arc-monitoring) | Arc-enabled on-prem server, Azure Monitor Agent, Data Collection Rule to Log Analytics |
| 09 | [Persistent web + CI/CD](https://github.com/dilsworld/azure-web-persistent) *(separate repo)* | Stateful/stateless layer split, remote state, GitHub Actions with OIDC (no stored secrets) |

## Practices used throughout

- **No secrets in code:** SSH keys only; generated passwords stored in Key Vault;
  state and `tfvars` files excluded from Git
- **Least exposure:** SSH limited to a single /32 or to the Bastion subnet only
- **Pinned providers** and committed lock files for repeatable builds
- **Destroy after use:** every lab is torn down when finished to control cost

## Running any project

```bash
az login
cd <project>
cp terraform.tfvars.example terraform.tfvars   # where provided; add subscription_id etc.
terraform init
terraform plan
terraform apply
terraform destroy
```
