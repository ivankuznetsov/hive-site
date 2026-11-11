---
title: workflow
layout: doc
parent: Command reference
nav_order: 23
permalink: /docs/commands/workflow/
description: Scaffold, validate, and manage the workflows that drive Hive tasks, including reviewed Honeycomb packages.
---

# hive workflow

Manages the workflows a project's tasks follow. Use it to scaffold a project-local workflow,
validate and commit it, or install, update, and remove reviewed Honeycomb
packages. Run it from inside the project. For how to author stages, instructions,
and permissions, see the [Custom workflows]({{ '/docs/custom-workflows/' | relative_url }}) guide.

## Usage

```bash
hive workflow new ID [--template NAME]
hive workflow validate ID [--json]
hive workflow commit ID
hive workflow install honeycomb/NAME[@VERSION]
hive workflow install ID --from REPOSITORY [--ref REF]
hive workflow list [--json]
hive workflow update NAME [--dry-run] [--yes] [--allow-escalation]
hive workflow remove NAME [--dry-run] [--yes]
hive workflow publish ID --version X.Y.Z [--dry-run] [--expected-release-digest SHA256] [--json]
```

## Subcommands

| Subcommand | What it does |
|------------|--------------|
| `new ID` | Scaffolds `.hive-state/workflows/ID.yml` and its stage instructions. Edit them, then run `hive new PROJECT --workflow ID "idea"`. |
| `validate ID` | Loads the workflow graph and instructions and reports problems. Read-only. |
| `commit ID` | Validates and commits an owner-authored workflow under Hive's state lock. Does not accept `--json`. |
| `install honeycomb/NAME` | Verifies and installs a reviewed Honeycomb package. |
| `install ID --from REPOSITORY` | Imports a workflow from a private Git repository (Hive v0.8.0 and later). See [Private workflows]({{ '/docs/private-workflows/' | relative_url }}). |
| `list` | Shows built-in, authored, and managed workflows. Takes no ID. |
| `update NAME` | Shows the package diff, then advances it after confirmation. |
| `remove NAME` | Stops new tasks from using a managed package. Refused while tasks still use it, or when it is the project default. |
| `publish ID` | Packages an authored workflow and opens a Honeycomb registry pull request. |

## Options

| Flag | What it does |
|------|--------------|
| `--template NAME` | For `new`: seed from a sample, `blank` (default) or `research`. `architecture` and `writing` now install from Honeycomb. |
| `--yes` | For `update` and `remove`: confirm without a prompt. Required with `--json` or without a terminal. |
| `--dry-run` | Validate and report without changing the project or remote state. |
| `--allow-escalation` | For `update`: separately allow capabilities that are unbounded or increased. |
| `--mapping SLOT=AGENT[,model=M][,effort=E]` | For `install` and `update`: override the agent for a stage slot. |
| `--input-binding NAME=ENV_NAME` | For `install` and `update`: bind an optional input to an environment variable. |
| `--from REPOSITORY` / `--ref REF` | For `install ID`: the Git repository to import from, and an optional ref (defaults to `HEAD`). `--ref` requires `--from`. |
| `--version X.Y.Z` | For `publish`: the semantic version to package. |
| `--expected-release-digest SHA256` | For `publish`: the digest from a confirmed dry run. Not valid with `--dry-run`. |
| `--json` | Machine-readable output. |

## Examples

```bash
# Scaffold from the research sample, then check it
hive workflow new my-flow --template research
hive workflow validate my-flow --json

# Install a reviewed package, preview an update, then apply it
hive workflow install honeycomb/architecture
hive workflow update architecture --dry-run --json
hive workflow update architecture --yes

# Publish: dry run first, then submit the confirmed digest
hive workflow publish my-flow --version 1.0.0 --dry-run --json
hive workflow publish my-flow --version 1.0.0 --expected-release-digest <digest> --json
```
