---
layout: home
title: Run or contribute to hive-bench
nav_exclude: true
description: Run Hive's built-in benchmark workflow locally or submit a completed task to the public hive-bench corpus.
permalink: /bench/run/
---

<section class="bench-doc bench-doc--detail"><div class="wrap" markdown="1">

# Run hive-bench on your machine

A benchmarkable task is a completed Hive coding task in `9-done` with a merged
GitHub pull request. The merged PR is the held-out reference; candidates receive
the frozen task inputs but never that patch.

You need Docker, Ruby 3.4, authenticated agent CLIs for the candidates and
judges you select, and enough provider quota for complete planning,
implementation, review, and judging runs.

## Select Hive's built-in workflow

[Install Hive]({{ '/#install' | relative_url }}), then initialize a local
benchmark project with the named workflow. You do not need to copy a workflow
descriptor or clone hive-bench to select it.

> **Release status:** the built-in `bench` workflow is currently available in
> [Hive PR #734](https://github.com/ivankuznetsov/hive/pull/734), not in the
> latest `v0.4.1` release. Use a source checkout of that PR until a release
> containing it is published.

```sh
hive init /path/to/benchmark-project --workflow bench
hive new <project-name> "benchmark my task"
hive status
```

The normal Hive daemon owns stage ordering, locking, retry behavior, and
per-project concurrency. Hive stores the versioned benchmark harness in
`.hive-state/bench-runtime`; no separate hive-bench checkout is needed to run
the campaign.

## Extract your completed task

Create the corpus entry from the completed task and its merged reference PR:

```sh
cd /path/to/benchmark-project
ruby .hive-state/bench-runtime/harness/extract.rb \
  --task-dir /absolute/project/.hive-state/stages/9-done/<task-slug> \
  --repo owner/repository \
  --repo-path /absolute/project \
  --out corpus
```

Keep the generated corpus entry local when the task is private. Candidates do
not receive its held-out `reference.patch`.

## Pre-register and run the campaign

Copy the packaged example into the new task folder reported by `hive status`,
then edit it as `campaign.yml`. Pin the
source repository, corpus tasks, candidate ids, judges and reasoning levels,
sample count, timeout, budget declaration, and exclusions before any model
spends tokens. Commit that file inside `.hive-state`; start a new campaign
instead of amending it after generation begins.

```sh
cp /path/to/benchmark-project/.hive-state/bench-runtime/campaign.yml.example \
  /path/to/benchmark-project/.hive-state/stages/1-inbox/<campaign-slug>/campaign.yml

git -C /path/to/benchmark-project/.hive-state add \
  stages/1-inbox/<campaign-slug>/campaign.yml
git -C /path/to/benchmark-project/.hive-state commit \
  -m "Pre-register benchmark campaign"

hive approve <campaign-slug>
hive run <campaign-slug>
```

You may run stages manually or enroll the project in the Hive daemon. One
campaign task processes its matrix in stable order; independent campaign tasks
can run concurrently within Hive's configured limits.

For the campaign contract, candidate profiles, and evidence format, see the
[benchmark workflow reference](https://github.com/ivankuznetsov/hive-bench/blob/main/wiki/v3-workflow.md).

## Submit a task to the public benchmark

Public submission adds a reusable task to the corpus. It does not spend model
quota or immediately change the leaderboard.

```sh
hive bench submit <task-slug>

# Disambiguate the project when the slug exists more than once:
hive bench submit <task-slug> --project <project-name>
```

The task must be in `9-done`, include `worktree.yml` and `pr.md`, belong to a
registered Hive project with a GitHub origin, and point to a merged reference
PR. Review the task for confidential material first: its specification, plan,
provenance, and merged reference diff become public.

The command extracts the corpus entry, runs a local secret-pattern preflight,
and opens a proposal in
[hive-bench](https://github.com/ivankuznetsov/hive-bench). Maintainer-gated CI
then validates structure, provenance, candidate-visible answer leakage,
secrets, and reference reproducibility before the task can join a public
campaign. Submission currently requires a writable checkout of your hive-bench
fork configured with `HIVE_BENCH_PATH`; the separate checkout is for creating
the public corpus PR, not for running the built-in local benchmark workflow.

</div></section>
