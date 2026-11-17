# ---------- Core ----------

variable "org_prefix" {
  description = "Short prefix for the management group hierarchy and resource names (lowercase, no spaces)."
  type        = string
  default     = "alz"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.org_prefix))
    error_message = "org_prefix must be 2-8 lowercase letters or digits."
  }
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "uksouth"
}

variable "allowed_locations" {
  description = "Regions permitted by the Allowed Locations policy."
  type        = list(string)
  default     = ["uksouth", "ukwest"]
}

variable "default_tags" {
  description = "Tags applied to every resource this configuration creates."
  type        = map(string)
  default = {
    managed_by  = "terraform"
    environment = "lab"
    owner       = "platform-team"
  }
}

# ---------- Subscriptions ----------

variable "management_subscription_id" {
  description = "Subscription for management resources (Log Analytics etc.)."
  type        = string
}

variable "connectivity_subscription_id" {
  description = "Subscription for the hub network. Null = use management subscription."
  type        = string
  default     = null
}

variable "landingzone_subscription_id" {
  description = "Subscription for spoke networks. Null = use management subscription."
  type        = string
  default     = null
}

variable "subscription_placement" {
  description = <<-EOT
    Map of subscription ID => management group key to move it under.
    Valid keys: platform, management, connectivity, identity, corp, online, sandbox, decommissioned.
    Leave empty to create the hierarchy without moving any subscriptions.
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for mg in values(var.subscription_placement) :
      contains(["platform", "management", "connectivity", "identity", "corp", "online", "sandbox", "decommissioned"], mg)
    ])
    error_message = "subscription_placement values must be a valid management group key."
  }
}

# ---------- Policy ----------

variable "policy_enforce" {
  description = "true = Deny effects are enforced. false = DoNotEnforce (audit-only, safe for first runs)."
  type        = bool
  default     = false
}

variable "required_tag_name" {
  description = "Tag that must exist on resources inside landing zones."
  type        = string
  default     = "owner"
}

# ---------- Management ----------

variable "log_retention_days" {
  description = "Log Analytics retention (30 days is included in the base price)."
  type        = number
  default     = 30
}

variable "enable_defender" {
  description = "Enable Defender for Cloud paid plans on the management subscription (costs money)."
  type        = bool
  default     = false
}

# ---------- Connectivity ----------

variable "hub_address_space" {
  description = "Hub VNet address space."
  type        = string
  default     = "10.0.0.0/22"
}

variable "deploy_firewall" {
  description = "Deploy Azure Firewall Basic in the hub (roughly £250+/month - destroy after labbing)."
  type        = bool
  default     = false
}

variable "private_dns_zones" {
  description = "Private DNS zones for Private Endpoints, linked to the hub."
  type        = list(string)
  default = [
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.database.windows.net",
  ]
}

variable "spokes" {
  description = "Spoke VNets peered to the hub."
  type = map(object({
    address_space = string
    subnets       = map(string) # subnet name => CIDR
  }))
  default = {
    corp-app1 = {
      address_space = "10.1.0.0/24"
      subnets = {
        snet-web  = "10.1.0.0/26"
        snet-app  = "10.1.0.64/26"
        snet-data = "10.1.0.128/26"
      }
    }
  }
}

# ---------- Identity / RBAC ----------

variable "rbac_assignments" {
  description = <<-EOT
    Role assignments at management group scope.
    Key is any unique label. principal_id is an Entra ID group/user/SP object ID.
  EOT
  type = map(object({
    management_group = string # MG key, e.g. "platform"
    role             = string # built-in role name, e.g. "Reader"
    principal_id     = string
  }))
  default = {}
}
