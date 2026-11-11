---
title: web
layout: doc
parent: Command reference
nav_order: 20
permalink: /docs/commands/web/
description: Run the Hive web UI in the foreground or manage its background service.
---

# hive web

Serves the Hive web UI, which shows the same projects and tasks as the TUI. Bare
`hive web` runs it in the foreground until you stop it. Use the subcommands to
run or repair the background service that
[`hive setup`]({{ '/docs/commands/setup/' | relative_url }}) installs.

By default the server binds `127.0.0.1` on port `4567`. Set `web.bind` and
`web.port` in your Hive config, or override them for one run with `--bind` and `--port`.

## Usage

```bash
hive web [--bind ADDR] [--port PORT] [--no-bootstrap] [--unsafe]
hive web start [--detach]
hive web stop
hive web status [--json]
hive web install [--force] [--json]
```

## Subcommands

| Subcommand | What it does |
|------------|--------------|
| (none) | Runs the server in the foreground. |
| `start` | Runs in the foreground. With `--detach`, starts the managed service instead. |
| `stop` | Stops the managed service. |
| `status` | Reports the effective URL and whether the service is installed, enabled, running, and ready. Read-only. |
| `install` | Installs the managed service with autostart. Installs or refreshes the web app bundle unless `--no-bootstrap` is set. |

## Options

| Flag | What it does |
|------|--------------|
| `--bind ADDR` | Override `web.bind` (default `127.0.0.1`). |
| `--port PORT` | Override `web.port` (default `4567`). |
| `--no-bootstrap` | Do not install or refresh the managed web app. |
| `--unsafe` | Allow a non-loopback bind without a configured GitHub owner. `--allow-public` is an alias. |
| `--force` | For `install`: refresh the bundle and overwrite a service unit that differs. |
| `--detach` | For `start`: run the managed service instead of the foreground server. |
| `--json` | Works with `status` and `install`. Other forms reject it. |

## Binding and sign-in

- A non-loopback bind is refused unless `web.github.owner` is set or `--unsafe` is passed.
- On loopback, GitHub sign-in is skipped by default. Set `web.local_loopback: false` to require it.

## Examples

```bash
# Run the UI in the foreground on the default address
hive web

# Serve on another port for this run
hive web --port 4600

# Install the background service, then check it
hive web install
hive web status --json

# Start and stop the managed service
hive web start --detach
hive web stop

# Repair a service unit that has drifted
hive web install --force
```

For running the web service alongside the daemon, see
[Operating]({{ '/docs/operating/' | relative_url }}).
