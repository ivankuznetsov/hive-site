---
title: Command reference
layout: doc
nav_order: 4
has_children: true
permalink: /docs/commands/
description: Every user-facing hive command, grouped by what it's for.
---

# Command reference

Every Hive command runs through `hive` (or the `hv` shim when Apache Hive
shadows the name). Machine-readable commands return typed envelopes, so an
agent can drive Hive with structured output instead of scraping text.

Native Hive web is the normal browser interface, the TUI is the power-user
terminal interface, and an agent-driven CLI is the recommended automation
surface. Every command below remains available directly for scripting,
debugging, and recovery.

| Group | Commands |
|-------|----------|
| **First run & web** | [`setup`]({{ '/docs/commands/setup/' | relative_url }}), [`web`]({{ '/docs/commands/web/' | relative_url }}) |
| **Workflow** | [`new`]({{ '/docs/commands/new/' | relative_url }}), [`run`]({{ '/docs/commands/run/' | relative_url }}), [`approve`]({{ '/docs/commands/approve/' | relative_url }}) |
| **Status surfaces** | [`web`]({{ '/docs/commands/web/' | relative_url }}), [`tui`]({{ '/docs/commands/tui/' | relative_url }}), [`status`]({{ '/docs/commands/status/' | relative_url }}) |
| **Review** | [`findings`]({{ '/docs/commands/findings/' | relative_url }}) |
| **Autonomy** | [`patrol`]({{ '/docs/commands/patrol/' | relative_url }}), [`babysit`]({{ '/docs/commands/babysit/' | relative_url }}), [`daemon`]({{ '/docs/commands/daemon/' | relative_url }}), [`bot`]({{ '/docs/commands/bot/' | relative_url }}) |
| **Lifecycle** | [`init`]({{ '/docs/commands/init/' | relative_url }}), [`update`]({{ '/docs/commands/update/' | relative_url }}), [`uninstall`]({{ '/docs/commands/uninstall/' | relative_url }}), [`drop`]({{ '/docs/commands/drop/' | relative_url }}), [`migrate`]({{ '/docs/commands/migrate/' | relative_url }}) |
| **Diagnostics** | [`doctor`]({{ '/docs/commands/doctor/' | relative_url }}), [`metrics`]({{ '/docs/commands/metrics/' | relative_url }}), [`wiki`]({{ '/docs/commands/wiki/' | relative_url }}) |

See [Configuration]({{ '/docs/configuration/' | relative_url }}) for the
settings these commands read, and [Operating]({{ '/docs/operating/' | relative_url }})
for running Hive web, the daemon, bot, and babysitter as services.
