---
title: babysit
layout: default
parent: Command reference
nav_order: 9
permalink: /docs/commands/babysit/
description: Experimental background process that keeps open PRs green, mergeable, and rebased behind main.
---

# hive babysit

Manages the **experimental** PR babysitter — a background process that polls
your open pull requests and keeps them mergeable. It auto-rebases green PRs that
have fallen behind `main`, and asks your development agent to repair merge
conflicts or red CI in an isolated worktree. Reach for it when you want open PRs
to stay green without manual babysitting.

The babysitter is a separate process from the
[daemon]({{ '/docs/commands/daemon/' | relative_url }}). It only touches projects
that set `babysitter.enabled: true`.

## Usage

```bash
hive babysit start [--detach] [--dry-run]
hive babysit stop
hive babysit restart [--detach] [--dry-run]
hive babysit status
hive babysit reload
hive babysit tail
hive babysit --once PROJECT [--dry-run]
hive babysit --once --all [--dry-run]
```

This command is text-only; it does not emit a `--json` envelope.

## Subcommands and options

| Subcommand / flag | What it does |
|-------------------|--------------|
| `start` | Starts the babysitter. Add `--detach` to run it in the background. |
| `stop` | Sends a graceful stop and waits for in-flight PR repairs to finish before escalating. |
| `restart` | Stops a running babysitter and starts a fresh one. |
| `status` | Reports running / not-running plus uptime, and recommends a restart if the process predates your current Hive install. |
| `reload` | Re-reads config and log settings. Does not reload code into a detached process — use `restart` after upgrading Hive. |
| `tail` | Follows the babysitter log. |
| `--once PROJECT` | Runs a single poll tick for one project (handy for smoke tests and dry runs). |
| `--once --all` | Runs a single tick across every enabled project. |
| `--dry-run` | Runs without mutating GitHub: the agent writes a plan instead, and `git`/`gh` are replaced with read-only stubs. Use throwaway repos for destructive validation. |

## Project configuration

Enable the babysitter per project in `<project>/.hive-state/config.yml`:

```yaml
babysitter:
  enabled: true
  interval: 10m
  max_concurrent_prs: 2
  labels_ignore: [wip, do-not-merge, draft]
  auto_rebase: true
  budget_minutes: 30
  budget_usd: 50
```

`babysitter.enabled: false` is the kill switch and takes effect within one poll
interval. `auto_rebase` (default `true`) controls auto-rebasing green-but-behind
PRs onto the base branch; a rebase that conflicts is left untouched for a human.
PRs whose labels match `labels_ignore`, and draft PRs, are skipped.

## Examples

```bash
# Dry-run a single project to see what the babysitter would do
hive babysit --once my-project --dry-run

# Run it in the background and check on it later
hive babysit start --detach
hive babysit status
```
