---
title: patrol
layout: doc
parent: Command reference
nav_order: 8
permalink: /docs/commands/patrol/
description: Opt-in repository scan that finds, fixes, validates, and opens PRs for issues across a registered project.
---

# hive patrol

Runs one repository-scan cycle for a registered project: it maps the codebase
into feature slices, reviews each slice, attempts isolated fixes that clear the
confidence gate, validates them with your configured commands, and opens PRs
for fixes that pass. Reach for it when you want Hive to proactively surface and
fix issues rather than waiting for you to file work.

Patrol is **opt-in**. Each project must enable it in its config, and the
[daemon]({{ '/docs/commands/daemon/' | relative_url }}) runs it automatically on
a slow cadence once enabled.

## Usage

```bash
hive patrol my-project            # run one scan cycle
hive patrol my-project --dry-run  # map + review + select candidates only
hive patrol my-project --json     # machine-readable envelope
```

`my-project` is a registered project name from your global config. The project
opts in through its `.hive-state/config.yml`:

```yaml
patrol:
  enabled: true
  min_confidence_to_fix: medium
  max_prs_per_cycle: 3
  commands:
    test: bundle exec rake test
```

## Options

| Flag | What it does |
|------|--------------|
| `--dry-run` | Stops after mapping, review, and candidate selection. Updates scan state but creates no worktrees, pushes no branches, and opens no PRs. |
| `--json` | Emit the typed `hive-patrol` envelope (features mapped, findings, fixes attempted/validated, PRs opened, PR URLs) instead of text. |

## Configuration

Patrol intensity is controlled by `patrol.mode` (`ultrapatrol` / `high` /
`medium` / `low` / `off`) plus the keys above. Opened PRs flow into the normal
`6-review` stage by default so your reviewers see them. See
[Configuration]({{ '/docs/configuration/' | relative_url }}#patrol) for the full
set of patrol settings.

## Examples

```bash
# Dry-run first to see what patrol would do, without touching GitHub
hive patrol my-project --dry-run --json

# Run a real cycle once you're comfortable with the candidates
hive patrol my-project
```
