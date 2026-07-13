---
layout: home
title: hive-bench methodology & limitations
nav_exclude: true
description: How the 36-cell hive-bench v2-ce campaign was run, scored, and published, and the limits on its preliminary findings.
permalink: /bench/methodology/
---

<section class="bench-doc"><div class="wrap" markdown="1">

# Methodology & limitations (v2-ce)

## What one cell measures

One cell is one corpus task run by one candidate configuration. The published
campaign has six tasks and six candidates, for **36 generated cells**. A
candidate can use one model across the workflow or split stages between models;
for example, `opus-plan->codex-exec-xhigh` uses Opus to plan and review and
Codex 5.5 xhigh to execute.

Each task is a real completed Hive task with a merged reference PR. The runner
rewinds a source clone to the task's base commit and supplies its frozen
candidate-visible inputs. The candidate does not receive the reference patch.
It then runs the real Hive cycle in an isolated runner: planning,
implementation, a sandbox-local pull request, and Hive's production review and
fix loop. The scored artifact is the final post-review candidate diff, not an
intermediate answer or a reimplemented approximation of Hive.

## Current scoring

Two judges independently score every final diff from 0–10 against the task and
merged reference:

- **Fable 5**, reasoning effort not exposed by the runner.
- **GPT-5.6 Sol**, explicitly pinned to `xhigh` reasoning.

The merged PR tells a judge what the task ultimately required; candidates are
not rewarded for textual or structural similarity. Each primary judge has one
score sample per cell. The per-task board displays `Fable / Sol` in that order.

Judge calibrations are not interchangeable, so there is no average across
Fable and Sol. The site publishes one complete six-candidate table for each
judge. A row is marked **same-family** when the judge shares a model family with
any model in the candidate configuration. Those scores remain visible but
should be treated as weaker evidence because self-preference cannot be ruled
out.

GPT-5.5 Pro is a historical supplemental ruler. It scored only one cell for
Codex 5.5 xhigh, GLM 5.2, and Grok 4.5. Those three observations are shown in a
separate partial table and are not used to rank the full slate.

## Coverage and objective evidence

All 36 candidate runs produced scoreable patches, and all 36 exact patches are
published. There are no pending or failed generation cells in the canonical
result. Every objective-gate record is `no_gate`: the corpus does not yet have
curated held-out tests suitable for a fair candidate-independent pass/fail
claim. The current numbers are judge evidence, not test-pass rates.

The site links every score to its machine-readable cell result and exact
candidate patch. The campaign manifest, complete merged `results.json`, and
all evidence directories are public in
[hive-bench](https://github.com/ivankuznetsov/hive-bench/tree/main/runs/v2-ce).

## Time, tokens, and cost

Wall time is recorded per task where recoverable. Four Sol cells, five Grok
cells, five mixed Opus/Codex cells, and all six cells for the remaining
candidates have usable timing evidence. A displayed time mean uses only those
recorded cells and always shows its sample count.

Generation tokens and API-equivalent costs are recomputed uniformly from the
per-event stage logs with `HiveBench::TokenReport`. Session-cumulative `result`
and `system` events are excluded rather than counted again. Codex usage is
normalized by subtracting `cached_input_tokens` from its inclusive input count,
then pricing cached and uncached input separately. Event model ids provide the
first attribution signal; stages provide the fallback for Codex events that do
not carry a model id. Claude's internal Haiku utility calls remain a separate
priced model instead of being charged at the Opus rate.

That per-model attribution makes the mixed candidate priceable: across all six
tasks, Codex 5.5 contributes $67.3351, Opus 4.8 contributes $47.6319, and Haiku
utility calls contribute $0.6159, for **$115.5829 total or an average of
$19.26 per task**.
The site also publishes every task-level cost, normalized token count, and
recorded wall time rather than only the mean.

Costs use the versioned `2026-06-usual` price table and are descriptive
API-equivalent estimates, not a billing claim. Judge usage is excluded. Grok's
runner emits no usable token events, so its token and cost fields remain
**unknown**, not zero. No missing value is imputed from another provider or
model.

## Known limitations

- **Small, single-project corpus.** Six Ruby/CLI tasks from one repository do
  not support a universal "best coding model" claim.
- **One sample per primary judge-cell.** There are no useful stability
  intervals yet; small gaps may reverse under repeated judging.
- **No objective gates.** Human-aligned judge scoring is the only current
  quality signal.
- **Judge-family overlap.** Sol candidates are judged by Sol, while Opus and
  the mixed candidate are judged by Fable. Flags disclose this but cannot
  remove the bias.
- **Corpus provenance can frame the task.** All original task plans were
  Claude-authored, even though candidates re-ran the workflow themselves.
- **Recovered telemetry is incomplete.** Some finished cells predate complete
  wall-time capture, and Grok exposes no usable token stream. The site labels
  every affected task cell and aggregate.
- **Post-merge references.** The reference PRs are human-reviewed outcomes.
  They are strong task evidence, but model training contamination cannot be
  ruled out for already-public PRs.

The scoped claim is therefore: **what these configurations shipped through
the full Hive workflow on this corpus**, not which model is universally best.

## Follow-up campaign (not part of these scores)

The native `bench` Hive workflow now defaults new campaigns to three
independent samples per judge and cell, Fable 5 plus GPT-5.6 Sol at `ultra`,
judging against the candidate-generated plan, and a diagnostic deliberation
round in which each judge must make the strongest evidence-based case against
its own initial score. Deliberated scores do not replace the independent
leaderboard values.

Those settings describe the follow-up campaign only. The current website keeps
the v2-ce provenance exact: Sol `xhigh`, one sample per primary judge-cell, and
no claim that the future three-sample results already exist.

The workflow runs as a normal Hive custom workflow. Hive owns its daemon,
locking, retry behavior, stable task ordering, and global/per-project
concurrency; hive-bench does not add a parallel shell scheduler.

</div></section>
