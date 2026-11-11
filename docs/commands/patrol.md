---
title: patrol
layout: doc
parent: Command reference
nav_order: 8
permalink: /docs/commands/patrol/
description: Opt-in repository scan that maps a registered project, reviews it for defects, and hands findings to the Patrol Fix workflow.
---

# hive patrol

Runs one repository-scan cycle for a registered project. It maps the codebase
into feature slices, asks the patrol agent to review a rotating batch of them
for high-value production defects, and records the findings it accepts. The
cycle never edits code, pushes branches, or opens PRs. Each accepted finding is
handed to the separate Patrol Fix workflow, which fixes and validates it and
opens the PR as a task.

Patrol is **opt-in**. Each project must enable it in its config, and the
[daemon]({{ '/docs/commands/daemon/' | relative_url }}) runs it automatically on
a slow cadence once enabled.

## Usage

```bash
hive patrol my-project            # run one scan cycle
hive patrol my-project --dry-run  # map and review without persisting findings
hive patrol my-project --json     # machine-readable envelope
hive patrol my-project --list     # summarize recorded findings (read-only)
hive patrol my-project --once     # one scheduler pass (hive-one-shot.v1)
```

`my-project` is a registered project name from your global config. The project
opts in through its `.hive-state/config.yml`:

```yaml
patrol:
  mode: medium
  min_confidence_to_fix: medium
  max_prs_per_cycle: 3
  commands:
    test: bundle exec rake test
```

## Options

| Flag | What it does |
|------|--------------|
| `--dry-run` | Maps and reviews as usual, but writes no findings, hands nothing to the Patrol Fix workflow, and does not advance the last scanned SHA. |
| `--json` | Emits the typed `hive-patrol` envelope (`hive-patrol.v3`) instead of text: features mapped and reviewed, review errors, findings, fix candidates, skipped findings, and the last scanned SHA. `fixes_attempted`, `fixes_validated`, `prs_opened`, `pr_urls`, `fix_results`, and `review_handoff_errors` are always zero or empty here, because fixes and PRs happen in the Patrol Fix workflow. With `--list`, it emits `hive-patrol-findings.v1`. |
| `--list` | Prints a bounded, read-only summary of recorded findings without running a scan. |
| `--once` | Runs one pass of the daemon's patrol scheduler for this project and prints a `hive-one-shot.v1` result. It starts a scan only if one is due. With `--dry-run` it only reports readiness. Cannot be combined with `--list`. |

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
