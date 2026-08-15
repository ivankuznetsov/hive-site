---
layout: home
title: hive-bench methodology & limitations
nav_exclude: true
description: How 78 hive-bench runs measured coding agents across planning, implementation, pull requests, review, and fixes—and how to read the limits.
permalink: /bench/methodology/
---

<section class="bench-doc"><div class="wrap" markdown="1">

# Methodology & limitations

## What one cell measures

One cell is one corpus task run by one candidate configuration. The published
board has six tasks and thirteen candidates across four completed campaigns, for
**78 generated cells**. A candidate can use one model across the workflow or
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
CI command or browser test was configured for these campaigns.

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
      <th scope="row">Sol plan &rarr; Sol execute &rarr; Sol + Grok review</th>
      <td>Plan: Sol xhigh;<br>Implement: Sol high;<br>PR, triage, fix: Sol xhigh</td>
      <td><code>codex-ce-code-review</code> using Sol xhigh and <code>grok-ce-code-review</code> using Grok 4.5 xhigh</td>
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
      <th scope="row">Sol plan &rarr; Terra execute &rarr; Grok review</th>
      <td>Plan: Sol xhigh;<br>Implement: Terra xhigh;<br>PR, triage, fix: Grok 4.5 xhigh</td>
      <td><code>grok-ce-code-review</code> using Grok 4.5 xhigh</td>
    </tr>
    <tr>
      <th scope="row">DeepSeek V4 Pro 0813 xhigh</th>
      <td>Plan, implement, PR, triage, fix: DeepSeek V4 Pro 0813 xhigh through Pi/OpenRouter</td>
      <td><code>pi-ce-code-review</code> using DeepSeek V4 Pro 0813 xhigh</td>
    </tr>
    <tr>
      <th scope="row">DeepSeek V4 Pro plan &rarr; V4 Flash execute &rarr; V4 Pro review</th>
      <td>Plan, PR, triage, fix: DeepSeek V4 Pro 0813 xhigh;<br>Implement: DeepSeek V4 Flash 0731 xhigh, all through Pi/OpenRouter</td>
      <td><code>pi-ce-code-review</code> using DeepSeek V4 Pro 0813 xhigh</td>
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

The original publication commit's harness defines the earlier
[candidate stage assignments](https://github.com/ivankuznetsov/hive-bench/blob/122e6473971b6ccf7c3a24e1273fb7cffbbb7631/harness/profiles/candidates.rb)
and [review-panel derivation](https://github.com/ivankuznetsov/hive-bench/blob/122e6473971b6ccf7c3a24e1273fb7cffbbb7631/harness/lib/hive_config.rb).
The two production-panel rows and the two dated DeepSeek rows come from later
pre-registered campaigns. The DeepSeek campaign serializes its exact Pro 0813
and Flash 0731 OpenRouter pins. Earlier evidence bundles do not bind every
result to a harness revision or contain each resolved `config.yml`, so the
table documents the publication records, not independently serialized
per-cell configuration provenance for every older row.

## Current scoring

Two judges independently score every final diff from 0–10 against the task and
merged reference:

- **Fable 5**, pinned to `xhigh` in the first three campaign records. It ran
  with reasoning enabled for the DeepSeek campaign, but that record did not
  serialize an exact effort level.
- **GPT-5.6 Sol**, pinned to `xhigh` for the original campaign and `ultra` for
  all three three-seed follow-ups.

The merged PR tells a judge what the task ultimately required; candidates are
not rewarded for textual or structural similarity. The original 36 cells have
one score sample per judge; the 42 cells in the three later campaigns have three
samples per judge. The bold independent score for the original rows and
independent three-sample mean for the later rows remain the leaderboard's
primary
evidence. The public summary table opens ordered by the paired discussion-final
mean, while the independent scores remain visible and sortable. All 78 cells
then received an adversarial deliberation pass. The secondary **discussion
final** is a separate one-shot diagnostic run with
campaign-specific round-one provenance. The original campaign reused its exact
published independent verdicts and rationales recovered from exact local
provider sessions; all three three-seed follow-ups freshly re-graded round one.
In all four campaigns, each judge then received the other judge's verdict
anonymously, argued the strongest evidence-based case that its own view was
wrong, and held or revised. It is not an adjustment applied to the independent
score or mean.

The site publishes all 156 discussion-final judge decisions across all 78
cells. Reusing the original campaign's published initial verdicts means its
round two did not rerun independent scoring. Sol's originally interrupted
second-round decision for the Fable-plan/Grok-execute `daemon` follow-up cell
was also recovered by replaying only round two from the preserved pair of
round-one verdicts, plan, diff, and reference.
Discussion finals do not replace the independent leaderboard because exposing
verdicts can add anchoring or convergence pressure even when it also surfaces
genuine misses. The default **After discussion** sort orders all thirteen rows by
their paired final mean; choosing it as the presentation default does not
rewrite the independent scores. The per-task board displays Fable before Sol
for both layers.

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

All 78 candidate runs produced scoreable patches, with no pending or failed
generation cells. All 78 exact final patches are public. The 42 cells across
the three three-seed campaigns also publish their complete score samples and
intervals in the site snapshot. Every objective-gate
record is `no_gate`: the corpus does not yet have curated held-out tests
suitable for a fair candidate-independent pass/fail claim. The current numbers
are judge evidence, not test-pass rates.

The site links every score to a machine-readable record. For the original
campaign, the manifest, complete merged `results.json`, exact candidate patches,
and evidence directories are public in
[hive-bench](https://github.com/ivankuznetsov/hive-bench/tree/main/runs/v2-ce).
The three follow-ups' three-sample distributions are included in the site's
[data snapshot]({{ '/bench/results.json' | relative_url }}), and every later
cell links directly to its candidate patch. Raw provider streams, build logs,
target clones, and auth material remain unpublished.

## Time, tokens, and cost

Wall time is recorded per task where recoverable. The original campaign has 32
timed cells; the first three-seed follow-up has 14, the production-panel
follow-up has all 12, and the DeepSeek campaign has 9. A displayed time mean
uses only those recorded cells and always shows its sample count.

For the original campaign, generation tokens and API-equivalent costs are
recomputed uniformly from per-event stage logs with `HiveBench::TokenReport`.
Session-cumulative `result` and `system` events are excluded rather than counted
again. Codex usage is normalized by subtracting `cached_input_tokens` from its
inclusive input count, then pricing cached and uncached input separately. Event
model ids provide the first attribution signal; stages provide the fallback for
Codex events that do not carry a model id. Claude's internal Haiku utility calls
remain a separate priced model instead of being charged at the Opus rate.

The first follow-up retains the per-event stage logs used by `HiveBench::TokenReport`.
Five of the six Sol-plan/Terra-execute cells preserve complete Codex events, so
the site publishes their normalized token splits and API-equivalent costs. The
recovered `fix-review` artifact retains only aggregate inclusive-input usage;
its missing cached-input split makes its comparable tokens and price unknown.
Grok emits no usable token events through this runner. The two Grok-execution
rows therefore publish explicitly labeled **known-provider subtotals**, never
complete workflow totals. Sol-plan/Grok-execute/Sol-review includes retained Sol
plan/review usage for all six tasks. Fable-plan/Grok-execute/Sol-review includes
Fable planning for all six tasks plus retained Sol review events where present.
The production-panel campaign retains comparable Sol/Terra events for all 12
cells. Sol-plan/Terra-execute/Grok-review therefore publishes Sol plus Terra
subtotals; the production-like Sol/Sol/Sol+Grok configuration publishes its Sol
stage subtotal. Grok reviewer usage remains absent from both. No Grok usage is
imputed.

The DeepSeek campaign ran through Pi/OpenRouter with dated model pins. Its
serialized telemetry preserves complete input, output, cache-read, and cost
data for 11 of 12 cells and wall time for 9. The all-Pro `fix-tmux` cell has no
usable efficiency record, so its values remain unknown. Costs use the
campaign's `2026-08-12-openrouter` usual-tier rates: Pro 0813 at
$0.435/$0.87/$0.003625 per million input/output/cached-input tokens, and Flash
0731 at $0.08/$0.18/$0.016. Judge usage remains excluded.

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

Costs use versioned usual-tier tables (`2026-06-usual` for the earlier
publication and `2026-08-12-openrouter` for DeepSeek) and are descriptive
API-equivalent estimates, not a billing claim. Judge usage is excluded. Grok's
runner emits no usable token events, so workflows that use Grok keep
their complete-workflow token totals and cost fields **unknown**, not zero. The
displayed known-provider token and cost subtotals are explicitly marked
**partial** and are not used to claim a full-workflow price or cost-sort value.
No missing value is imputed from another provider or model.

## Known limitations

- **Small, single-project corpus.** Six Ruby/CLI tasks from one repository do
  not support a universal "best coding model" claim.
- **Mixed sampling depth.** The original 36 cells have one sample per primary
  judge; the 42 later cells have three. Stability intervals therefore exist
  only for the later rows, and close gaps in the original cohort may reverse.
- **No objective gates.** Human-aligned judge scoring is the only current
  quality signal.
- **Judge-family overlap.** Several earlier follow-up candidates use Sol for at
  least one production stage and are judged by Sol; the Fable-planned candidate
  is also judged by Fable. The two DeepSeek rows are family-disjoint from both
  judges. Flags disclose overlap where present but cannot remove the bias.
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
