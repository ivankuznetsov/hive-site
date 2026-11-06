---
title: migrate
layout: doc
parent: Command reference
nav_order: 17
permalink: /docs/commands/migrate/
description: Historical hive migrate reference and current guidance for converting older Hive state.
---

# hive migrate

**Removed from current Hive.** Do not use the commands below with v0.8.0.
For older installations, back up retained state and follow the
[current-format conversion guide](https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/guides/current-format-migration.md).
Startup and update do not convert historical state automatically.

The following reference is preserved for older installations.

In earlier releases, this command renamed outdated stage folders, rewrote
renamed configuration keys, and backfilled task IDs and display names.

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

Current Hive reports retained legacy state for attention. Use the conversion
guide above, not this historical command, to plan an upgrade.
