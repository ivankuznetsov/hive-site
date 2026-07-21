---
title: Documentation
layout: doc
nav_order: 0
permalink: /docs/
description: Hive documentation — getting started, concepts, configuration, commands, and operating Hive as a service.
---

# Hive documentation

Hive runs reusable workflows as durable task folders. A workflow definition
names the stages and handoffs; a task run carries one brief through that
process. Agents and people leave artifacts behind, status markers control
movement, and the daemon advances work that is ready.

## Start with the workflow model

- **[Getting started]({{ '/docs/getting-started/' | relative_url }})** — install, `hive init`, and your first task in the TUI.
- **[How workflows work]({{ '/docs/concepts/' | relative_url }})** — distinguish a reusable definition from a task run, then follow artifacts, markers, checkpoints, and terminal outcomes.
- **[Custom workflows]({{ '/docs/custom-workflows/' | relative_url }})** — turn that model into project-local YAML with a complete editorial example.

Hive's flagship **`coding`** workflow turns a rough idea into a merge-ready pull
request. The same engine also runs built-in content and benchmark workflows,
project-local definitions, and reviewed versioned Honeycombs.

## Operate and configure Hive

- **[Configuration]({{ '/docs/configuration/' | relative_url }})** — project config, patrol mode, reviewers, agent profiles, and the daemon.
- **[Command reference]({{ '/docs/commands/' | relative_url }})** — every user-facing `hive` command.
- **[Operating]({{ '/docs/operating/' | relative_url }})** — daemon, bot, and babysitter as services.

## Looking for the source?

Hive is open source (MIT) on [GitHub](https://github.com/ivankuznetsov/hive).
The full engineering wiki lives in the repo; these docs are the curated,
user-facing subset.
