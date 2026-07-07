---
layout: home
title: hive-bench methodology & limitations
nav_exclude: true
description: How hive-bench v2 scores agents, and the limitations you must read the leaderboard against.
permalink: /bench/methodology/
---

<section class="bench-doc"><div class="wrap" markdown="1">

# Methodology & limitations (v2)

## What is measured

Each cell is `(corpus task × candidate)`. A **candidate** is a model
configuration for hive's stages (e.g. `all-opus-4.8`, `all-glm-5.2`, or a mixed
pair like `glm-plan→kimi-exec`). The cell runs the **real hive pipeline** —
plan (`/ce-plan`) → execute → open-pr → review with hive's production review
config — inside an isolated, resource-capped container seeded with the task's
frozen idea + brainstorm. The candidate never sees the reference solution; the
container has a bench-local git origin and a stubbed `gh`, and every cell's
logs are scanned for reference-PR access.

**Scoring** is the final post-review diff graded against the merged reference
PR by two independent blind judges (`gpt-5.5-pro`, `fable-5`) on an absolute
0–10 rubric — the reference is a *signal*, not "closest wins", and verbosity is
explicitly not rewarded.

## Judge integrity

Both judge families also compete, so **a judge never counts toward the
headline of a same-family candidate**: `gpt-5.5-pro` headlines the
anthropic-family and open-model candidates, `fable-5` headlines the
openai-family ones; mixed-family candidates get flagged means only.

A **deliberation diagnostic** (judges exchange anonymized verdicts and must
check each other's claims against the diff) found across 15 discussed
verdicts: gpt-5.5-pro's mean revision was 0.00; fable-5 revised only downward,
only on diff-verified facts. The leaderboard keeps independent scores;
deliberation transcripts ship with the repo.

**Model claims are verified**: every cell's agent stream logs are cross-checked
against the candidate's claimed models (101 substantive stage logs, 0
violations in the published board).

## Known limitations (read the number against these)

- **Single-author, Ruby/CLI corpus, n=6.** Tasks come from one maintainer's
  repo. The claim is "best on this corpus", not all software.
- **Judge-scored only.** No curated test gates yet — there is no objective
  pass/fail floor under the judge scores (the gate machinery exists and
  requires positively-observed per-test results when curation lands).
- **Mostly single judge seed.** Stability intervals collapse at one sample;
  small gaps between candidates are not meaningful.
- **Post-review gold vs. pipeline output.** Candidates are judged against
  merged, human-reviewed PRs; scores read as "distance from mergeable".
- **Named exclusions.** `glm-plan→kimi-exec` on install and fix-tmux was
  excluded after two funded, reproducible execute failures each; every other
  hole in the board is labeled with its cause (subscription limit windows or
  budget caps), never silently dropped.
- **Availability shapes coverage.** Subscription-model candidates
  (opus) are limit-window bound; per-token candidates can always be re-run.
  Coverage differences are disclosed per row.

## Reproducibility

Every cell records harness + model versions, run status, telemetry, and both
judges' scores. Corpus, harness, deliberation transcripts, and the canonical
`results.json` are public at
[hive-bench](https://github.com/ivankuznetsov/hive-bench).

</div></section>
