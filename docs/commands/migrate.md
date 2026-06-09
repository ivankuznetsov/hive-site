---
title: migrate
layout: default
parent: Command reference
nav_order: 17
permalink: /docs/commands/migrate/
description: Upgrade a project's tasks and config to the current Hive stage layout. Safe to re-run.
---

# hive migrate

Upgrades a project's tasks and config to the current Hive layout. Run it once on
an older project to rename outdated stage folders, rewrite renamed config keys,
and backfill task ids and display names. It's the explicit, idempotent upgrade
path for projects created before recent layout changes.

## Usage

```bash
hive migrate [PROJECT_PATH]
```

`PROJECT_PATH` defaults to the current directory. The project must already have
a `.hive-state/stages/` directory.

## What it does

- **Renames stage folders** from the old layout to the current one (for
  example, the old `5-review` becomes `6-review`, old `6-pr` becomes
  `8-finalize`, old done stages become `9-done`). Only real task folders move;
  stray files stay put.
- **Rewrites renamed config keys** to their current names (canonical keys win if
  both old and new are present).
- **Backfills task ids** for tasks missing one. Existing ids are never
  reassigned.
- **Backfills display names** for tasks missing one. Existing names are kept.

All changes are committed inside `.hive-state`, and only when there's something
to change. Re-running after a successful migration reports there's nothing to do
and leaves your folders in place.

## Examples

```bash
# Migrate the project in the current directory
hive migrate

# Migrate a specific project
hive migrate ~/Dev/your-project
```

When [`hive status`]({{ '/docs/commands/status/' | relative_url }}) warns about
legacy stage directories, `hive migrate` is what clears them.
