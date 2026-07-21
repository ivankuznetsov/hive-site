---
title: Command reference
layout: doc
nav_order: 4
has_children: true
permalink: /docs/commands/
description: Every user-facing hive command, grouped by what it's for.
---

# Command reference

Every Hive workflow verb runs on `bin/hive` (or the `hv` shim when Apache Hive
shadows the name). Commands whose pages document a typed `--json` result can be
driven without scraping text. Support is command-specific: in Hive 0.6.5,
`hive new` accepts the global flag but still prints human prose, and `hive tui`
is human-only.

The TUI is the recommended human interface and an agent-driven CLI is the
recommended automation surface — but every command below is available directly
for scripting, debugging, and recovery.

| Group | Commands |
|-------|----------|
| **Workflow** | [`new`]({{ '/docs/commands/new/' | relative_url }}), [`run`]({{ '/docs/commands/run/' | relative_url }}), [`approve`]({{ '/docs/commands/approve/' | relative_url }}), and [`workflow new`]({{ '/docs/custom-workflows/' | relative_url }}#create-the-files) |
| **Dashboard** | [`tui`]({{ '/docs/commands/tui/' | relative_url }}), [`status`]({{ '/docs/commands/status/' | relative_url }}) |
| **Review** | [`findings`]({{ '/docs/commands/findings/' | relative_url }}) |
| **Autonomy** | [`patrol`]({{ '/docs/commands/patrol/' | relative_url }}), [`babysit`]({{ '/docs/commands/babysit/' | relative_url }}), [`daemon`]({{ '/docs/commands/daemon/' | relative_url }}), [`bot`]({{ '/docs/commands/bot/' | relative_url }}) |
| **Lifecycle** | [`init`]({{ '/docs/commands/init/' | relative_url }}), [`update`]({{ '/docs/commands/update/' | relative_url }}), [`uninstall`]({{ '/docs/commands/uninstall/' | relative_url }}), [`drop`]({{ '/docs/commands/drop/' | relative_url }}), [`migrate`]({{ '/docs/commands/migrate/' | relative_url }}) |
| **Diagnostics** | [`doctor`]({{ '/docs/commands/doctor/' | relative_url }}), [`metrics`]({{ '/docs/commands/metrics/' | relative_url }}), [`wiki`]({{ '/docs/commands/wiki/' | relative_url }}) |

See [Configuration]({{ '/docs/configuration/' | relative_url }}) for the
settings these commands read, and [Operating]({{ '/docs/operating/' | relative_url }})
for running the daemon, bot, and babysitter as services.
