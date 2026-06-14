---
layout: home
title: hive-bench methodology & limitations
nav_exclude: true
description: How hive-bench scores agents, and the limitations you must read the leaderboard against.
permalink: /bench/methodology/
---

<section class="bench-doc"><div class="wrap" markdown="1">

# Methodology & limitations

## What is measured

Each cell is `(corpus task × candidate agent)`. The agent is given only the
frozen spec (idea + brainstorm + plan) — never the reference solution — and runs
in an isolated, resource-capped container. Scoring is three tiers:

1. **Gate (objective floor).** The candidate's diff must build and flip the
   task's `FAIL_TO_PASS` tests while keeping `PASS_TO_PASS` green, in a
   no-network container. Tasks with no runnable gate fall into a separate
   **judged** subset.
2. **Judge.** A blind, family-disjoint LLM scores passing diffs on an absolute
   rubric (the reference is a *signal*, not "closest wins"), across several
   seeds → a stability interval. Verbosity is explicitly not rewarded.
3. **Efficiency.** Cost, review/CI fix-passes, and wall-clock (measured on fresh
   runs only).

## Known limitations (read the number against these)

- **Single-author, Ruby/CLI-weighted corpus.** Tasks come from one maintainer's
  repos. The published distribution shows the language/size mix; the claim is
  scoped to "hive-style work on this corpus," not all software.
- **Plan-author confound.** Replay is *from a frozen plan*, mostly authored by
  the incumbent agents — so the headline is "best **executor** of a frozen
  plan," not "best coding agent." Per-task plan-authorship is published.
- **Incumbent anchoring.** The reference and (for reused cells) the diff come
  from the incumbents. A reference-withheld ablation is run on a held-out subset
  to bound the effect; the delta is published.
- **Judge variance.** A single judge family is used; scores carry a stability
  interval and overlapping intervals are reported as ties. Agents below a
  minimum cell count are marked **preliminary**.
- **Reused cells.** claude/codex cells may reuse recorded outputs (diff + cost +
  fix-passes); their wall-clock is not comparable and is omitted.

## Reproducibility

Every result records the corpus version, each agent's harness + model version,
and the run date. The corpus and harness are public at
[hive-bench](https://github.com/ivankuznetsov/hive-bench).

</div></section>
