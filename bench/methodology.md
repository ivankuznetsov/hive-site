---
layout: home
title: hive-bench methodology & limitations
nav_exclude: true
description: How 36 hive-bench runs measured coding agents across planning, implementation, pull requests, review, and fixes—and how to read the limits.
permalink: /bench/methodology/
---

<section class="bench-doc"><div class="wrap" markdown="1">

# Methodology & limitations

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
fix loop. The scored artifact is the final captured candidate diff. When review
finalization failed, the harness restored the saved post-execute diff rather
than scoring partial review side effects.

## Workflow and reviewer configuration

[Compound Engineering]({{ '/docs/concepts/#compound-engineering-in-practice' | relative_url }})
powered planning through `/ce-plan`. Implementation then used Hive's normal
plan-driven development stage; it did not invoke `/ce-work`.
Hive opened a benchmark-local pull request and ran its production review,
courageous triage, and fix loop for at most two passes and two hours. No review
CI command or browser test was configured for this campaign.

The production reviewers below were part of the candidate workflow and could
change the diff before scoring. They are separate from the Fable and Sol judges,
which only evaluated the finished artifact afterward.

<div class="bench-table-scroll" role="region" aria-label="Candidate workflow and reviewer configuration" tabindex="0">
<table class="bench-table bench-config-table">
  <thead>
    <tr>
      <th scope="col">Candidate</th>
      <th scope="col">Stage owners</th>
      <th scope="col">Pre-score reviewer panel</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">GPT-5.6 Sol xhigh</th>
      <td>Plan, implement, PR, triage, fix: Sol xhigh</td>
      <td><code>codex-ce-code-review</code> using Sol xhigh</td>
    </tr>
    <tr>
      <th scope="row">Opus plan &rarr; Codex 5.5 xhigh</th>
      <td>Plan, PR, triage, fix: Opus 4.8;<br>Implement: Codex 5.5 xhigh</td>
      <td><code>claude-ce-code-review</code> using Opus; <code>codex-ce-code-review</code> using Codex; <code>pr-review-toolkit</code> using Opus</td>
    </tr>
    <tr>
      <th scope="row">Opus 4.8</th>
      <td>Plan, implement, PR, triage, fix: Opus 4.8</td>
      <td><code>claude-ce-code-review</code> and <code>pr-review-toolkit</code>, both using Opus</td>
    </tr>
    <tr>
      <th scope="row">Grok 4.5 xhigh</th>
      <td>Plan, implement, PR, triage, fix: Grok 4.5 xhigh</td>
      <td><code>grok-ce-code-review</code> using Grok's embedded CE review template</td>
    </tr>
    <tr>
      <th scope="row">Codex 5.5 xhigh</th>
      <td>Plan, implement, PR, triage, fix: Codex 5.5 xhigh</td>
      <td><code>codex-ce-code-review</code> using Codex 5.5 xhigh</td>
    </tr>
    <tr>
      <th scope="row">GLM 5.2</th>
      <td>Plan, implement, PR, triage, fix: GLM 5.2 through Pi</td>
      <td><code>pi-ce-code-review</code> using GLM 5.2 through Pi</td>
    </tr>
  </tbody>
</table>
</div>

The publication commit's harness defines the
[candidate stage assignments](https://github.com/ivankuznetsov/hive-bench/blob/122e6473971b6ccf7c3a24e1273fb7cffbbb7631/harness/profiles/candidates.rb)
and [review-panel derivation](https://github.com/ivankuznetsov/hive-bench/blob/122e6473971b6ccf7c3a24e1273fb7cffbbb7631/harness/lib/hive_config.rb).
The evidence bundle does not bind each result to that harness revision or
contain its resolved `config.yml`, so the table documents the publication code,
not independently serialized per-cell configuration provenance.

## Current scoring

Two judges independently score every final diff from 0–10 against the task and
merged reference:

- **Fable 5**, with reasoning enabled; its exact effort level was not preserved
  in the benchmark record.
- **GPT-5.6 Sol**, explicitly pinned to `xhigh` reasoning.

The merged PR tells a judge what the task ultimately required; candidates are
not rewarded for textual or structural similarity. Each primary judge has one
score sample per cell. The per-task board displays `Fable / Sol` in that order.

Judge calibrations are not interchangeable. The site keeps separate Fable and
Sol columns as the primary evidence and uses their arithmetic mean only as a
presentation aid to sort one compact leaderboard. It is not a third judge or a
claim that the two rulers share a scale. A score is marked **same-family** when
that judge shares a model family with any model in the candidate configuration.
Those scores remain visible but should be treated as weaker evidence because
self-preference cannot be ruled out.

GPT-5.5 Pro is a historical supplemental ruler. It scored only one cell for
Codex 5.5 xhigh, GLM 5.2, and Grok 4.5. Those three observations remain in the
published score data but are not used in the compact leaderboard ranking.

## Coverage and objective evidence

All 36 candidate runs produced scoreable patches, and all 36 exact patches are
published. There are no pending or failed generation cells in the published
score result. Every objective-gate record is `no_gate`: the corpus does not yet
have curated held-out tests suitable for a fair candidate-independent pass/fail
claim. The current numbers are judge evidence, not test-pass rates.

The site links every score to its machine-readable cell result and exact
candidate patch. The campaign manifest, complete merged `results.json`, and
all evidence directories are public in
[hive-bench](https://github.com/ivankuznetsov/hive-bench/tree/main/runs/v2-ce).

## Experimental follow-up cells

The site also publishes six newer cells outside the leaderboard. Five are the
fully dual-judged portion of an unfinished 18-cell mixed-workflow follow-up;
the other is a Kimi K2.7 Code recovery probe. Every published follow-up cell
has three independent Fable 5 samples and three GPT-5.6 Sol samples. The site
snapshot preserves the sample arrays, means, intervals, family-overlap flags,
and available efficiency fields.

The mixed-workflow campaign is not leaderboard-ready: ten generated cells have
only one judge, one cell produced an empty diff, and two remain provider-pending.
Those thirteen cells are intentionally omitted from the site until they have
the same evidence contract. The Kimi probe is also not comparable: it failed
the pull-request and review stages, did not traverse the complete native v3
campaign, and its recovery envelope serialized the wrong corpus version.

These cells therefore provide early comparison and failure evidence without
changing the complete 36-cell v2-ce ranking. Their score summaries are public
in the [site data snapshot]({{ '/bench/results.json' | relative_url }}), while
raw patches and runner artifacts are not yet in the public evidence bundle.

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

All 32 displayed wall times match the corresponding `wall_clock_sec` values in
the published score results. The per-event source logs used to reconstruct the
normalized token split and costs are not public. Those displayed values are
available in the site's [data snapshot]({{ '/bench/results.json' | relative_url }}),
but visitors cannot yet independently rerun that accounting from the public
evidence bundle; older token and cost fields in the score results are not the
source for the current table.

The normalized token total includes four non-overlapping buckets: fresh input,
output, cache reads, and cache creation/writes. The site publishes the split for
every measured candidate/task cell and for each candidate average. “Cache” is
therefore not subtracted from the displayed total: the cache read and write
figures are components of that total. This distinction matters because most of
the observed token volume is cache reuse rather than fresh input.

That per-model attribution makes the mixed candidate priceable: across all six
tasks, Codex 5.5 contributes $67.3351, Opus 4.8 contributes $47.6319, and Haiku
utility calls contribute $0.6159, for **$115.5829 total or an average of
$19.26 per task**.
The site also publishes every task-level cost, token-bucket split, and recorded
wall time rather than only the mean.

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
- **Token and cost source logs are not published.** The normalized site snapshot
  is public, but the underlying provider streams needed to reproduce that
  accounting are intentionally excluded from the evidence bundle. Published
  per-cell wall times remain directly checkable.
- **Post-merge references.** The reference PRs are human-reviewed outcomes.
  They are strong task evidence, but model training contamination cannot be
  ruled out for already-public PRs.

The scoped claim is therefore: **what these configurations shipped through
the full Hive workflow on this corpus**, not which model is universally best.

</div></section>
