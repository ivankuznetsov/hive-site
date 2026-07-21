---
title: How workflows work
layout: doc
nav_order: 2
permalink: /docs/concepts/
description: Understand Hive's reusable workflow definitions, durable task runs, stages, artifacts, checkpoints, and terminal outcomes.
---

# How Hive workflows work
{: .no_toc }

A Hive workflow is a reusable definition of how work should move from an input
to a known outcome. A task run is one brief going through that process. Instead
of asking one agent to hold the whole job in one conversation, Hive gives each
stage durable context, records its result, and advances only when the stage's
status allows it.

This page is the model. When you are ready to write YAML, continue to
[Custom workflows]({{ '/docs/custom-workflows/' | relative_url }}).

1. TOC
{:toc}

## Vocabulary

| Term | Meaning in Hive |
|---|---|
| **Project** | The repository or working directory Hive is attached to. Its `.hive-state/` worktree contains workflow definitions and task runs. |
| **Workflow definition** | A reusable, ordered process: the stage names, instructions or skills, agent settings, artifacts, and outcome. It is not a particular run. |
| **Task run** | One brief moving through one workflow definition. Its task folder accumulates the run's durable context. |
| **Stage** | One bounded step in the ordered process. A stage can run an agent, coordinate people, or remain inert as an entry or terminal point. |
| **Agent and model** | The runner assigned to an active stage and, optionally, the model used there. Different stages can make different choices. |
| **Artifact** | A file produced for people and later stages: research, a draft, a plan, review findings, or another named deliverable. |
| **Marker** | The trailing status in a stage's state file, such as `WAITING`, `COMPLETE`, or `ERROR`. The last marker is the current status. |
| **Checkpoint** | A place where progress depends on recorded status or human judgment. It can advance, pause, retry, or return work for revision. |
| **Outcome** | The workflow's defined end state and deliverable. “The agent stopped” is not an outcome; “approved copy is ready for a human to publish” is. |
| **Honeycomb** | A reviewed, versioned workflow package distributed through the maintained registry. It is different from a built-in workflow and from YAML owned only by one project. |

The important distinction is between the **workflow definition** and a
**task run**. Editing `editorial.yml` changes the reusable process; creating a
task sends one brief through that process and gives it its own folder.

## How a task run moves

1. **An idea enters the workflow.** `hive new` creates a task folder in the
   first stage and writes the brief to that stage's state file.
2. **The current stage reads durable context.** Hive supplies the accumulated
   task artifacts to the assigned agent. A person can inspect the same files
   without reconstructing a chat transcript.
3. **An agent or human produces an artifact.** The stage writes its named
   output and records status in its state file.
4. **A checkpoint decides what happens next.** A complete marker allows Hive
   to advance. A waiting marker pauses for a human. An error can be corrected
   and retried. Revision feedback can send the task back to an earlier stage.
5. **The daemon handles ready work.** It runs active stages and commits safe
   transitions in the background. An operator can still use `hive run` and
   [`hive approve --to`]({{ '/docs/commands/approve/' | relative_url }}) to
   intervene explicitly.
6. **The run reaches its terminal outcome.** The final stage defines what done
   means. It may be inert, or it may be an active stage whose non-empty
   deliverable and complete marker prove the outcome exists.

```text
workflow definition
        │
        ▼
brief → stage reads context → artifact + marker → checkpoint
          ▲                                      │
          ├──────── retry or revision ───────────┤
          │                                      ▼
          └──────────── next stage ←──── advance or human approval
                                                 │
                                                 ▼
                                        defined terminal outcome
```

The folder's location is also state. Moving a task from `2-research/` to
`3-draft/` records the transition in a form a shell, editor, agent, or person
can all understand. Use the CLI for normal movement because it adds marker
checks, locking, idempotency, and a state-branch commit.

## Why durable stages help

| Benefit | The mechanism that provides it |
|---|---|
| **Repeatability** | One versioned workflow definition gives every task the same ordered process and artifact contracts. |
| **Auditability** | Recorded transitions make the run auditable; named artifacts preserve its inputs, decisions, and outputs. |
| **Interruption-safe resumption** | Durable files make resumption safe after a closed terminal, provider reset, or restarted daemon; the next run reads the folder again. |
| **Bounded autonomy** | Markers and human checkpoints let automation continue where the rule is clear and pause where judgment is required. |
| **Stage-specific execution** | Each stage can select an appropriate agent, model, budget, timeout, and enforceable permission scope. |
| **Reusable team process** | Review rules and handoffs live in the definition instead of being remembered or rebuilt in each prompt. |

This is why staged work is safer than a single prompt. A long prompt may be
fast for a small disposable task, but its intermediate reasoning and decisions
are easy to lose. Hive makes the important handoffs explicit without claiming
that people never need to intervene.

## Three ways to get a workflow

Hive resolves workflows from three product surfaces:

- **Built-in workflows** ship with Hive. `coding` is the flagship engineering
  workflow; `content` handles research, outlining, drafting, and critique; and
  `bench` runs the benchmark contribution process.
- **Project-local workflows** are owner-authored YAML and instruction files in
  `.hive-state/workflows/`. They are the right choice for a process that belongs
  to one project or is still evolving. The editorial example in
  [Custom workflows]({{ '/docs/custom-workflows/' | relative_url }}) uses this
  route.
- **Honeycombs** are reviewed, versioned packages installed from the maintained
  registry. Browse the [Honeycomb catalog]({{ '/honeycombs/' | relative_url }})
  when a shared process already exists and you want its permission and review
  evidence before installation.

All three use the same task folders, stages, artifacts, markers, daemon, and
operator controls. Their difference is who owns and distributes the definition.

## Non-coding workflows are first-class

The general model is not tied to source code or nine stages.

- The built-in **content** workflow moves an idea through research, outline,
  draft, critique, and a finished article.
- A project-local **editorial** workflow can move a brief through research,
  drafting, an explicit human decision, and a publish-ready local artifact.
- A **research or triage** workflow can gather evidence, compare options, pause
  for a decision, and end with a recorded recommendation.

Each process should use the fewest stages that create useful boundaries. A
four-stage editorial workflow does not become safer by copying a nine-stage
engineering shape.

## The flagship coding workflow

Coding remains Hive's deepest built-in proof of the model:

```text
inbox → brainstorm → plan → execute → open-pr → review → artifacts → finalize → done
```

The original idea becomes requirements, an implementation plan, a committed
feature branch, a draft pull request, review evidence, and finally a merge-ready
pull request with its trail attached. The mechanics are the same as every other
workflow; the engineering process simply needs more stages and specialized
runners.

## People remain part of the protocol

Human intervention is ordinary, not a failure mode. A person can edit a
decision file, answer a waiting question, reject an artifact with revision
feedback, move a task back, or rerun a corrected stage. The daemon continues
only after the durable status reflects that decision.

That separation keeps autonomy bounded: agents do the work they were assigned,
while checkpoints reserve product, editorial, security, or release judgment for
the people responsible for it.

---

Next: [author a project-local workflow]({{ '/docs/custom-workflows/' | relative_url }})
or see [Configuration]({{ '/docs/configuration/' | relative_url }}) for agent,
model, budget, permission, and daemon settings.
