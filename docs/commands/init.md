---
title: init
layout: doc
parent: Command reference
nav_order: 1
permalink: /docs/commands/init/
description: Bootstrap a git project for Hive — creates the state branch, scaffolds stages, and walks you through setup.
---

# hive init

Bootstraps a project so Hive can run its pipeline against it. Run this once per
repository, from the main checkout. It creates Hive's hidden state branch and
worktree, scaffolds the stage folders, registers the project, and (on an
interactive terminal) walks you through which agents and settings to use.

## Usage

```bash
# Initialize the project in the current directory
hive init

# Initialize a specific project path
hive init ~/Dev/your-project

# Skip the clean-tree check and emit the resolved setup as JSON
hive init --force --json
```

`PROJECT_PATH` defaults to the current directory.

## Options

| Flag | What it does |
|------|--------------|
| `--force` | Skip the "working tree must be clean" check. |
| `--workflow ID` | Use workflow `ID` as the project default and skip the workflow prompt. Built-in and project-authored workflows are accepted. Cannot be combined with `--new-workflow`. |
| `--new-workflow ID` | Scaffold a custom workflow `ID`, bind it as the project default, and print the paths to edit. Cannot be combined with `--workflow`. |
| `--minimal` | With `--new-workflow` on a fresh project, use the minimal profile: patrol, architecture patrol, ad-hoc auto-fix, the daemon (dispatch and autostart), babysitting, optional reviewers, and service installs are all off. Requires `--new-workflow`; rejects `--force` and `--refactor-patrol`. |
| `--preview` | With `--minimal`, print the resolved initialization plan without writing anything. |
| `--[no-]refactor-patrol` | Turn architecture patrol (post-merge refactor discovery) on or off before anything is written. Fresh projects only; for an existing project, edit `refactor_patrol.enabled` in `.hive-state/config.yml`. |
| `--json` | Emit a typed `hive-init` envelope with the project metadata and your resolved setup answers, instead of the human summary. |

## What it sets up

When you run `hive init` on a real terminal, it asks you to pick:

- The workflow to use as the project default. It is asked only on a terminal
  when more than one workflow is registered, and it can also start a new one.
- The planning agent (used for brainstorm and plan).
- Claude permission mode. Claude runs headless in v0.8.0; there is no launch-mode prompt.
- The Claude model and reasoning effort. Both default to `default`, which follows
  Claude Code's own choice.
- The development agent that implements the work (defaults to `codex`).
- Which reviewers run during code review, and which run on patrol PRs.
- The patrol frequency (`ultrapatrol`, `high`, `medium`, `low`, or `off`).
- The triage bias (`courageous` or `safetyist`, default `courageous`), which decides
  how review findings are routed before auto-fix.
- Whether to enable auto-fix for ad-hoc PR reviews (`hive review --pr`). Default is off.
- Whether to enable architecture patrol, which reviews merged PRs for refactor
  opportunities. Default is on. It is not asked when you pass `--[no-]refactor-patrol`.
- Optional per-stage budget and timeout caps. Claude budgets are uncapped unless configured.
- Whether to enroll the project in the auto-advance daemon and the experimental
  PR babysitter, and whether to autostart the daemon service now.

All of these land in `<project>/.hive-state/config.yml`, which you can edit
later. See [Configuration]({{ '/docs/configuration/' | relative_url }}) for the
project settings.

When you run it in a script or pipe (non-interactive), it skips every question
and uses the recommended defaults.

## Requirements

- The path must be a git repository.
- It must be the main checkout, not a worktree.
- The working tree must be clean, unless you pass `--force`.
- If the project is already initialized, `hive init` reports that and does
  nothing — it is safe to re-run.

## Examples

```bash
# First-time setup, interactive
cd ~/Dev/your-project
hive init

# Scripted setup using defaults, captured as JSON
hive init ~/Dev/your-project --force --json
```

Next, capture an idea with [`hive new`]({{ '/docs/commands/new/' | relative_url }})
or open the dashboard with [`hive tui`]({{ '/docs/commands/tui/' | relative_url }}).
See [Getting started]({{ '/docs/getting-started/' | relative_url }}) for the full
first-run walkthrough.
