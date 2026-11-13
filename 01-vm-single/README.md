# 01 - Single Linux VM

The baseline: everything needed to run one Ubuntu VM in Azure, written by hand
to learn how the pieces fit together.

## What it builds
- Resource group, VNet and subnet
- Network security group associated with the NIC
- Public IP, network interface and Linux VM (SSH key authentication)

## What it taught me
How Azure networking objects relate: the VM attaches to a NIC, the NIC sits in a
subnet and carries the public IP, and the NSG controls what reaches it.

## Deployment
Deployed by GitHub Actions (`.github/workflows/terraform-01-vm-single.yml`):
a pull request runs `fmt`, `validate` and `plan` and posts the plan as a comment;
merging to `main` applies after approval; a manual run from the Actions tab can
destroy it. State is stored remotely in Azure Storage, and the pipeline logs in to
Azure with OIDC, so no credentials are stored in GitHub. SSH is closed unless
`ssh_source_cidr` is set.
