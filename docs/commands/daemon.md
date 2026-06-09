---
title: daemon
layout: default
parent: Command reference
nav_order: 10
permalink: /docs/commands/daemon/
description: The always-on dispatcher that auto-advances ready tasks through every workflow stage.
---

# hive daemon

The operator surface for Hive's auto-advancing dispatcher. One long-running
process watches every registered project and automatically dispatches the next
workflow verb (`plan`, `develop`, `open-pr`, `review`, `artifacts`, `finalize`)
for any task that's ready to move, then archives tasks once their PR merges.
Reach for it when you want Hive to drive tasks forward on its own.

The daemon stops at human-input gates — questions, triage, plan approval, and
finalize while the PR is still open — so it never advances past a point that
needs you.

## Usage

```bash
hive daemon install [--force]
hive daemon enable PROJECT | --all
hive daemon start [--detach] [--dry-run]
hive daemon status [--json]
hive daemon tail
hive daemon stop
hive daemon disable PROJECT | --all
hive daemon reload
hive daemon queue [list | show <id> | prune]
```

## Subcommands

| Subcommand | What it does |
|------------|--------------|
| `install` | Installs the autostart service (systemd-user on Linux, launchd on macOS) so the daemon survives reboot. `--force` overwrites an existing unit (the previous one is backed up). |
| `enable PROJECT` / `enable --all` | Enrols a project for dispatch by setting `daemon.enabled: true` in its config. |
| `disable PROJECT` / `disable --all` | Stops dispatching for a project. The next tick honours it automatically. |
| `start` | Starts the daemon. `--detach` runs it in the background; `--dry-run` logs every dispatch decision without spawning any work. |
| `status` | Reports running / not-running plus uptime, PID, log path, and autostart-service state. |
| `tail` | Follows the daemon log. |
| `stop` | Gracefully stops the daemon, waiting for in-flight children before escalating. Idempotent. |
| `reload` | Reloads config at the next tick; in-flight work continues. |
| `queue [list\|show\|prune]` | Read-only inspection of the dispatch-request queue the bot writes and the daemon consumes. |

Most subcommands (`stop`, `status`, `reload`, `enable`, `disable`, `install`,
`queue`) accept `--json` and emit a typed envelope for automated callers.

## Key configuration

Concurrency and cost caps live under `daemon:` in `~/Dev/hive/config.yml`:

| Key | Default | Purpose |
|-----|---------|---------|
| `poll_interval_sec` | 30 | How often to run a full status scan. |
| `max_concurrent_runs` | 3 | Global cap on tasks running at once. Raising it multiplies cost. |
| `max_concurrent_per_project` | 3 | Per-project burst cap. |
| `max_runs_per_day_per_project` | 50 | Circuit breaker for runaway loops. |

## Examples

```bash
# First-time setup: install the service and enrol a project
hive daemon install
hive daemon enable my-project

# Shake it down in dry-run for a while, then go live
hive daemon start --dry-run
hive daemon tail
hive daemon stop
hive daemon start --detach

# Cost runaway? Stop everything, or drop one project mid-flight
hive daemon stop
hive daemon disable my-project
```

See [Operating]({{ '/docs/operating/' | relative_url }}) for the full day-2
guide: service setup, autostart, dry-run shakedown, and troubleshooting.
