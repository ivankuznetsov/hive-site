---
title: Documentation
layout: doc
nav_order: 0
permalink: /docs/
description: Hive documentation — getting started, concepts, configuration, commands, and operating Hive as a service.
---

# Hive documentation

Hive runs multi-step work as a **folder-as-agent pipeline**: each task moves
through stage folders, an AI agent does the work at each stage, and a daemon
advances it in the background, asking for answers only when it needs them. Its
flagship **`coding`** workflow turns a rough idea into a merge-ready pull
request — but `coding` is one of several workflows. Hive also ships `content`
(research) and lets you author your own. These docs cover installing it, the
ideas behind it, configuring it, the command surface, and running it as a
service.

## Start here

- **[Getting started]({{ '/docs/getting-started/' | relative_url }})** — install, `hive init`, and your first task in the TUI.
- **[Concepts]({{ '/docs/concepts/' | relative_url }})** — folder-as-agent, the stage state machine, and the marker protocol.
- **[Configuration]({{ '/docs/configuration/' | relative_url }})** — project config, patrol mode, reviewers, agent profiles, and the daemon.
- **[Command reference]({{ '/docs/commands/' | relative_url }})** — every user-facing `hive` command.
- **[Custom workflows]({{ '/docs/custom-workflows/' | relative_url }})** — the engine is generic: author your own per-project pipeline in YAML.
- **[Operating]({{ '/docs/operating/' | relative_url }})** — daemon, bot, and babysitter as services.

## Looking for the source?

Hive is open source (MIT) on [GitHub](https://github.com/ivankuznetsov/hive).
The full engineering wiki lives in the repo; these docs are the curated,
user-facing subset.
