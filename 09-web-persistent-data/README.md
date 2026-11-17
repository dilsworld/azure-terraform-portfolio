# 09 - Web server with persistent data, remote state and CI/CD

Destroy and redeploy the web server as often as you like. The site content
and public IP survive in a separate layer. State lives in Azure Storage, and
the web layer deploys from GitHub Actions using OIDC (no stored secrets).

```
bootstrap/    run once, locally   -> state storage account + GitHub OIDC identity
persistent/   run once, locally   -> data disk, static IP, delete lock
web/          pipeline-managed    -> VNet, NSG, VM, disk attachment, cloud-init
.github/workflows/terraform-web.yml
```

| Layer | State | Who runs it |
|---|---|---|
| bootstrap | local (it creates the state storage) | you, once |
| persistent | Azure Storage | you - it creates a resource lock, which needs Owner |
| web | Azure Storage | GitHub Actions (or you) |

## 1. Bootstrap (once)

Check `github_repo` in `bootstrap/terraform.tfvars` matches the repo you will push to.

```bash
cd bootstrap
terraform init
terraform apply
terraform output
```

This creates the state storage account, writes `backend.hcl` into `persistent/`
and `web/`, and creates the `gha-lab-terraform` app registration trusted by your repo.
Wait 2-3 minutes for the role assignments to apply before the next step.

## 2. Persistent layer (once)

```bash
cd ../persistent
terraform init -backend-config=backend.hcl
terraform apply
```

Already applied with local state? Use `terraform init -migrate-state -backend-config=backend.hcl`
and answer yes to copy it up.

## 3. GitHub setup

1. Create the repo (default name: `dilsworld/azure-web-persistent`) and push this folder:
   ```bash
   cd ..            # the 09 folder
   terraform -chdir=web fmt -recursive
   git init -b main && git add . && git commit -m "Initial commit"
   git remote add origin https://github.com/dilsworld/azure-web-persistent.git
   git push -u origin main
   ```
2. **Settings > Secrets and variables > Actions > Secrets**: add `AZURE_CLIENT_ID`,
   `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` from the bootstrap outputs.
3. **Variables** tab: add `SSH_PUBLIC_KEY` = contents of `~/.ssh/id_ed25519.pub`.
4. **Settings > Environments**: create `production` and add yourself as a required reviewer.

## 4. Use it

- **Change something in `web/` on a branch, open a PR**: the pipeline runs fmt, validate
  and plan, and posts the plan as a PR comment.
- **Merge to main**: apply runs after you approve it.
- **Actions tab > terraform-web > Run workflow**: apply or destroy the web layer on demand.

## Prove persistence

1. Open `http://<ip>/rebuilds.txt` - one line.
2. Run the workflow with **destroy**, then **apply**.
3. Same IP, same "first created" date, and a second line in `rebuilds.txt`.

## How it works

- `web/` finds the disk and IP with `data` sources by name (shared `prefix`).
- Cloud-init waits for the disk, formats it **only if it has no filesystem**,
  mounts it at `/var/www` and installs nginx. Log: `/var/log/webdata-setup.log`
- State has blob versioning on, so previous state versions can be restored.
- The pipeline logs in with a short-lived GitHub token that Entra ID trusts only for
  this repo's PRs, main branch and `production` environment.

## Security notes / production hardening

- The pipeline identity has Contributor on the subscription (fine for a lab).
  In production, scope it to the resource groups it manages.
- Disable shared key access on the state storage account and use Entra ID only.
- Add a private endpoint to the state storage account.

## Costs and clean-up

Persistent layer + state storage: a few pounds a month. Destroy `web/` when idle.

To remove everything: destroy `web/`, then in `persistent/` set
`prevent_destroy = false` on both resources and run `terraform destroy`
(Terraform removes the lock first), then `terraform destroy` in `bootstrap/`.
