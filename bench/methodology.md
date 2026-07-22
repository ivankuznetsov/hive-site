---
layout: home
title: hive-bench methodology & limitations
nav_exclude: true
description: How 54 hive-bench runs measured coding agents across planning, implementation, pull requests, review, and fixes—and how to read the limits.
permalink: /bench/methodology/
---

<section class="bench-doc"><div class="wrap" markdown="1">

# Methodology & limitations

## What one cell measures

One cell is one corpus task run by one candidate configuration. The published
board has six tasks and nine candidates across two completed campaigns, for
**54 generated cells**. A candidate can use one model across the workflow or
split stages between models; for example,
`sol-plan->grok-exec-sol-review` uses Sol to plan and review and Grok to
execute.

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
      <th scope="row">Sol plan &rarr; Grok execute &rarr; Sol review</th>
      <td>Plan, PR, triage, fix: Sol xhigh;<br>Implement: Grok 4.5 xhigh</td>
      <td><code>codex-ce-code-review</code> using Sol xhigh</td>
    </tr>
    <tr>
      <th scope="row">Sol plan &rarr; Terra execute &rarr; Sol review</th>
      <td>Plan, PR, triage, fix: Sol xhigh;<br>Implement: Terra xhigh</td>
      <td><code>codex-ce-code-review</code> using Sol xhigh</td>
    </tr>
    <tr>
      <th scope="row">Fable plan &rarr; Grok execute &rarr; Sol review</th>
      <td>Plan: Fable 5 high;<br>Implement: Grok 4.5 xhigh;<br>PR, triage, fix: Sol xhigh</td>
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
  in either benchmark record.
- **GPT-5.6 Sol**, pinned to `xhigh` for the original campaign and `ultra` for
  the mixed-workflow follow-up.

The merged PR tells a judge what the task ultimately required; candidates are
not rewarded for textual or structural similarity. The original 36 cells have
one score sample per judge. The 18 mixed-workflow cells have three samples per
judge plus an adversarial deliberation pass. The bold independent three-sample
means enter the leaderboard and control sorting. The secondary **discussion
final** is a separate one-shot diagnostic run: each judge first re-grades the
cell, then sees the other judge only as an anonymous referee with a score and
rationale, must argue the strongest evidence-based case that its own fresh
verdict is wrong, and finally holds or revises. It is not an adjustment applied
to the three-sample mean.

The site publishes 35 of 36 discussion-final judge decisions across all 18
follow-up cells. The missing Sol decision for the Fable-plan/Grok-execute
`daemon` cell is shown as unavailable and is not imputed. Discussion finals do
not replace the independent leaderboard because exposing verdicts can add
anchoring or convergence pressure even when it also surfaces genuine misses.
The per-task board displays `Fable / Sol` in that order for both layers.

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

All 54 candidate runs produced scoreable patches, with no pending or failed
generation cells. The original 36 exact patches are public. The 18
mixed-workflow rows currently publish their complete score samples and
intervals in the site snapshot, but not their raw patches. Every objective-gate
record is `no_gate`: the corpus does not yet have curated held-out tests
suitable for a fair candidate-independent pass/fail claim. The current numbers
are judge evidence, not test-pass rates.

The site links every score to a machine-readable record. For the original
campaign, the manifest, complete merged `results.json`, exact candidate patches,
and evidence directories are public in
[hive-bench](https://github.com/ivankuznetsov/hive-bench/tree/main/runs/v2-ce).
The follow-up's three-sample distributions are included in the site's
[data snapshot]({{ '/bench/results.json' | relative_url }}); its raw-evidence
bundle remains unpublished.

## Time, tokens, and cost

Wall time is recorded per task where recoverable. The original campaign has 32
timed cells; the mixed-workflow follow-up has 14. A displayed time mean uses
only those recorded cells and always shows its sample count.

For the original campaign, generation tokens and API-equivalent costs are
recomputed uniformly from per-event stage logs with `HiveBench::TokenReport`.
Session-cumulative `result` and `system` events are excluded rather than counted
again. Codex usage is normalized by subtracting `cached_input_tokens` from its
inclusive input count, then pricing cached and uncached input separately. Event
model ids provide the first attribution signal; stages provide the fallback for
Codex events that do not carry a model id. Claude's internal Haiku utility calls
remain a separate priced model instead of being charged at the Opus rate.

The follow-up retains the per-event stage logs used by `HiveBench::TokenReport`.
Five of the six Sol-plan/Terra-execute cells preserve complete Codex events, so
the site publishes their normalized token splits and API-equivalent costs. The
recovered `fix-review` artifact retains only aggregate inclusive-input usage;
its missing cached-input split makes its comparable tokens and price unknown.
Grok emits no usable token events through this runner. The two Grok-execution
rows therefore publish explicitly labeled **Sol-only subtotals**, never complete
workflow totals: Sol-plan/Grok-execute/Sol-review has retained Sol plan/review
usage for all six tasks, while Fable-plan/Grok-execute/Sol-review has retained
Sol review usage for two. The latter also excludes Fable planning so its label
describes one consistent provider scope. Missing Sol completions are not
estimated, and no Grok usage is imputed.

All displayed wall times come from the corresponding serialized
`wall_clock_sec` values. The per-event source logs used to reconstruct normalized
token splits and costs are not public. Those displayed values are available in
the site's [data snapshot]({{ '/bench/results.json' | relative_url }}), but
visitors cannot yet independently rerun that accounting from the public
evidence bundle.

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
runner emits no usable token events, so workflows that execute with Grok keep
their complete-workflow token totals and cost fields **unknown**, not zero. The
displayed Sol-only subtotals are provider-scoped usage evidence and are not used
to claim a full-workflow price. No missing value is imputed from another
provider or model.

## Known limitations

- **Small, single-project corpus.** Six Ruby/CLI tasks from one repository do
  not support a universal "best coding model" claim.
- **Mixed sampling depth.** The original 36 cells have one sample per primary
  judge; the 18 follow-up cells have three. Stability intervals therefore exist
  only for the follow-up rows, and close gaps in the original cohort may reverse.
- **No objective gates.** Human-aligned judge scoring is the only current
  quality signal.
- **Judge-family overlap.** Every follow-up candidate uses Sol for at least one
  production stage and is judged by Sol; the Fable-planned candidate is also
  judged by Fable. Flags disclose this but cannot remove the bias.
- **Follow-up raw patches are not public yet.** Their independent samples and
  intervals are in the site snapshot, but direct code-level audit remains
  available only for the original 36 cells.
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
