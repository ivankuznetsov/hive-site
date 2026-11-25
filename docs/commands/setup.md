---
title: setup
layout: doc
parent: Command reference
nav_order: 19
permalink: /docs/commands/setup/
description: First-run provisioning that checks prerequisites, installs Hive's services, and enrolls the current project.
---

# hive setup

Provisions a machine for Hive. It checks prerequisites, provisions Hive's managed
agent skills and dependencies, enrolls the current project, and installs the
daemon, PR babysitter, and web service. Run it after installing Hive.

In a terminal, setup previews its changes and asks for one confirmation. With
`--json` or without a terminal, it changes nothing unless you pass `--yes`.

## Usage

```bash
hive setup [--yes] [--no-service] [--no-bootstrap] [--no-init] [--json]
```

## Options

| Flag | What it does |
|------|--------------|
| `--yes` | Confirm the complete setup plan without a prompt. Required for `--json` and non-terminal runs. |
| `--no-service` | Skip installing and starting the managed web service. An existing service is observed, not stopped. |
| `--no-bootstrap` | Diagnose only. Runs the checks and provisions nothing. |
| `--no-init` | Do not enroll the current project. |
| `--json` | Print a machine-readable `hive-setup` result. |

## What it does

1. Runs diagnostics on the tools Hive needs: Ruby, git, the Claude and Codex
   CLIs, Node/npm, QMD, and SQLite.
2. Provisions Hive's managed agent skills for your configured agents.
3. Installs QMD if it is missing, and installs or refreshes the web app bundle.
4. Enrolls the current project, unless `--no-init` is set.
5. Installs the daemon and the PR babysitter services.
6. Installs and starts the Hive web service, unless `--no-service` is set.

In a terminal, setup also offers once to import your personal MCP servers. See
[`hive mcp`]({{ '/docs/commands/mcp/' | relative_url }}).

By default the web UI listens on loopback at `http://127.0.0.1:4567`. Setup never
creates LAN, public, or Tailscale exposure. Setup exits 0 only when every step
succeeds. A failed step, or a run refused for lack of `--yes`, exits 1.

## Examples

```bash
# First run: review the plan and confirm once
hive setup

# Scripted core provisioning, without enrolling the current project
hive setup --no-init --yes --json

# Check prerequisites and change nothing
hive setup --no-bootstrap

# Provision everything except the web service
hive setup --no-service --yes
```

To manage the web service afterwards, see
[`hive web`]({{ '/docs/commands/web/' | relative_url }}). To enroll more projects,
see [`hive init`]({{ '/docs/commands/init/' | relative_url }}).
