module "network" {
  source             = "../../../modules/network"
  project_name       = var.project_name
  location           = var.location
  vnet_address_space = ["10.2.0.0/16"]
  web_subnet_prefix  = ["10.2.1.0/24"]
  data_subnet_prefix = ["10.2.2.0/24"]
}

module "security" {
  source              = "../../../modules/security"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.network.resource_group_name
  web_subnet_id       = module.network.web_subnet_id
  data_subnet_id      = module.network.data_subnet_id
}

module "loadbalancer" {
  source              = "../../../modules/loadbalancer"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.network.resource_group_name
}

module "compute" {
  source              = "../../../modules/compute"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.network.resource_group_name
  web_subnet_id       = module.network.web_subnet_id
  backend_pool_id     = module.loadbalancer.lb_backend_address_pool_id
  vm_size             = var.vm_size
  vmss_instance_count = var.vmss_instance_count
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
}

module "database" {
  source              = "../../../modules/database"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.network.resource_group_name
  data_subnet_id      = module.network.data_subnet_id
  sql_admin_username  = var.sql_admin_username
  random_suffix       = random_string.suffix.result
}

module "keyvault" {
  source              = "../../../modules/keyvault"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.network.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  vmss_principal_id   = module.compute.vmss_principal_id
  sql_admin_password  = module.database.sql_admin_password
  random_suffix       = random_string.suffix.result
}

module "monitoring" {
  source              = "../../../modules/monitoring"
  project_name        = var.project_name
  location            = var.location
  resource_group_name = module.network.resource_group_name
  load_balancer_id    = module.loadbalancer.lb_id
  database_id         = module.database.database_id
}