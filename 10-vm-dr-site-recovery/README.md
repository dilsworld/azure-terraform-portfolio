# 10 - VM disaster recovery with Azure Site Recovery

Protects a Linux web server in **UK South** by continuously replicating it to **UK West** with Azure Site Recovery (ASR), then proves recovery with a **test failover** into an isolated network.

## What it builds

| Component | Region | Purpose |
|---|---|---|
| `vm-dr-app01` + VNet 10.20.0.0/24 | UK South | The "production" server. nginx shows which region it's running in. |
| Recovery Services vault `rsv-dr-ukwest` | UK West | DR control plane. It lives in the target region so it survives a primary outage. |
| Fabrics, protection containers, container mapping | both | ASR's model of "this region protects to that region" |
| Replication policy | - | Keeps 24h of recovery points, app-consistent every 4h (crash-consistent every 5 min is automatic) |
| Cache storage account | UK South | Staging area where disk changes land before being shipped across |
| Recovery VNet 10.21.0.0/24 + network mapping | UK West | Where the VM lands in a **real** failover, at 10.21.0.10 |
| Test VNet 10.22.0.0/24 (isolated) | UK West | Where the VM lands in a **test** failover, at 10.22.0.10, with no route to production |

## DR concepts it demonstrates

- **RPO** (how much data you can lose): crash-consistent recovery points every 5 minutes, app-consistent every 4 hours.
- **RTO** (how fast you're back): measure it yourself by timing a test failover from start to "nginx answers".
- **Network mapping and IP planning:** the VM gets a predictable address in each scenario (see `terraform output ip_plan`).
- **Non-disruptive DR testing:** a test failover runs in an isolated VNet while production keeps running.
- **Vault in the target region:** the DR tooling doesn't fail with the site it protects.

## Running

```bash
az login
cd 10-vm-dr-site-recovery
terraform init -backend-config=backend.hcl
terraform plan
terraform apply      # 15-30 minutes: initial replication of the disk takes a while
```

Replication carries on after `apply` finishes. In the portal, go to **Recovery Services vault → Replicated items** and wait until the VM shows **Protected** with a healthy replication status.

## Test failover (the actual DR test)

1. Check the primary is working: **vm-dr-app01 → Serial console**, log in, then `curl -s localhost`. It shows **uksouth**.
2. **Vault → Replicated items → vm-dr-app01-replica → Test failover**
   - Recovery point: *Latest processed*
   - Azure virtual network: `vnet-dr-test`
3. When the job completes, open the new `vm-dr-app01-test` VM in `rg-dr-secondary-ukwest` → **Serial console** → `curl -s localhost`. It shows **ukwest**.
4. Note how long steps 2–3 took. That's your measured RTO.
5. **Replicated item → Cleanup test failover.** Tick "testing complete" and add notes. This deletes the test VM.

> Always clean up the test failover before running `terraform destroy`. Otherwise the test VM is left behind in the secondary resource group.

A real failover (**Failover**, then **Commit**, then **Re-protect** to replicate back) also works from the same menu. After that, Terraform's state no longer matches reality, so just `destroy` and re-apply for the next run.

## Cost

- **Site Recovery licence:** free for the first 31 days of protection per VM, so a lab torn down the same day costs nothing for ASR itself.
- **Charged while running:** the B2s_v2 VM, its disk, the replica disk and snapshots in UK West, the cache storage account, and a small amount of cross-region data transfer. Roughly **£1–1.50 a day**.
- A test failover adds a second VM for as long as it runs.

Destroy after use:

```bash
terraform destroy    # 10-20 minutes; disabling replication is slow
```

## Fit with the landing zone (lab 00)

All resources are tagged with `owner` and stay in UK South / UK West, so they pass the landing zone policies. The VM has no public IP, so it's also fine under the Corp "no public IPs on NICs" rule. It uses its own 10.20–10.22 ranges, so it won't clash with the landing zone spokes.

## Interview talking points

- Same model as on-prem DR (VMware SRM, SAN replication), with the second site replaced by a second Azure region.
- Why the vault lives in the DR region.
- Test failover into an isolated network vs a real failover, and why you test regularly.
- RPO/RTO: what ASR gives you, and how you measured RTO.
- What ASR doesn't do on its own: DNS cutover, app dependencies, and the order servers come up in (that's what **Recovery Plans** are for).
- What would change for production: recovery plans with scripts, a failover-ready hub network in the DR region, and Azure Backup alongside ASR, because replication also copies corruption and ransomware.
