---
title: Concepts
layout: doc
nav_order: 2
permalink: /docs/concepts/
description: How task folders, stage outputs, markers, and recorded state keep Hive workflows inspectable and recoverable.
---

# Concepts
{: .no_toc }

A task is a folder of inputs and outputs. Its current stage determines what
happens next, and markers record whether an agent is working, waiting, or done.
A **workflow** defines those stages and their instructions.

Hive includes `coding` (idea to pull request), `content` (research to article),
and `bench` (evaluation campaigns). You can also define a workflow per project.
This guide uses the default `coding` workflow to explain the shared mechanics.
See [Custom workflows]({{ '/docs/custom-workflows/' | relative_url }}) for authoring.

1. TOC
{:toc}

## Folder as agent

A Hive task is a directory that keeps its inputs and outputs together: the
original idea, brainstorm rounds, the plan, execution notes, review files, PR metadata,
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

## Durability and recovery

The task outlives an individual agent attempt. Stage artifacts remain readable
files under `.hive-state/`, alongside task history. Hive also uses a
**machine-local SQLite runtime control plane** for attempts, delivery, leases,
and coordination.

Recorded state, guarded retries, and explicit recovery requests let work
continue after interruptions. The current stage may run again using saved
inputs. Some failures are blocked for human intervention; this is not arbitrary
in-process checkpointing, deterministic code replay, or a guarantee of
exactly-once external effects. Local durability also does not replace backups.

A workflow can include a real `kind: human` stage: approval completes a result,
or rejection returns the same task to an earlier stage. See the
[human approval example](/docs/custom-workflows/#human-approval). A decision to
approve an artifact does not, on its own, publish or send it.

Use the native web UI, TUI, or CLI to inspect the current task, its artifacts,
and recovery state. Git worktrees separate coding work, but they are not a
security sandbox. Tool permission support depends on the selected agent.

## The nine stages: the `coding` workflow

The stages below are Hive's built-in **`coding`** workflow. A different workflow
(`content`, or one you author) defines its own stages — but the mechanics are
shared: each stage has a folder, the agent reads prior artifacts and writes
its output, and markers record readiness for the next handoff.

```text
1-inbox → 2-brainstorm → 3-plan → 4-execute → 5-open-pr → 6-review → 7-artifacts → 8-finalize → 9-done
capture     refine        design    build       draft PR    harden     collect       publish      archive
```

| Stage | What happens |
|-------|--------------|
| **1-inbox** | The capture stage. `hive new` writes `idea.md`. No agent runs in the inbox; an enrolled daemon can advance ready tasks. |
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

Each Hive project keeps an **LLM-maintained wiki**: a `wiki/` directory of
Markdown pages, cataloged in `wiki/index.md` and cross-linked with
`[[backlinks]]`. It records the project's architecture, modules, conventions,
and decisions for later tasks.

Agents read relevant pages before starting work and record what they learn in
new pages or append-only changelog fragments under `wiki/log.d/`. This gives
the next task access to established patterns and the reasons behind decisions.

It's searchable: Hive ships a managed indexer (QMD), so you or an agent can run
`qmd search "<topic>"` to find relevant wiki pages. The changelog is rebuilt
from those fragments with
[`hive wiki compile-log`]({{ '/docs/commands/wiki/' | relative_url }}), which
keeps concurrent edits from colliding on a single file.

## What Hive is not

- It is not a Kanban board.
- It is not a CI replacement.
- It is not a central tracker.

---

Next: see [Configuration]({{ '/docs/configuration/' | relative_url }}) for the
settings that shape each stage, or the [Command reference]({{ '/docs/commands/' | relative_url }})
for the verbs that drive them.
