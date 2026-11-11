---
title: Documentation
layout: doc
nav_order: 0
permalink: /docs/
description: Hive documentation — getting started, concepts, configuration, commands, and operating Hive as a service.
---

# Hive documentation

Hive runs local workflows for AI agents. Each task moves through named stages,
with files that record the input, work, and result. The daemon advances ready
stages and pauses when a task needs your input. Inspect the same work in the
local web UI, TUI, or CLI.

Start with the built-in `coding`, `content`, or `bench` workflow, install a
[Writing or Architecture Honeycomb](/honeycombs/), or define your own stages
in YAML. These docs cover installation, workflow behavior,
configuration, commands, and background services.

## Start here

- **[Getting started]({{ '/docs/getting-started/' | relative_url }})** — install, `hive init`, and your first task in the local web UI or TUI.
- **[Concepts]({{ '/docs/concepts/' | relative_url }})** — folder-as-agent, the stage state machine, and the marker protocol.
- **[Configuration]({{ '/docs/configuration/' | relative_url }})** — project config, patrol mode, reviewers, agent profiles, and the daemon.
- **[Command reference]({{ '/docs/commands/' | relative_url }})** — commands for everyday use and recovery.
- **[Custom workflows]({{ '/docs/custom-workflows/' | relative_url }})** — define stages, instructions, and human decisions in YAML.
- **[Operating]({{ '/docs/operating/' | relative_url }})** — daemon, bot, and babysitter as services.

## Looking for the source?

Hive is open source (MIT) on [GitHub](https://github.com/ivankuznetsov/hive).
The repository also contains the full CLI reference and engineering wiki.

## Workflows from private repositories

See [Installing private workflows](/docs/private-workflows/) for repository
access, Git authentication, exact-revision imports and runtime setup. This
feature is available in Hive v0.8.0 and later; older builds cannot run it.
The guide explains how to check CLI availability.
