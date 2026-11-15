---
title: daemon
layout: doc
parent: Command reference
nav_order: 10
permalink: /docs/commands/daemon/
description: The always-on dispatcher that auto-advances ready tasks through every workflow stage.
---

# hive daemon

Manages the background process that advances ready tasks in enrolled
projects. In the coding workflow, it dispatches `plan`, `develop`, `open-pr`,
`review`, `artifacts`, and `finalize`, then archives eligible completed tasks
after their PR merges.

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
hive daemon quiesce [--timeout SECONDS]
hive daemon resume [--timeout SECONDS]
hive daemon clear-hold PROJECT [SLUG]
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
| `quiesce [--timeout SECONDS]` | Closes admission, drains owned work, flushes SQLite, and reports success only after it verifies a paused generation. `--timeout` defaults to 600 seconds. |
| `resume [--timeout SECONDS]` | Reconciles the closed generation, reopens admission, and restores the managed services that were running before the pause. |
| `clear-hold PROJECT [SLUG]` | Clears the persisted dropped-project hold for `PROJECT`, or only `SLUG`'s quarantine. Stop the daemon first. Does not accept `--json`. |
| `queue [list\|show\|prune]` | Inspects the dispatch-request queue the bot writes and the daemon consumes. `list` (the default) and `show <id>` are read-only. `prune` deletes expired requests the daemon has not claimed yet. |

Most subcommands (`stop`, `status`, `reload`, `enable`, `disable`, `install`,
`queue`, `quiesce`, `resume`) accept `--json` and emit a typed envelope for
automated callers. `clear-hold` does not accept `--json`.

## Key configuration

Concurrency and cost caps live under `daemon:` in the global `~/.config/hive/config.yml`:

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

# Inspect dispatch decisions in dry-run before enabling work
hive daemon start --dry-run
hive daemon tail
hive daemon stop
hive daemon start --detach

# Stop dispatch, or disable one project
hive daemon stop
hive daemon disable my-project
```

See [Operating]({{ '/docs/operating/' | relative_url }}) for the service setup,
autostart, dry runs, and troubleshooting.
