# 08 - Azure Arc monitoring for on-prem servers

Brings a Linux server from my on-premises Proxmox lab under Azure management
and sends its logs and metrics to Log Analytics.

## What it builds
- Resource group and Log Analytics workspace
- Looks up the **Arc-enabled server** (`data "azurerm_arc_machine"`)
- Installs the **Azure Monitor Agent** as an Arc machine extension
- **Data Collection Rule** collecting:
  - Syslog (auth, authpriv, daemon, syslog, user)
  - Performance counters
- DCR association linking the server to the rule

## Why it matters
Hybrid estates need one monitoring plane. Arc lets on-prem servers be managed with
the same Azure tooling (Monitor, Policy, Update Manager) as cloud VMs.
