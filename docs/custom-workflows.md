---
title: Custom workflows
layout: doc
nav_order: 6
permalink: /docs/custom-workflows/
description: Hive's engine is generic — author your own per-project pipeline (writing, research, triage, anything) in a few lines of YAML, and let the daemon run it.
---

# Creating custom workflows
{: .no_toc }

Hive ships with two workflows out of the box: `coding`, the nine-stage
inbox → … → done pipeline that opens PRs, and `content`, a research pipeline.
Most people stop there, assuming those two are the product.

They aren't. They're just the two pipelines someone already wrote down.

The engine underneath is generic. A workflow is nothing more than an **ordered
list of stages described in a YAML file** — and you can author your own, per
project, in a few minutes. Writing. Research. Triage. Translation. A
weekly-report generator. Any task that moves through a sequence of steps, where
an AI agent does the work at each step, is a workflow Hive can run. You describe
the steps; the daemon runs the pipeline.

This guide takes you from the mental model to a custom workflow you can run
today. Every code block, command, and output here is copy-pasteable and real.
If you're new to Hive's core ideas, read [Concepts](/docs/concepts/) and
[Getting started](/docs/getting-started/) first.

1. TOC
{:toc}

---

## The mental model

Hive is a **[folder-as-agent](/docs/concepts/) pipeline**. Every task is a
directory, and at any moment it lives under exactly one stage folder:

```
<project>/.hive-state/stages/
  1-inbox/       <- a task starts here
  2-research/
  3-draft/
  4-edit/
  5-done/        <- and finishes here
```

That's the whole data model. A task's stage is *which folder it's in*. Advancing
a task is the folder moving from `N-stage` to `N+1-stage`. There is no hidden
database tracking state — the filesystem *is* the state.

Two things make it move:

- **An agent stage runs an AI agent** with an *instruction* — a markdown file
  telling it what to do. The agent reads the task's prior files and writes the
  stage's output file. That output becomes context for the next stage.
- **The hive daemon advances tasks for you.** Enabled by default at
  [`hive init`](/docs/commands/init/), it watches your projects, runs each ready
  stage's agent, and moves the task to the next stage automatically. You
  *author the workflow, create a task, and watch* — the daemon does the driving.

That second point is the one to internalize. In normal use you never touch the
folders yourself. The daemon does.

Because the model is just folders, though, you *can* reach in by hand when you
need to — [`hive run`](/docs/commands/run/) to run the current stage,
[`hive approve`](/docs/commands/approve/) to advance it, or literally `mv` the
folder to move it. That always works, and it's invaluable for intervention:
stepping a stuck task, re-running one that went sideways, nudging something past
a gate. But it's the escape hatch, not the workflow. Day to day, you create the
task and let the daemon take it from there.

A **workflow descriptor** is the YAML that names the stages and says which are
agent stages, what each one reads and writes, and what instruction drives it.
That file is the thing you author. Everything else follows from it.

---

## Anatomy of a descriptor

A descriptor is short enough to read top to bottom and understand completely.
Here's a real one — a `writing` pipeline that takes an idea and returns a
finished piece — fully annotated:

```yaml
id: "writing"                 # must match the filename (writing.yml) and the
                              # SAFE_SLUG rule: lowercase, starts with a letter,
                              # [a-z0-9-]. Cannot be a built-in (coding/content).
stages:
  - name: inbox               # stage 1. Its folder is "1-inbox".
    kind: terminal            # terminal = no agent; a gate the task rests at.
    state_file: idea.md       # the file `hive new` writes your idea into.

  - name: research            # stage 2 -> folder "2-research".
    kind: agent               # agent = Hive runs an AI agent here.
    state_file: research.md   # the file this stage PRODUCES.
    instruction: ./writing/research.md   # the markdown telling the agent what
                              # to do. Path is relative to the descriptor.

  - name: draft
    kind: agent
    state_file: draft.md
    instruction: ./writing/draft.md

  - name: edit
    kind: agent
    state_file: edit.md
    instruction: ./writing/edit.md

  - name: done                # the LAST stage MUST be terminal — a task at the
    kind: terminal            # final stage has nowhere to advance, so a
    state_file: done.md       # non-terminal last stage would be undroppable.
```

Read it once and the shape is clear: an entry gate, three agents that each do
one job, an exit gate. The task flows top to bottom. Each agent stage names the
file it produces and the instruction that drives it.

### Field reference

Every field a stage can carry, and what it means:

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Workflow id. Matches the filename stem and `SAFE_SLUG`; not a built-in. |
| `stages` | yes | Ordered list. Indices are implicit: stage *N* lives in folder `N-<name>`. |
| `name` | yes | Stage name (`SAFE_SLUG`). The folder is `<index>-<name>`. |
| `kind` | yes | `agent` (runs an agent) or `terminal` (a gate, no agent). |
| `state_file` | yes | A **bare filename** (no `/`) the stage reads/writes inside the task folder. |
| `instruction` | agent stages | Markdown file the agent is given. Relative to the descriptor. Exactly one of `instruction` or `skill`. |
| `skill` | agent stages | A skill name to invoke instead of an inline instruction. |
| `advance_verb` | optional | The verb that *arrives at* this stage (defaults to the stage name). The first stage must not declare one. |
| `permissions` | optional, agent only | Per-stage tool/permission scope (`read-only`, `scoped`, `yolo`). |

The parser is strict on purpose, so a typo fails at author time instead of
halfway through a run. The rules it enforces:

- Stage indices are `1..N` in order; names and folders are unique.
- The **last stage must be `kind: terminal`**.
- `state_file` is a bare basename (no `/`, not `.`/`..`).
- Agent stages declare **exactly one** of `skill` or `instruction`.
- `instruction` must point at a readable file.

None of these are arbitrary. A non-terminal last stage would leave a finished
task with nowhere to go; a `state_file` with a slash in it would write outside
the task folder at runtime. The parser catches both before you ever start a run.

---

## Creating a workflow

You don't write the YAML from a blank page. Hive scaffolds it for you, and which
command you reach for depends on one thing: whether the project already exists.

### A. In an existing project — `hive workflow new`

You're already in a project and want to add a workflow to it:

```bash
cd my-project
hive workflow new writing
```

This scaffolds a **blank** `inbox → work → done` starter:

```
.hive-state/workflows/writing.yml          # the descriptor
.hive-state/workflows/writing/work.md       # the work-stage instruction (a stub)
```

and prints:

```
hive: created workflow writing at .../workflows/writing.yml
edit: .../workflows/writing/work.md (the `work` stage instruction — a placeholder until you define it)
next: hive new my-project --workflow writing "<your idea>"
```

Now **edit the instruction(s)** that the `edit:` line points at. The blank stub
literally says *"Edit this file to define what the `work` stage should do."* —
so if you skip this step, the agent reads that sentence and does nothing useful.
Define the work, then create a task.

#### Seed from a sample instead of the blank stub

A one-stage blank is a fine starting point when you know exactly what you're
building. More often you want a real, multi-stage pipeline to shape, not a bare
stub. Pass `--template`:

```bash
hive workflow new evidence --template research
```

This renders a curated sample descriptor with **your** id and copies its real
stage instructions in — actual briefs, not placeholders. Pass an unknown
template name and Hive lists what's available:

```
$ hive workflow new x --template bogus
hive workflow: unknown workflow template "bogus" (available: blank, research)
```

The two that ship in Hive 0.6.5:

| Template | Stages |
|---|---|
| `blank` (default) | `inbox → work → done` (one placeholder instruction) |
| `research` | `inbox → gather → synthesize → report → done` |

A multi-stage template prints `edit: <id>/ (N stage instructions to fill in)` —
edit those to your taste, then create a task.

### B. In a fresh project — `hive init --new-workflow`

Starting from nothing? Bootstrap the project *and* bind it to a custom workflow
in a single command — no `init` → create → re-init dance:

```bash
hive init --new-workflow writing ~/Dev/my-writing
```

This runs [`init`](/docs/commands/init/), scaffolds the `writing` descriptor and
its instructions, and sets it as the project's `default_workflow`. Edit the
scaffolded instructions, and because the default is already bound, a plain
[`hive new`](/docs/commands/new/) routes through it — no `--workflow` flag
needed:

```bash
hive new my-writing "an essay on folder-as-agent pipelines"
```

---

## Writing stage instructions

The descriptor is the skeleton. The instruction files are where the work
actually lives — each one is a single agent's brief, and the quality of your
pipeline is the quality of these files.

There's one convention that consistently works: **tell the agent what to read
(the prior stages' outputs) and what to produce (this stage's `state_file`).**
You don't have to wire context by hand — earlier `.md` artifacts in the task
folder are passed to the agent automatically. Your job is to point at the right
ones and be specific about the output.

Here are the three instructions for the `writing` pipeline.

`writing/research.md`:

```markdown
You are the **research** stage of a writing pipeline.

Read `idea.md` (the topic). Produce `research.md` with:
- Framing — audience, angle, the single takeaway.
- 5–8 key points worth including, each with why it matters.
- An outline (section headings, in order).
- Open questions for the draft stage.

Be specific. Do not write the piece — that is the draft stage's job.
```

`writing/draft.md`:

```markdown
You are the **draft** stage.

Using `idea.md` and `research.md`, write a complete first draft in `draft.md`.
Follow the outline, keep the takeaway front and centre, plain direct voice.
A strong complete draft is the goal — the edit stage will polish.
```

`writing/edit.md`:

```markdown
You are the **edit** stage.

Revise `draft.md` into a final version in `edit.md`. Tighten every sentence,
fix flow and tone, verify the takeaway lands. Output the full final text.
```

Notice how each stage builds on the last. `research` produces the outline;
`draft` reads `research.md` and follows it; `edit` sees both `idea.md` and
`draft.md` and polishes. The pipeline is a relay, and each instruction tells its
runner what baton it's receiving and what it's handing off.

---

## Running a task through your workflow

The setup is done. Running a task is one command.

```bash
hive new my-project --workflow writing "an essay on durable automation"
```

> **Tip:** put options *before* the project too if you like — `hive new
> --workflow writing my-project "…"`. Either ordering is accepted. (If the
> project's `default_workflow` is `writing`, drop the flag entirely.)

That's the whole interaction. Hive captures your idea into `idea.md` under
`1-inbox/`, and — with the daemon running — takes it from there. It runs
`research`, then `draft`, then `edit`, moving the task forward one stage at a
time until it lands in `done`. You don't touch a thing. You just watch:

```bash
hive status            # where every task is, across all your projects
```

You'll also see Hive print a manual `next:` line — something like
`mv … && hive run <id>`. That's the fallback for when the daemon is off, or for
when you want to step a task yourself: [`hive run <id>`](/docs/commands/run/)
runs its current stage now, [`hive approve <id>`](/docs/commands/approve/)
advances it, and `mv` moves the folder directly. Reach for these to intervene —
to unstick something, re-run a stage, push past a gate. They are not the normal
path. The normal path is: create the task, watch
[`hive status`](/docs/commands/status/), let the daemon drive.

---

## A complete worked example, start to finish

Here's everything above in one sequence — a fresh project to a finished essay,
with the daemon doing the work in between:

```bash
# 1. A fresh project bound to a blank "writing" workflow.
hive init --new-workflow writing ~/Dev/essays
cd ~/Dev/essays

# 2. Replace the generated descriptor and placeholder instruction with the
#    workflow and instructions from this guide.
$EDITOR .hive-state/workflows/writing.yml
$EDITOR .hive-state/workflows/writing/work.md

# 3. Create a task — no --workflow needed, the default is already "writing".
hive new essays "what folder-as-agent pipelines teach us about durable automation"

# 4. The daemon takes it from here: inbox -> research -> draft -> edit -> done.
hive status            # watch it move through the stages, across all projects
# (only if you want to step it yourself: `hive run <id>`, or `mv` the folder)
```

When the task reaches `5-done`, `edit.md` holds your finished piece. The daemon
got it there. You authored the workflow once and dropped in an idea — that was
the entire job.

---

## Advanced options

Once the basics click, a handful of fields let you shape pipelines that go
beyond the linear-agent default.

- **`kind: terminal` vs `agent`** — terminal stages are gates with no agent: the
  entry inbox, the exit done, or any human-review pause you want to insert
  mid-pipeline. Agent stages run the AI. Put a terminal stage between two agents
  and the task rests there until you advance it — a built-in approval gate.
- **`skill` instead of `instruction`** — point a stage at a named skill rather
  than an inline markdown brief: `skill: ce-brainstorm`. Use this to reuse
  packaged behavior instead of re-describing it.
- **Per-stage permissions** — scope an agent stage's tools so a stage can only do
  what it needs to:
  ```yaml
  - name: research
    kind: agent
    state_file: research.md
    instruction: ./writing/research.md
    permissions: read-only        # or: { preset: scoped, tools: [Read, Grep] }
  ```
  Three presets: `read-only`, `scoped` (an allow-list of tools, dirs, and bash),
  and `yolo` (no scoping). A present-but-blank `permissions:` is rejected
  (fail-closed) — so you can never silently grant full access by leaving the key
  empty.
- **`default_workflow`** — bind a workflow as the project default in
  `.hive-state/config.yml`, and `hive new` uses it without `--workflow`.
- **`advance_verb`** — customize the verb that *arrives at* a stage. It defaults
  to the stage name, and the first stage must not declare one.

---

## Gotchas (learned the hard way)

A few sharp edges. Each one is here because it bit someone first.

- **Edit the scaffolded instruction before running.** A blank `hive workflow new`
  leaves a placeholder, and running it as-is hands the agent the literal text
  *"Edit this file…"* — which it will dutifully not act on. The `edit:` line in
  the command output tells you exactly what to open. (Seeding with `--template`
  sidesteps this entirely: you get real instructions.)
- **The last stage must be `terminal`.** Otherwise a finished task can neither
  advance nor drop — it's stranded at a stage with nowhere to go.
- **`state_file` is a bare filename.** Something like `sub/idea.md` passes
  validation but fails at runtime. Keep it flat: `idea.md`, `work.md`.
- **`id` can't shadow a built-in** (`coding`, `content`), and it must match the
  descriptor filename.
- **Custom workflows are per project.** Hive discovers them from
  `<hive_state_path>/workflows/*.yml`, and once discovered they're available to
  `hive new --workflow`, `status`, `run`, `approve`, and the daemon — the same
  surfaces the built-ins use.

---

## See also

- [Concepts](/docs/concepts/) — folder-as-agent, the stage state machine, and
  the marker protocol the pipeline runs on.
- [Getting started](/docs/getting-started/) — install Hive and run your first
  task end to end.
- [Command reference](/docs/commands/) — every `hive` verb, including
  [`init`](/docs/commands/init/), [`new`](/docs/commands/new/),
  [`run`](/docs/commands/run/), [`approve`](/docs/commands/approve/), and
  [`status`](/docs/commands/status/).
- The built-in `coding` and `content` workflows — full-featured descriptors to
  learn from when your own pipeline outgrows the basics.
