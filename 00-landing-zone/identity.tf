# RBAC at management group scope - assign to Entra ID groups, not individuals.
#
# Example in terraform.tfvars:
# rbac_assignments = {
#   platform-owners = { management_group = "platform", role = "Owner",       principal_id = "<group-object-id>" }
#   lz-contributors = { management_group = "corp",     role = "Contributor", principal_id = "<group-object-id>" }
#   all-readers     = { management_group = "root",     role = "Reader",      principal_id = "<group-object-id>" }
# }

resource "azurerm_role_assignment" "mg" {
  for_each = var.rbac_assignments

  scope                = local.mg_ids[each.value.management_group]
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}
