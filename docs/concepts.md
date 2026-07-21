---
title: Concepts
layout: doc
nav_order: 2
permalink: /docs/concepts/
description: The load-bearing ideas behind Hive — folder-as-agent, the stage state machine, and the marker protocol — and how built-in, installable, and owner-authored workflows ride on top of them.
---

# Concepts
{: .no_toc }

Hive has three load-bearing ideas: a task is a folder, stage folders form a
state machine, and every stage writes an artefact that lets the next stage run
with less ambiguity.

Those three are the **engine**. *Which* stages exist, and what each one does, is
defined by a **workflow** — and Hive runs more than one. It ships three built-in
workflows: `coding`, the nine-stage idea → PR pipeline described below (its
flagship, and the default `hive init` selects); `content`, a research and
writing pipeline; and `bench`, a reproducible agent-benchmark workflow. You can
also install reviewed [Honeycombs]({{ '/honeycombs/' | relative_url }}) or author
your own per project — see [Custom workflows]({{ '/docs/custom-workflows/' | relative_url }}). Everything in
this page applies to any workflow; `coding` is just the most involved, so it's
the one worth walking through in full.

1. TOC
{:toc}

## Folder as agent

A Hive task is not a ticket row or a single markdown blob. It is a directory
that accumulates the artefacts needed to keep work inspectable: the original
idea, brainstorm rounds, the plan, execution notes, review files, PR metadata,
logs, and a feature-worktree pointer.

The folder's location **is** the task state. Moving a task from `2-brainstorm/`
to `3-plan/` is the approval gesture; running `hive plan <slug>` does the same
move with marker checks, locking, JSON support, and a state-branch commit.

```text
<project>/.hive-state/stages/6-review/<slug>/
├── idea.md
├── brainstorm.md
├── plan.md
├── task.md
├── pr.md
├── worktree.yml
└── reviews/
    ├── claude-ce-code-review-01.md
    ├── codex-ce-code-review-01.md
    ├── pr-review-toolkit-01.md
    └── escalations-01.md
```

## The nine stages: the `coding` workflow

The stages below are Hive's built-in **`coding`** workflow. A different workflow
(`content`, `bench`, an installed Honeycomb, or one you author) defines its own stages — but the mechanics are
identical: each stage is a folder, the agent reads the prior artefacts and writes
this stage's, and a marker negotiates the handoff. `coding` is the deepest of the
built-ins, so it's the clearest illustration of the whole protocol.

```text
1-inbox → 2-brainstorm → 3-plan → 4-execute → 5-open-pr → 6-review → 7-artifacts → 8-finalize → 9-done
capture     refine        design    build       draft PR    harden     collect       publish      archive
```

| Stage | What happens |
|-------|--------------|
| **1-inbox** | The capture stage. `hive new` writes `idea.md`; nothing runs automatically yet. |
| **2-brainstorm** | The brainstorm agent reads `idea.md` and writes `brainstorm.md`, usually pausing to ask you questions, then marking the requirements clear. |
| **3-plan** | The plan agent reads `brainstorm.md` and writes `plan.md`, fixing scope, implementation units, verification, and risks before any code work. |
| **4-execute** | Creates an isolated feature worktree, writes `worktree.yml`, spawns the implementation agent, and finishes only when there's a clean new commit. |
| **5-open-pr** | Pushes the task branch and opens a **draft** GitHub PR — a normal entry point for humans and reviewers before autonomous review starts. |
| **6-review** | Runs the autonomous loop: CI fix, reviewers, triage, fix, guardrail, and an optional browser test. It pauses at human-input or recovery gates. |
| **7-artifacts** | The collection handoff after review — the artifact agent writes `artifact.md` for release-packaging and handoff work. |
| **8-finalize** | Verifies the branch is clean and pushed, refreshes the PR body, writes `summary.md`, and marks the draft PR ready. |
| **9-done** | Archives the task and prints manual cleanup commands for the feature worktree and branch. |

## Markers as the protocol

Markers are HTML comments at the bottom of a stage's state file. **The last
marker wins.** They are how a stage agent and the runner negotiate handoff.

| Marker | Meaning |
|--------|---------|
| `<!-- AGENT_WORKING pid=N started=ISO -->` | A stage agent is running. |
| `<!-- WAITING -->` | The agent needs human input in the file. |
| `<!-- COMPLETE -->` | The stage is ready for promotion. |
| `<!-- ERROR reason=... -->` | The runner or agent failed and needs investigation. |
| `<!-- EXECUTE_WAITING reason=... -->` | Execute paused without a clean implementation commit. |
| `<!-- EXECUTE_COMPLETE -->` | Execute produced a clean task-branch commit. |
| `<!-- REVIEW_WAITING ... -->` | Review needs human triage or guardrail approval. |
| `<!-- REVIEW_COMPLETE ... -->` | Review is done and the task can collect artifacts. |

Human edits are part of the protocol. You can open `brainstorm.md`, `plan.md`,
a `reviews/escalations-NN.md` file, or a recovery file in a normal editor, make
your changes, and re-run the same stage command. The agent picks up where you
left off.

## Compound engineering in practice

Compound engineering means structuring software work so each stage leaves
behind a durable result the next stage can trust. The term comes from
[Kieran Klaassen's work at Every](https://every.to/source-code/compound-engineering-the-definitive-guide) —
the idea that each unit of engineering work should make the next one easier, not
harder. Hive applies that to agent work by making every transition explicit and
every intermediate artefact reviewable.

Brainstorm pins requirements so the planner has fewer product unknowns. Plan
fixes implementation scope so the execute agent can focus on code. Execute
commits in a feature worktree so review can inspect a real diff. Review turns
findings into accepted fixes or escalations, and finalize ships the PR with the
trail still attached.

The trade-off is more intermediate files than a chat-only workflow. The benefit
is that a human can intervene at any stage with a normal editor instead of
trying to steer a long-running conversation.

## Knowledge sharing: the LLM wiki

Compounding doesn't stop at a single task. Each Hive project keeps an
**LLM-maintained wiki** — a `wiki/` directory of markdown pages, cataloged in
`wiki/index.md` and cross-linked with `[[backlinks]]`, capturing the project's
architecture, modules, conventions, and decisions. It's written for agents to
read and kept current as work lands.

The point is that knowledge accumulates instead of evaporating when a
conversation ends. The convention is simple: an agent reads the relevant wiki
pages before it starts — inheriting established patterns, past gotchas, and the
*why* behind decisions — and files what it learns back, either as new pages or
as an append-only changelog fragment under `wiki/log.d/`. Over time the project
gets *cheaper and safer* to work in, because every task starts with more context
than the last.

It's searchable: Hive ships a managed indexer (QMD), so you or an agent can run
`qmd search "<topic>"` and get the answer straight from the wiki instead of
re-deriving it. The changelog is rebuilt from those fragments with
[`hive wiki compile-log`]({{ '/docs/commands/wiki/' | relative_url }}), which
keeps concurrent edits from colliding on a single file.

## What Hive is not

- It is not a Kanban board.
- It is not a CI replacement.
- It is not a central tracker.

---

Next: see [Configuration]({{ '/docs/configuration/' | relative_url }}) for the
knobs that shape each stage, or the [Command reference]({{ '/docs/commands/' | relative_url }})
for the verbs that drive them.
