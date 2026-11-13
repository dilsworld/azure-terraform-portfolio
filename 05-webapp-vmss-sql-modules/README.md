# 05 - Three-tier platform as reusable modules

Project 04 refactored into modules, deployed twice (prod and test) from the same code.

## Structure
```
modules/
  network/  security/  compute/  loadbalancer/  database/  keyvault/  monitoring/
deployments/project1/
  prod/   -> 10.1.0.0/16, 2 web instances
  test/   -> 10.2.0.0/16, 1 web instance
```

## Design decisions
- **One set of modules, many environments:** prod and test differ only in variables
  (name, address space, instance count), so they cannot drift apart
- **Remote state:** each environment uses the `azurerm` backend with its own state
  key (`prod.hcl` / `test.hcl`), keeping environments isolated
- **Secrets flow:** the database module generates the password (marked `sensitive`)
  and passes it to the Key Vault module

## Usage
```bash
cd deployments/project1/test
terraform init -backend-config=test.hcl
terraform apply
```
