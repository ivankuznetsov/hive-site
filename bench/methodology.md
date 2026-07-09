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

One cell on the board is one corpus task run by one candidate. A **candidate**
is a model configuration for hive's stages — `all-opus-4.8`, `all-glm-5.2`, or
a mixed pair like `glm-plan→kimi-exec`, where one model plans and another
implements. The cell runs the **real hive pipeline** — plan (`/ce-plan`) →
execute → open-pr → review with hive's production review config — inside an
isolated, resource-capped container, seeded with the task's frozen idea and
brainstorm, with the repo rewound to the task's base commit.

The candidate never sees the reference solution. The container has a
bench-local git origin and a stubbed `gh`, and every cell's logs are scanned
for reference-PR access.

## How a diff is scored

The final post-review diff is graded against the merged reference PR by two
independent blind judges — `gpt-5.5-pro` and `fable-5` — on an absolute 0–10
rubric: does this accomplish the task? The merged PR is provided to the judges
as a signal; a candidate is never scored on how closely it matches it, and
verbosity is explicitly not rewarded.

## Judge integrity

The two judges score on different scales — `fable-5` runs 1–2 points more
generous than `gpt-5.5-pro` across the board — so the leaderboard never mixes
their scores into one ranking. Each judge gets its own table over every
candidate. Where a judge shares a model family with a candidate
(`gpt-5.5-pro` with the codex candidates, `fable-5` with the opus ones), the
row is flagged same-family rather than hidden: the score is shown, the
self-preference risk is named. An external design review (gpt-5.5-pro itself,
via API — transcript in the repo under `reviews/`) caught that an earlier
presentation mixed the two scales into one "cross-family" column; the
single-ruler tables replaced it.

Each table carries two aggregates: **quality** (mean over completed runs) and
**end-to-end** (mean over all attempted tasks, failures scored 0) — the second
is intention-to-treat, so a configuration that fails to finish is penalized
instead of being averaged over its survivors.

A deliberation diagnostic makes the judges exchange anonymized verdicts and
check each other's claims against the diff. Across 15 discussed verdicts,
gpt-5.5-pro's mean revision was 0.00; fable-5 revised only downward, and only
after verifying gpt's claims against the diff. The leaderboard keeps the
independent scores; the deliberation transcripts ship with the repo.

Model claims are verified, too: every cell's agent stream logs are
cross-checked against the candidate's claimed models. On the published board
that is 101 substantive stage logs and 0 violations.

## What a run costs

A full-cycle run on the open models comes to about $13 per task — roughly 4×
the cost of a bare execute — because the review stage re-reads the accumulated
context, around 49M cache-read tokens per task.

## Known limitations (read the numbers against these)

- **Single-author, Ruby/CLI corpus, n=6.** Every task comes from my repo. The
  claim is "best on this corpus", not best on software in general.
- **Judge-scored only.** No curated test gates yet, so there is no objective
  pass/fail floor under the judge scores. (The gate machinery exists; it
  requires positively-observed per-test results once curation lands.)
- **Mostly a single judge seed.** Stability intervals collapse at one sample;
  small gaps between candidates are not meaningful.
- **Post-review gold.** Candidates are judged against merged, human-reviewed
  PRs, so a score reads as distance from mergeable.
- **Named exclusions.** I excluded `glm-plan→kimi-exec` on install and
  fix-tmux after two funded, reproducible execute failures each; the pair also
  failed web-install (empty diff) and daemon (at execute). Every other hole on
  the board is labeled with its cause — subscription limit windows or budget
  caps — never silently dropped.
- **Availability shapes coverage.** Subscription candidates (opus) are bound
  to limit windows; per-token candidates can always be re-run. Coverage
  differences are disclosed per row.

## Reproducibility

Every cell records harness and model versions, run status, telemetry, and both
judges' scores. The corpus, the harness, the deliberation transcripts, and the
canonical `results.json` are public at
[hive-bench](https://github.com/ivankuznetsov/hive-bench).

</div></section>
