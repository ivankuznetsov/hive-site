---
title: Private workflows
layout: doc
nav_order: 7
permalink: /docs/private-workflows/
description: Install a project workflow from a private Git repository, authenticate access, pin its source commit, and configure its runtime prerequisites.
---

# Installing workflows from private repositories
{: .no_toc }

**Availability: unreleased.** Direct Git installation requires a Hive build
containing the private-source importer. Check `hive workflow --help` for the
`--from` and `--ref` options. If they are missing, your installed build cannot
run the commands below. A private repository invitation alone does not enable
this feature.

1. TOC
{:toc}

## Get repository access

The repository owner must grant your GitHub account read access, for example
through a collaborator invitation or organization team. Accept the invitation
before installing.

For HTTPS authentication with GitHub CLI:

```sh
gh auth login
gh auth setup-git
```

Hive uses Git's configured authentication. You can also use an SSH repository
URL with an SSH key that already has access. Keep tokens in your credential
helper; do not include them in repository URLs or workflow files.

## Install into your project

Start in an [initialized Hive project](/docs/getting-started/). Replace
`weekly-news`, `OWNER` and `PRIVATE-REPO` with the workflow's actual details:

```sh
hive workflow install weekly-news \
  --from https://github.com/OWNER/PRIVATE-REPO.git

hive workflow validate weekly-news --json
```

For SSH, use `--from git@github.com:OWNER/PRIVATE-REPO.git` instead.
The repository must provide this layout:

```text
workflows/
  weekly-news.yml
  weekly-news/
    research.md
    draft.md
```

The descriptor's ID must match `weekly-news`. Its instructions and other assets
belong under that workflow directory. See [Custom workflows](/docs/custom-workflows/)
for descriptor authoring.

Hive resolves the requested source to a commit, validates the graph, and commits
the imported descriptor and assets to your project's Hive state. The workflow
is editable. Its `hive-source.json` receipt records the repository, requested
ref, resolved commit and imported file hashes.

## Preview or pin a revision

An optional preview reports the source and files without changing project state:

```sh
hive workflow install weekly-news \
  --from https://github.com/OWNER/PRIVATE-REPO.git \
  --dry-run --json
```

To install exactly what you previewed, replace `FULL_COMMIT` below with the
preview's `source_commit`:

```sh
hive workflow install weekly-news \
  --from https://github.com/OWNER/PRIVATE-REPO.git \
  --ref FULL_COMMIT
```

Without `--ref`, Hive resolves the repository's HEAD. A supplied branch or tag
also resolves to a recorded commit. Existing workflow IDs are never overwritten,
including local edits and managed workflows.

## Configure the workflow before running it

Read the repository's setup instructions. Installation imports the workflow
files; it does not run setup scripts, install packages, initialize databases,
configure API credentials, create schedules or start tasks.

A workflow that uses external services may need:

- Helper tools and their dependencies installed and built.
- Paths configured for your machine rather than the author's home directory.
- Access to the required catalogue, APIs and model providers.
- Fresh application state or a documented import of an authorized dataset.
- Separate scheduling and delivery configuration.

A successful `workflow validate` checks the workflow graph. It does not prove
those runtime dependencies are ready. Complete the repository's setup steps
before creating a task.

## Edit and maintain an imported workflow

Direct Git imports are project-authored workflows with authored-project
permissions. Review the source before running it. They do not carry a
Honeycomb catalogue review, and managed Honeycomb `workflow update` and
`workflow remove` do not manage them.

After editing the imported files, validate and commit your changes:

```sh
hive workflow validate weekly-news --json
hive workflow commit weekly-news
```

Automatic upstream update and merge are not implemented. Keep local edits and
review upstream changes explicitly; reinstalling will not overwrite them.
