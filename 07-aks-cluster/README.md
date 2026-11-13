# 07 - AKS cluster

A production-shaped Azure Kubernetes Service cluster.

## What it builds
- VNet and node subnet
- AKS cluster with:
  - **System node pool** and separate **user node pool**, both with cluster autoscaler
  - **Azure CNI Overlay with Cilium** data plane and network policy
  - **Entra ID integration with Azure RBAC** for Kubernetes authorisation
  - Optional API server authorised IP ranges
  - **Container Insights** sending to a Log Analytics workspace
- `ignore_changes` on node counts so Terraform doesn't fight the autoscaler

## Problems solved
- Regional **vCPU quota** limits in UK South
- **VM size availability** errors when choosing node sizes

## Usage
Copy `terraform.tfvars.example` to `terraform.tfvars` and set `subscription_id`.
