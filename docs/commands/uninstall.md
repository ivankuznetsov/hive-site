---
title: uninstall
layout: doc
parent: Command reference
nav_order: 15
permalink: /docs/commands/uninstall/
description: Remove Hive's services, config, cache, and symlinks while preserving your accumulated work by default.
---

# hive uninstall

Removes your user-scoped Hive install — service units, config, cache, versioned
payloads, and the `hive`/`hv` symlinks — while preserving the work Hive has
accumulated by default.

## Usage

```bash
# Remove Hive, keep all state (interactive)
hive uninstall

# Remove Hive without prompts, still keep state
hive uninstall --purge

# Remove Hive AND delete accumulated state
hive uninstall --force-purge-state
```

## Options

| Flag | What it does |
|------|--------------|
| `--purge` | Run non-interactively (no prompts). Still preserves your state. |
| `--force-purge-state` | The explicit destructive path — also removes Hive's accumulated state and each registered project's `.hive-state` directory. |

## What it does

1. Stops a running daemon, bot, and babysitter.
2. Deregisters the daemon, bot, babysitter, and web service units (launchd on
   macOS, systemd user units on Linux). A unit that cannot be removed is reported
   as a warning and uninstall continues. If a service is busy or its state cannot
   be verified, uninstall stops before removing any config, cache, or data.
3. Removes Hive's config, cache, and versioned data directories.
4. Removes the `hive` and `hv` symlinks from your bin directory.

## State preservation

By default, uninstall **keeps your work**. It prints the state directory it is
preserving and lists each registered project's `.hive-state` path. An
interactive run asks whether to remove those project state directories, and
answering `y` deletes them; `--purge` skips that prompt and keeps them.

Project `.hive-state` directories are only deleted when you answer `y` to that
prompt or explicitly pass `--force-purge-state`.

## Examples

```bash
# Clean removal that keeps every task and project state
hive uninstall --purge

# Full wipe, including project .hive-state directories
hive uninstall --force-purge-state
```

See [Operating]({{ '/docs/operating/' | relative_url }}#updating--uninstalling)
for related guidance.
