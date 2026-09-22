---
title: setup
layout: doc
parent: Command reference
nav_order: 0
permalink: /docs/commands/setup/
description: Provision the normal native Hive experience — agent skills, daemon, project enrollment, and loopback Hive web.
---

# hive setup

The normal first run after installing Hive on Linux or macOS. It diagnoses the
host, previews one consent boundary, provisions Hive-owned dependencies, installs
the daemon, initializes or enrolls the current project, and by default installs,
enables, starts, and probes the native Hive web service.

The untouched web configuration stays at `http://127.0.0.1:4567`. Setup never
creates LAN/public binding or Tailscale exposure; it only observes a pre-existing,
explicitly gated non-loopback choice.

## Usage

```bash
hive setup
hive setup --no-service
hive setup --no-bootstrap
hive setup --no-init
hive setup --yes --json
```

## Options

| Flag | What it does |
|------|--------------|
| `--no-service` | Perform the other setup work but make **no** web-service mutation. A pre-existing service may be observed, never stopped or disabled. |
| `--no-bootstrap` | Diagnose only. Skip agent-skill, QMD/web-bundle, daemon/web-service, and project mutations. This wins over service flags. |
| `--no-init` | Skip initialization or daemon enrollment of the current project. |
| `--yes` | Accept the revalidated aggregate plan for unattended operation. It does not override conflicts or user-owned files. |
| `--json` | Emit one versioned machine document. JSON never prompts; use `--yes` when the plan contains mutations. |

Interactive setup shows the aggregate agent-skill plan and asks once. JSON or
non-interactive setup without `--yes` performs no mutation and returns a
`consent_required` result.

## What successful setup reports

Setup keeps service lifecycle facts separate instead of collapsing them into
one “running” label:

- the effective URL;
- whether the platform's service manager is available;
- whether the `hive-web` service is installed and enabled;
- whether it is currently running; and
- whether its bounded `/health` probe is ready.

The JSON contract is `hive-setup.v1`. Its top-level mode is
`managed_service`, and its `service` object carries installed, enabled, running,
manager availability, URL, ready, and readiness fields. The process exit code
and document `ok` value use the same success predicate.

Linux without systemd-user and other unsupported service-manager environments
are a truthful platform exception: setup succeeds while reporting manager
unavailable and installed/enabled/running/ready as false, with foreground
`hive web`, WSL-systemd, and Hivebox guidance. A genuine install failure,
drifted unit, or active-but-not-ready service remains a failure.

## Repair and opt-out

Ordinary setup preserves a customized or drifted web unit. Inspect it with
[`hive web status --json`]({{ '/docs/commands/web/' | relative_url }}) and use
`hive web install --force` only when you intend to replace that unit. If you do
not want a managed web service, use `hive setup --no-service` and run bare
`hive web` in the foreground when needed.

On Windows, use WSL with systemd for native Hive web or
[Hivebox]({{ '/box/' | relative_url }}) through Docker Desktop.
