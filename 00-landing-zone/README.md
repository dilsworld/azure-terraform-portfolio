# 00 - Azure Landing Zone

A Cloud Adoption Framework-style landing zone built from plain `azurerm` resources. It's small enough to read end to end, and it runs in a single lab subscription or across separate platform and workload subscriptions. This is the **platform layer** that the other labs can deploy into.

## What it builds

| Area | Resources | File |
|---|---|---|
| **Hierarchy** | Intermediate root MG → Platform (Management / Connectivity / Identity), Landing Zones (Corp / Online), Sandbox, Decommissioned. Optional subscription placement. | `management-groups.tf` |
| **Governance** | Built-in policies: allowed locations (resources and RGs) at root, required `owner` tag on Landing Zones, no public IPs on NICs in Corp. Starts in audit mode. | `policy.tf` |
| **Management** | Central Log Analytics workspace, Activity Log → workspace, optional Defender for Cloud plans | `management.tf` |
| **Connectivity** | Hub VNet 10.0.0.0/22 (Firewall, Firewall-Mgmt, Gateway, Bastion, shared subnets), optional Azure Firewall Basic + policy, Private DNS zones for Private Endpoints | `connectivity.tf` |
| **Spokes** | Spoke VNets from a map, subnets + NSGs, two-way hub peering, DNS zone links, a 0.0.0.0/0 route via the firewall when it's deployed | `spokes.tf` |
| **Identity** | RBAC role assignments to Entra groups at MG scope | `identity.tf` |

## Costs (UK South)

With the defaults, cost is close to zero. Management groups, policy, VNets, peering, NSGs and DNS zones cost nothing or pennies. Log Analytics costs very little at lab volumes.

| Toggle | Rough cost | Advice |
|---|---|---|
| `deploy_firewall = true` | Firewall Basic + 2 public IPs ≈ £250+/month | Turn on to lab it, then destroy the same day |
| `enable_defender = true` | Per-resource billing | Lab only briefly |

## Prerequisites

Unlike the other labs, this one works **above subscription level**, so whoever runs it needs rights at the **Tenant Root Group**:

- **You (local runs):** Entra ID → Properties → *Access management for Azure resources* = Yes, then assign yourself Owner at the Tenant Root Group.
- **GitHub Actions identity:** assign the OIDC app Owner at the Tenant Root Group, or the narrower trio of Management Group Contributor, Resource Policy Contributor and User Access Administrator.

```bash
az role assignment create --assignee <AZURE_CLIENT_ID> --role Owner \
  --scope /providers/Microsoft.Management/managementGroups/<TENANT_ID>
```

## Running

```bash
az login
cd 00-landing-zone
cp terraform.tfvars.example terraform.tfvars   # add management_subscription_id
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
terraform destroy
```

From GitHub: `.github/workflows/terraform-00-landing-zone.yml` follows the same plan-on-PR / apply-on-merge / manual-destroy pattern as lab 01.

## Rolling out policy safely

1. Apply with `policy_enforce = false` (the default).
2. Check **Policy → Compliance** in the portal.
3. Fix or exempt anything non-compliant, then set `policy_enforce = true`.

## Deploying the other labs on top

Each lab keeps its own state. To drop a lab's VMs into a landing zone spoke, read this lab's outputs:

```hcl
data "terraform_remote_state" "lz" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-lab-tfstate"
    storage_account_name = "sttfstate4dfd6h"
    container_name       = "tfstate"
    key                  = "portfolio/00-landing-zone.tfstate"
    use_azuread_auth     = true
  }
}

# e.g. in a NIC:
subnet_id = data.terraform_remote_state.lz.outputs.spoke_subnet_ids["corp-app1/snet-app"]
```

Once policy is **enforced** and your subscription is placed under **Corp**, these rules apply:

- **Every resource needs an `owner` tag.**
- **No public IPs on NICs.** Labs 01 and 02 attach public IPs to VM NICs, so they'll be denied. Lab 03 gives scale set instances public IPs, which breaks the same Corp rule even though this built-in policy may not catch scale sets. Lab 04's load balancer public IP is fine. Either deploy those labs into a subscription under **Online** or **Sandbox**, or switch them to Bastion access (as lab 06 does).
- **UK South / UK West only.**
- Lab 06 also uses 10.0.0.0/16 for its hub. If you ever peer it with this landing zone, change one of the ranges.

## Interview talking points

- Why management groups rather than per-subscription policy: inheritance, and one place for guardrails.
- Corp vs Online landing zones, and why Corp denies public IPs.
- Hub-and-spoke vs Virtual WAN trade-offs.
- Central Private DNS zones in the hub, linked to spokes, so Private Endpoint resolution works everywhere.
- Rolling out policy in audit mode before enforcing it.
- Platform state is kept separate from workload state.
- How this compares with the official ALZ accelerator / Azure Verified Modules (`avm-ptn-alz`): this is a hand-built, readable equivalent of the core.
