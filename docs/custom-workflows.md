---
title: Custom workflows
layout: doc
nav_order: 6
permalink: /docs/custom-workflows/
description: Define project workflows in YAML with stage instructions, saved artifacts, agent permissions, and human approval.
---

# Creating custom workflows
{: .no_toc }

Hive includes `coding`, `content`, and `bench` workflows. To run a different
process, define its stages in a YAML descriptor and give each agent stage
instructions. Examples include writing, research, triage, and weekly reports.

This guide builds a project-local workflow and explains its inputs, outputs,
and approval behavior. For repository imports, see
[Installing private workflows](/docs/private-workflows/); direct Git import
is unreleased. New to Hive? Start with [Concepts](/docs/concepts/) and
[Getting started](/docs/getting-started/).

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

A task's stage is visible in its folder location. Stage documents and task
history stay under `.hive-state/`; a machine-local SQLite runtime control plane
also coordinates attempts, delivery, and leases. See
[durability and recovery](/docs/concepts/#durability-and-recovery).

An **agent stage** reads earlier task files and writes its output according
to a Markdown instruction file. The **daemon** runs ready stages and advances
tasks in enrolled projects; it pauses for human input or recovery. Configure
project enrollment with [`hive init`](/docs/commands/init/).

Use [`hive run`](/docs/commands/run/) to run the current stage and
[`hive approve`](/docs/commands/approve/) for eligible stage transitions. Use
`hive decide` for an explicit human decision, as shown below. Prefer these
supported commands to moving folders: they apply locking and state checks.

The **workflow descriptor** names the stages, their inputs and outputs, and
the instruction files that each agent receives.

---

## Human approval

Use `kind: human` when a person must approve an artifact or return it for
revision. This custom Research example also appears on the homepage:

```yaml
id: research-report
stages:
  - name: research
    kind: agent
    state_file: research.md
    instruction: ./research-report/research.md
  - name: synthesis
    kind: agent
    state_file: report.md
    instruction: ./research-report/synthesis.md
  - name: approval
    kind: human
    state_file: approval.md
    input: report.md
    outcomes:
      approve: { complete: true, artifact: report.md }
      reject: { to: synthesis }
```

Provide the two instruction files, then validate your descriptor with
`hive workflow validate research-report --json`. When the task reaches the
human stage, the waiting response supplies a visit-specific decision ID:

```bash
hive decide <task> approve --from approval --decision-id <decision-id>
hive decide <task> reject --from approval --decision-id <decision-id> --note "clarify source limitations"
```

Approval requires a non-empty, regular task-local `report.md` and completes
that result. Rejection records the decision and returns the same task to
synthesis. Neither outcome publishes, deploys, sends, or otherwise acts outside
Hive. External effects require a separately configured and authorized step.

For the complete current descriptor contract, see the
[v0.8.0 workflow reference](https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/workflows.md).

## Anatomy of a descriptor

This `writing` example has an inbox, three agent stages, and a final archive
stage. Save the descriptor as `writing.yml` and provide the instruction files
shown later in this guide:

```yaml
id: "writing"                 # must match the filename (writing.yml) and the
                              # SAFE_SLUG rule: lowercase, starts with a letter,
                              # [a-z0-9-]. Cannot be a built-in (coding/content/bench).
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

  - name: done                # this simple example ends in an inert exit gate
    kind: terminal
    state_file: done.md
```

Each agent stage names the file it produces and the instruction it receives.
The task advances through the declared stages as their completion checks pass.

### Field reference

Core descriptor and stage fields:

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Workflow id. Matches the filename stem and `SAFE_SLUG`; not a built-in. |
| `stages` | yes | Ordered list. Indices are implicit: stage *N* lives in folder `N-<name>`. |
| `name` | yes | Stage name (`SAFE_SLUG`). The folder is `<index>-<name>`. |
| `kind` | yes | `agent`, `human` (explicit decision), `council`, or an inert/terminal gate. See the release reference for the full contract. |
| `state_file` | yes | A **bare filename** (no `/`) the stage reads/writes inside the task folder. |
| `instruction` | agent stages | Markdown file the agent is given. Relative to the descriptor. Exactly one of `instruction` or `skill`. |
| `skill` | agent stages | A skill name to invoke instead of an inline instruction. |
| `advance_verb` | optional | The verb that *arrives at* this stage (defaults to the stage name). The first stage must not declare one. |
| `permissions` | optional, agent only | Per-stage tool/permission scope (`read-only`, `scoped`, `yolo`). |

Validation checks the descriptor before execution, including these rules:

- Stage indices are `1..N` in order; names and folders are unique.
- The final stage must have a valid completion contract: for example a terminal gate, an agent deliverable, or a completing human outcome.
- `state_file` is a bare basename (no `/`, not `.`/`..`).
- Agent stages declare **exactly one** of `skill` or `instruction`.
- `instruction` must point at a readable file.

Validation makes the stage contract explicit before a run. Keep state files
inside the task folder, provide readable instructions, and declare a supported
completion path.

---

## Creating a workflow

Hive can scaffold a workflow in an existing project or initialize a project
with a new workflow.

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

Edit the instruction file shown on the `edit:` line before creating a task.
The blank starter contains a placeholder, not a runnable brief.

#### Seed from a sample instead of the blank stub

Use `--template research` for a multi-stage starting point:

```bash
hive workflow new field-notes --template research
```

The command copies a descriptor and stage instructions using your chosen ID.
Review and adapt the instructions before running a task. An unknown template
name lists the available choices:

```
$ hive workflow new x --template bogus
hive workflow: unknown workflow template "bogus" (available: blank, research)
```

| Template | Stages |
|---|---|
| `blank` (default) | `inbox → work → done` (one placeholder instruction) |
| `research` | `inbox → gather → synthesize → report → done` |

In v0.8.0, Writing and Architecture are reviewed Honeycomb packages, no longer
scaffold templates. [Browse the catalog](/honeycombs/) to inspect their
permissions and installation instructions. The `writing` descriptor in this
guide is a separate example you author yourself.

### B. In a fresh project — `hive init --new-workflow`

Initialize a project and set its default workflow in one command:

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

Each instruction file tells an agent what to read and what to produce. Name
the prior stages' outputs and the current stage's `state_file` explicitly.
Earlier Markdown artifacts in the task folder are passed to the agent
automatically, but the instructions should identify which files matter.

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
`draft.md` and revises the final text.

---

## Running a task through your workflow

The setup is done. Running a task is one command.

```bash
hive new my-project --workflow writing "an essay on durable automation"
```

> **Tip:** put options *before* the project too if you like — `hive new
> --workflow writing my-project "…"`. Either ordering is accepted. (If the
> project's `default_workflow` is `writing`, drop the flag entirely.)

Hive saves the request in `idea.md` under `1-inbox/`. With the project enrolled
and the daemon running, ready stages advance through research, draft, and edit.
Inspect progress and respond when a stage needs input or recovery:

```bash
hive status
```

The CLI also prints a manual `next:` hint for projects without daemon dispatch.
Use [`hive run`](/docs/commands/run/) for the current stage and
[`hive approve`](/docs/commands/approve/) for eligible transitions. Human
decision stages use `hive decide`; moving a folder is not a substitute for
recording that decision.

---

## A complete worked example, start to finish

Create the project, replace the blank starter with the annotated descriptor
above, and save the three instruction files before running a task:

```bash
# 1. Initialize a project with a blank owner-authored workflow.
hive init --new-workflow writing ~/Dev/essays
cd ~/Dev/essays

# 2. Save the descriptor and research/draft/edit instructions from this guide.
$EDITOR .hive-state/workflows/writing.yml
$EDITOR .hive-state/workflows/writing/{research,draft,edit}.md
hive workflow validate writing --json
hive workflow commit writing

# 3. Create a task using the project's default workflow.
hive new essays "what folder-as-agent pipelines teach us about durable automation"

# 4. Inspect progress; the enrolled daemon advances ready stages.
hive status
```

When the task reaches `5-done`, inspect the finished piece in `edit.md` and its
supporting files. If you did not enable daemon dispatch, use the manual
commands described above.

---

## Advanced options

Use these fields to control stage behavior and permissions.

- **`kind: terminal` vs `agent`** — terminal stages are gates with no agent: the
  entry inbox, exit archive, or an inert pause. Agent stages run the AI. For
  an explicit, recorded approval or revision decision, use
  [`kind: human`](#human-approval).
- **`skill` instead of `instruction`** — point a stage at a named skill rather
  than an inline markdown brief: `skill: ce-brainstorm`. Use this to reuse
  packaged behavior instead of re-describing it.
- **Per-stage permissions** — declare the tool access an agent stage needs.
  Enforcement depends on the selected agent profile:

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

## Before running a workflow
{: #gotchas-learned-the-hard-way }

- **Edit the scaffolded instruction before running.** A blank `hive workflow new`
  leaves a placeholder. The `edit:` line tells you what to open. Templates
  include instructions, but still need review for your task.
- **Declare a completion path.** A terminal gate, an agent deliverable, or a
  completing human outcome can finish a workflow.
- **`state_file` is a bare filename.** Keep it flat: `idea.md`, `work.md`.
- **`id` can't shadow a built-in** (`coding`, `content`, `bench`), and it must match the
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
- [Command reference](/docs/commands/) — workflow commands, including
  [`init`](/docs/commands/init/), [`new`](/docs/commands/new/),
  [`run`](/docs/commands/run/), [`approve`](/docs/commands/approve/), and
  [`status`](/docs/commands/status/).
- The built-in `coding`, `content`, and `bench` workflows — full-featured descriptors to
  learn from when your own pipeline outgrows the basics.

## Share a workflow privately

Follow [Build and share a private workflow](/docs/build-private-workflow/) for a
complete repository example, portability requirements and clean-project checks.
