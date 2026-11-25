---
title: Command reference
layout: doc
nav_order: 4
has_children: true
permalink: /docs/commands/
description: Hive commands for task workflows, status, services, setup, and diagnostics.
---

# Command reference

Use `hive` (or `hv` if Apache Hive occupies that command name) to capture
tasks, run stages, inspect results, and manage services. Workflow verbs support
`--json` for structured output; each page notes exceptions and supported options.

The native web UI and TUI provide interactive views of the same tasks. The
commands below cover common CLI operations. For the complete current surface,
see the [v0.8.0 CLI reference](https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/cli.md)
and `hive --help`.

| Group | Commands |
|-------|----------|
| **Workflow** | [`new`]({{ '/docs/commands/new/' | relative_url }}), [`run`]({{ '/docs/commands/run/' | relative_url }}), [`approve`]({{ '/docs/commands/approve/' | relative_url }}), [`decide`]({{ '/docs/commands/decide/' | relative_url }}), [`workflow`]({{ '/docs/commands/workflow/' | relative_url }}) |
| **Dashboard** | [`tui`]({{ '/docs/commands/tui/' | relative_url }}), [`status`]({{ '/docs/commands/status/' | relative_url }}), [`web`]({{ '/docs/commands/web/' | relative_url }}) |
| **Review** | [`findings`]({{ '/docs/commands/findings/' | relative_url }}) |
| **Autonomy** | [`patrol`]({{ '/docs/commands/patrol/' | relative_url }}), [`babysit`]({{ '/docs/commands/babysit/' | relative_url }}), [`daemon`]({{ '/docs/commands/daemon/' | relative_url }}), [`bot`]({{ '/docs/commands/bot/' | relative_url }}) |
| **Lifecycle** | [`setup`]({{ '/docs/commands/setup/' | relative_url }}), [`init`]({{ '/docs/commands/init/' | relative_url }}), [`update`]({{ '/docs/commands/update/' | relative_url }}), [`uninstall`]({{ '/docs/commands/uninstall/' | relative_url }}), [`drop`]({{ '/docs/commands/drop/' | relative_url }}), [`mcp`]({{ '/docs/commands/mcp/' | relative_url }}) |
| **Diagnostics** | [`doctor`]({{ '/docs/commands/doctor/' | relative_url }}), [`metrics`]({{ '/docs/commands/metrics/' | relative_url }}), [`wiki`]({{ '/docs/commands/wiki/' | relative_url }}) |

For installations with older state, read [Historical state conversion]({{ '/docs/commands/migrate/' | relative_url }}).

See [Configuration]({{ '/docs/configuration/' | relative_url }}) for the
settings these commands read, and [Operating]({{ '/docs/operating/' | relative_url }})
for running the daemon, bot, and babysitter as services.
