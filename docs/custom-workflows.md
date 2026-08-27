---
title: Custom workflows
layout: doc
nav_order: 6
permalink: /docs/custom-workflows/
description: Author a project-local Hive workflow in YAML, then run a safe editorial example through research, revision, human approval, and a publish-ready artifact.
---

# Creating custom workflows
{: .no_toc }

This guide turns a plain-language editorial process into one project-local Hive
workflow:

```text
brief → research → draft → approval → done
```

The first three active stages produce files. Approval pauses for an explicit
human decision. A rejection returns to drafting; an approval produces a local
`publish-ready.md`. The `done` stage performs no external write: a person still
decides whether and where to publish.

Read [How workflows work]({{ '/docs/concepts/' | relative_url }}) first if
workflow definitions, task runs, stages, artifacts, or markers are new terms.
Commands and descriptor fields below were verified with Hive 0.6.5, the current
stable release when this page was updated.

Hive 0.6.5 also needs the `base64` gem when it runs under Ruby 3.4, where
`base64` is no longer a default gem. Check the Ruby environment that launches
Hive before the first `hive run`; if the check fails, install the dependency
into Hive's isolated gem home for the channel you installed:

```bash
# install.sh (including a custom HIVE_PREFIX)
hive_gem_home="${HIVE_PREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}}/hive/gems"
GEM_HOME="$hive_gem_home" GEM_PATH="$hive_gem_home" ruby -rbase64 -e 'puts "base64 available"'
gem install base64 --install-dir "$hive_gem_home" --no-document

# Homebrew
hive_gem_home="$(brew --prefix hive)/libexec"
GEM_HOME="$hive_gem_home" GEM_PATH="$hive_gem_home" ruby -rbase64 -e 'puts "base64 available"'
gem install base64 --install-dir "$hive_gem_home" --no-document

# AUR
hive_gem_home=/usr/share/hive/gems
GEM_HOME="$hive_gem_home" GEM_PATH="$hive_gem_home" ruby -rbase64 -e 'puts "base64 available"'
sudo gem install base64 --install-dir "$hive_gem_home" --no-document
```

Run only the check and repair for your install channel, then repeat its
environment-scoped `ruby -rbase64` check before retrying Hive. A bare check or
`gem install` uses your default Ruby environment, which is not the isolated
environment these Hive launchers use.

1. TOC
{:toc}

## Design the process before the YAML

Write down the handoff at each boundary before choosing fields:

| Stage | Reads | User-facing artifact | Stage status file | Exit condition |
|---|---|---|---|---|
| `brief` | The operator's input | `brief.md` | `brief.md` | The task exists. |
| `research` | `brief.md` | `research.md` | `research-status.md` | Findings and sources are usable. |
| `draft` | Brief, research, and any revision feedback | `draft.md` | `draft-status.md` | A complete draft exists. |
| `approval` | Draft and decision | `decision.md`, then `publish-ready.md` | `approval-status.md` | A human approves, or revision is requested. |
| `done` | The completed task folder | No new artifact | `done.md` | Approved work is ready for a human to publish. |

Status and deliverables are deliberately separate. Hive excludes the current
stage's own `state_file` from the prior-artifact context supplied to that agent.
A sibling `draft.md` therefore remains readable when drafting is rerun, while
`draft-status.md` can be reset from `COMPLETE` to `WAITING` without overwriting
the actual draft.

## Create the files

Choose one scaffold path, then use the same descriptor and instructions in the
next section.

### Existing project

From a project already attached with `hive init`:

```bash
cd my-project
hive workflow new editorial
```

The command creates a blank `inbox → work → done` descriptor whose entry-stage
state file is `idea.md`, plus a placeholder `editorial/work.md` instruction.
Replace the descriptor, remove that placeholder instruction, and add the three
instructions from this page:

```bash
rm .hive-state/workflows/editorial/work.md
```

### New project

Create a normal Git repository first, then initialize Hive and bind the new
workflow as the default:

```bash
mkdir -p ~/Dev/editorial-site
cd ~/Dev/editorial-site
git init
touch README.md
git add README.md
git commit -m "Initial commit"
hive init --new-workflow editorial ~/Dev/editorial-site
```

`--new-workflow` creates the same blank scaffold and records `editorial` as
`default_workflow`. Remove its placeholder `work.md` exactly as in the existing
project path.

After adding the files below, both paths converge on:

```text
.hive-state/workflows/
├── editorial.yml
└── editorial/
    ├── README.md
    ├── honeycomb.yml
    ├── research.md
    ├── draft.md
    └── approval.md
```

The generated `README.md` and `honeycomb.yml` are package metadata; they do not
change the project-local run. Keep them if the workflow may later be reviewed
and versioned as a Honeycomb.

### Optional stable templates

Hive 0.6.5 ships only `blank` and `research` workflow templates. Editorial is
not a shipped template, so the example above starts blank. For a separate
research workflow you can seed the stable sample:

```bash
hive workflow new evidence --template research
```

An unknown template reports the exact supported list:

```text
hive workflow: unknown workflow template "bogus" (available: blank, research)
```

## Add the editorial descriptor

Replace `.hive-state/workflows/editorial.yml` with this complete descriptor.

### `editorial.yml`

```yaml
id: editorial
stages:
  - name: brief
    kind: terminal
    state_file: brief.md

  - name: research
    kind: agent
    state_file: research-status.md
    instruction: ./editorial/research.md
    agent: claude
    permissions:
      preset: scoped
      tools:
        - Read
        - WebSearch
        - WebFetch
        - "Edit(./**)"

  - name: draft
    kind: agent
    state_file: draft-status.md
    instruction: ./editorial/draft.md
    agent: claude
    permissions:
      preset: scoped
      tools:
        - Read
        - "Edit(./**)"

  - name: approval
    kind: agent
    state_file: approval-status.md
    instruction: ./editorial/approval.md
    agent: claude
    permissions:
      preset: scoped
      tools:
        - Read
        - "Edit(./**)"

  - name: done
    kind: terminal
    state_file: done.md
```

The descriptor uses five supported ideas:

- `id` matches the filename stem, `editorial`.
- Stage order defines folders such as `2-research` and `4-approval`.
- Every `state_file` is a bare filename inside the task folder.
- Each active stage names exactly one `instruction`; a reusable `skill` could
  be used instead, but not alongside it.
- `agent: claude` is intentional. In Hive 0.6.5, non-`yolo` tool scoping is
  enforceable by the Claude runner. `Edit(./**)` is resolved to the current task
  folder. Research alone receives `WebSearch` and `WebFetch` so its source links
  can be checked against live pages; draft and approval remain limited to
  reading and editing task artifacts. No stage receives shell access.

You may add a stable agent's `model` and `effort` fields per stage when the
project needs them. Choose by job: research may justify a stronger model, while
a deterministic formatting stage may not. Do not copy one expensive,
high-permission profile into every stage by habit.

## Add the stage instructions

These blocks are the source of truth used to verify the example. Copy them
verbatim into the named paths.

### `editorial/research.md`

```markdown
You are the research stage of an editorial workflow.

Read `brief.md`. Write `research.md` with:

- the audience and intended outcome;
- factual claims that need support;
- source links and a one-line note on what each source supports;
- risks, unknowns, and assumptions the draft must not hide;
- a recommended structure for the draft.

Use `WebSearch` to find relevant sources and `WebFetch` to open each source you
cite. Do not mark research complete when a factual claim or link has not been
checked against the fetched source; record it under unknowns instead.

Do not write the article and do not publish anything.

When `research.md` is complete and non-empty, replace `research-status.md`
with a short summary followed by exactly:

<!-- COMPLETE -->

If the brief lacks information required for honest research, explain the
specific question in `research-status.md` and end it with `<!-- WAITING -->`
instead.
```

### `editorial/draft.md`

```markdown
You are the draft stage of an editorial workflow.

Read `brief.md` and `research.md`. If `decision.md` says
`decision: rejected`, also read its non-empty `feedback` and revise the existing
`draft.md` rather than starting from memory.

Write a complete `draft.md` that:

- serves the audience and outcome in the brief;
- distinguishes sourced facts from assumptions;
- follows the useful structure from the research;
- is ready for a human editorial decision.

On a revision, preserve the rejection feedback in `decision.md`, change its
`decision` to `pending`, and add a short `revision_note` describing what changed.
Leave `selected_artifact: draft.md`; clear any old `approved_at` and `sha256`
values. Do not create `publish-ready.md`.

When the draft is complete and non-empty, replace `draft-status.md` with a short
summary followed by exactly:

<!-- COMPLETE -->

If drafting cannot finish, explain the blocker in `draft-status.md` and end it
with `<!-- WAITING -->` instead.
```

### `editorial/approval.md`

```markdown
You are the approval stage of an editorial workflow. You record a human's
decision; you never make the approval decision yourself.

Read `draft.md` and `decision.md` when it exists.

If `decision.md` is missing, create it with this form:

decision: pending
selected_artifact: draft.md
feedback:
approved_at:
sha256:

Then write `approval-status.md` with a request for human review and end it with
`<!-- WAITING -->`.

If `decision.md` says `decision: pending`, preserve the form, explain that a
human must choose `approved` or `rejected`, and leave `approval-status.md`
ending in `<!-- WAITING -->`.

If `decision.md` says `decision: rejected`, require non-empty `feedback`.
Preserve `draft.md` as revision input. Do not create `publish-ready.md`. Replace
`draft-status.md` with the revision feedback and end it with `<!-- WAITING -->`.
Leave `approval-status.md` ending in `<!-- WAITING -->` so an operator can move
the task back to draft explicitly.

If `decision.md` says `decision: approved`, require all of these operator-set
fields: `selected_artifact: draft.md`, a UTC `approved_at`, and a 64-character
lowercase `sha256`. Do not invent missing values. Write `publish-ready.md`
containing:

- `selected_artifact: draft.md`;
- `decision: approved`;
- the exact `approved_at` value;
- the exact `sha256` value;
- a separator and the complete contents of the selected `draft.md`.

Then replace `approval-status.md` with a short completion summary followed by
exactly `<!-- COMPLETE -->`.

No branch may publish to a CMS, website, social network, email service, GitHub,
or any other external system. The only approved output is the local
`publish-ready.md` artifact.
```

## Inspect before the first run

From the project root, ask the stable CLI to load all three workflow tiers:

```bash
hive workflow list --json
```

Confirm that `editorial` appears as an authored workflow. This load catches
invalid YAML, an id/filename mismatch, unreadable instruction paths, unknown
fields, invalid state-file paths, a missing instruction or skill, and malformed
permissions. Hive 0.6.5 has no separate `workflow validate` command.

Also inspect the files yourself:

```bash
find .hive-state/workflows/editorial* -maxdepth 2 -type f -print
```

## Run the happy path

Create a task. If `editorial` is the project's default, the `--workflow` option
may be omitted.

```bash
hive new my-project --workflow editorial "Explain interruption-safe agent workflows to engineering leads"
```

The command prints the task slug. With the daemon enabled, watch it run until
approval waits for a person:

```bash
hive status
```

For a deliberate first run with the daemon stopped, step every transition:

```bash
hive approve <slug>
hive run <slug>
hive approve <slug>
hive run <slug>
hive approve <slug>
hive run <slug>
```

The first approval run creates `decision.md` and ends
`approval-status.md` with `WAITING`. Review `draft.md`; Hive has not advanced.

For approval, enter the task folder and generate the two values rather than
asking the agent to invent them:

```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
sha256sum draft.md
```

On macOS, use `shasum -a 256 draft.md`. Put those exact values into
`decision.md`:

```text
decision: approved
selected_artifact: draft.md
feedback:
approved_at: 2026-07-21T12:34:56Z
sha256: <64-character output from sha256sum>
```

Rerun approval and advance only after its marker is complete:

```bash
hive run <slug>
hive approve <slug>
```

At `5-done`, inspect the local outcome and compare the hash again:

```bash
sha256sum draft.md
rg '^(selected_artifact|decision|approved_at|sha256):' publish-ready.md
tail -n 1 approval-status.md
```

The hash in `publish-ready.md` must match the bytes of the final `draft.md`.
`done` means “ready for a human to publish,” not “published.”

## Exercise rejection and revision

The first run should test this branch too. At the approval wait, edit
`decision.md`:

```text
decision: rejected
selected_artifact: draft.md
feedback: Explain the recovery boundary before introducing the daemon.
approved_at:
sha256:
```

Rerun approval. The approval instruction preserves `draft.md`, records the
feedback in `draft-status.md`, resets that stale completion marker to `WAITING`,
and leaves approval waiting. No `publish-ready.md` exists.

Use the released backward-transition command, then rerun drafting:

```bash
hive approve <slug> --to draft
hive run <slug>
hive approve <slug>
hive run <slug>
```

Drafting reads both the previous `draft.md` and the durable rejection feedback,
writes a revised draft, resets `decision` to `pending`, and completes its status
file. The task returns to approval and waits for a new human decision. Review
the revision, record the UTC timestamp and SHA-256 as in the happy path, change
the decision to `approved`, then rerun approval and advance to `done`.

Do not run `hive approve --to draft` while the approval agent is still running:
the task lock deliberately prevents two writers from moving the same folder.

## Authoring checklist

Use this sequence for a workflow of your own:

1. Choose the fewest stages that create a useful handoff.
2. Name the artifact and exit condition for every active stage.
3. Use an outcome-focused instruction for project-specific behavior, or a skill
   when a reviewed reusable behavior already exists.
4. Select the agent and optional model per stage.
5. Grant only permissions the chosen runner can enforce and the stage needs.
6. Add a human checkpoint only where judgment changes the outcome.
7. Make the entry stage capture the brief and define a real terminal outcome.
8. Scaffold, replace every placeholder, and inspect with
   `hive workflow list --json`.
9. Watch the first run, exercise success and rejection, then revise the
   definition before sharing it.

## Common mistakes

- **Vague outcome:** “write something good” does not define an artifact,
  audience, or exit condition.
- **Placeholder instruction:** the blank scaffold's `work.md` is a reminder,
  not useful agent behavior.
- **Missing `COMPLETE`:** a finished artifact without a terminal status marker
  leaves Hive unable to advance it safely.
- **Status mixed with deliverables:** reusing `draft.md` as the draft status file
  can hide the draft from its own revision run.
- **Invalid state-file paths:** `state_file` must be a bare filename, not a
  subdirectory or path traversal.
- **Excessive permissions:** `yolo` or shell/network access is not justified by
  a stage that only reads and writes task-local Markdown.
- **Too many checkpoints:** a gate after every mechanical step adds waiting
  without adding judgment.
- **Copying the nine-stage coding shape:** stage count should follow the process,
  not the flagship example.
- **No terminal completion:** define what done means and ensure the final stage
  can represent it; this example uses an inert `done` stage.

## Built-in, authored, or Honeycomb?

- Use a **built-in** when `coding`, `content`, or `bench` already matches the
  job.
- Keep an **authored project workflow** while the process is local or changing.
- Install a reviewed, versioned **Honeycomb** when you want a shared workflow
  with registry, permission, and review evidence. See the
  [Honeycomb catalog]({{ '/honeycombs/' | relative_url }}).

This authoring guide stops at a safe project-local outcome. Packaging and
registry publication are separate lifecycle decisions.

---

See [`hive init`]({{ '/docs/commands/init/' | relative_url }}),
[`hive new`]({{ '/docs/commands/new/' | relative_url }}),
[`hive run`]({{ '/docs/commands/run/' | relative_url }}), and
[`hive approve`]({{ '/docs/commands/approve/' | relative_url }}) for the command
contracts used above.
