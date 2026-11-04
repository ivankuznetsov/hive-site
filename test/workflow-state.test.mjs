import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import {
  initialState,
  transition,
  currentStage,
  inspectStage,
  visitAt,
  dockAt,
  flight,
  LAYOUTS,
} from "../assets/js/workflow-state.mjs";
const workflows = JSON.parse(
  await readFile(
    new URL("../_data/workflow_examples.json", import.meta.url),
    "utf8",
  ),
);
const [coding, writing, architecture] = workflows;
const research = JSON.parse(await readFile(new URL("../_data/approval_example.json", import.meta.url), "utf8"));
test("examples distinguish the builtin Coding path from published Writing and Architecture packages", () => {
  assert.deepEqual(
    coding.stages.map((s) => s.id),
    [
      "inbox",
      "brainstorm",
      "plan",
      "execute",
      "open-pr",
      "review",
      "artifacts",
      "finalize",
      "done",
    ],
  );
  assert.equal(coding.badge, "Built-in");
  assert.deepEqual(writing.stages.map((s) => [s.id, s.artifact]), [
    ["inbox", "brief.md"], ["repo-research", "repo-research.md"],
    ["web-research", "web-research.md"], ["research", "research.md"],
    ["draft", "draft.md"], ["editorial", "editorial.md"], ["deliver", "article.md"],
  ]);
  assert.deepEqual(architecture.stages.map((s) => [s.id, s.artifact]), [
    ["inbox", "brief.md"], ["repo-research", "repo-research.txt"],
    ["web-research", "web-research.txt"], ["research", "research.md"],
    ["draft", "draft.md"], ["review", "review.md"],
    ["architecture", "architecture.md"], ["done", "architecture.md"],
  ]);
  for (const flow of [writing, architecture]) {
    assert.equal(flow.badge, "Honeycomb");
    assert.equal(flow.install, `hive workflow install honeycomb/${flow.id}`);
    assert.ok(flow.source.endsWith(`/packages/${flow.id}/${flow.version}`));
    assert.ok(flow.stages.every((s) => !["pr", "code"].includes(s.form) && s.kind !== "human"));
    assert.equal(flow.stages[5].kind, "council");
  }
  assert.equal(writing.version, "1.0.2");
  assert.equal(architecture.version, "1.0.4");
});
test("coding rechecks its repair before evidence, and finishes without losing saved artifacts", () => {
  let state = initialState(coding),
    sawFix = false,
    sawRecheck = false;
  for (let count = 0; state.status !== "complete"; count++) {
    assert.ok(count < 15, "finite example");
    const visit = visitAt(coding, state.position);
    if (visit.phase === "fix") sawFix = true;
    if (visit.phase === "recheck") {
      assert.ok(sawFix);
      sawRecheck = true;
    }
    if (currentStage(state).id === "artifacts") assert.ok(sawRecheck);
    const before = state.saved;
    state = transition(state, { type: "next" });
    assert.ok(before.every((file) => state.saved.includes(file)));
  }
  assert.ok(state.saved.includes("plan.md"));
  assert.ok(state.saved.includes("summary.md"));
  assert.equal(transition(state, { type: "next" }), state);
});
test("an interrupted draft cannot advance; retry preserves saved inputs and increments its attempt", () => {
  const original = inspectStage(writing, 4);
  assert.deepEqual(original.saved, ["brief.md", "repo-research.md", "web-research.md", "research.md"]);
  const stopped = transition(original, { type: "interrupt" });
  assert.equal(stopped.status, "interrupted");
  assert.equal(transition(stopped, { type: "next" }), stopped);
  const retry = transition(stopped, { type: "retry" });
  assert.equal(retry.attempt, 2);
  assert.equal(currentStage(retry).id, "draft");
  assert.deepEqual(retry.saved, original.saved);
  const next = transition(retry, { type: "next" });
  assert.ok(next.saved.includes("draft.md"));
  assert.equal(currentStage(next).id, "editorial");
});
test("each package revises inside its council and preserves both review rounds before delivery", () => {
  for (const flow of [writing, architecture]) {
    let state = inspectStage(flow, 5);
    assert.ok(state.saved.includes("research.md"));
    assert.ok(state.saved.includes("draft.md"));
    const council = currentStage(state);
    assert.equal(visitAt(flow, state.position).phase, "review");
    state = transition(state, { type: "next" });
    assert.equal(currentStage(state), council, "revision is not a fictitious top-level stage");
    assert.equal(visitAt(flow, state.position).phase, "revise");
    assert.ok(state.saved.includes("reviews/triage-01.md"));
    assert.ok(!state.saved.includes(council.artifact), "council is not complete after its first round");
    const before = state.saved;
    state = transition(state, { type: "next" });
    assert.equal(currentStage(state), council);
    assert.equal(visitAt(flow, state.position).phase, "recheck");
    assert.deepEqual(state.saved, before, "revision replaces draft.md without duplicating or dropping saved filenames");
    state = transition(state, { type: "next" });
    assert.ok(state.saved.includes(council.artifact));
    assert.ok(state.saved.includes("reviews/triage-01.md"));
    assert.ok(state.saved.includes("reviews/triage-02.md"));
    assert.equal(currentStage(state).id, flow.id === "writing" ? "deliver" : "architecture");
    while (state.status !== "complete") state = transition(state, { type: "next" });
    assert.ok(state.saved.includes(flow.id === "writing" ? "verification.md" : "architecture.md"));
    assert.equal(new Set(state.saved).size, state.saved.length);
    assert.equal(transition(state, { type: "interrupt" }), state);
    const fresh = initialState(flow);
    assert.equal(fresh.position, 0);
    assert.deepEqual(fresh.saved, ["brief.md"]);
    assert.equal(fresh.attempt, 1);
    assert.equal(fresh.recovered, false);
  }
});
test("a retry inside the council keeps its round and earlier evidence without manufacturing completion", () => {
  const first = inspectStage(writing, 5);
  const revision = transition(first, { type: "next" });
  const stopped = transition(revision, { type: "interrupt" });
  assert.equal(stopped.status, "interrupted");
  assert.equal(transition(stopped, { type: "next" }), stopped);
  const retried = transition(stopped, { type: "retry" });
  assert.equal(retried.attempt, 2);
  assert.equal(retried.position, revision.position);
  assert.deepEqual(retried.saved, revision.saved);
  assert.ok(!retried.saved.includes("editorial.md"));
  const recheck = transition(retried, { type: "next" });
  assert.equal(recheck.attempt, 2, "council substeps are still part of the same retried stage");
  assert.equal(transition(recheck, { type: "next" }).attempt, 1, "delivery starts its own attempt");
});
test("a human gate cannot be bypassed by playback or retry, and approval is explicit", () => {
  const gate = inspectStage(research, 2);
  assert.equal(gate.status, "waiting");
  assert.deepEqual(gate.saved, ["research.md", "report.md"]);
  for (const type of ["next", "retry", "interrupt"])
    assert.equal(transition(gate, { type }), gate);
  const approved = transition(gate, { type: "approve" });
  assert.equal(approved.status, "complete");
  assert.deepEqual(approved.decisions, ["approved"]);
  assert.ok(approved.saved.includes("approval.md"));
  assert.equal(
    transition(initialState(research), { type: "approve" }).status,
    "ready",
  );
});
test("rejection returns the same task to synthesis without discarding evidence or its decision", () => {
  const gate = inspectStage(research, 2),
    revision = transition(gate, { type: "reject" });
  assert.equal(revision.workflow, gate.workflow);
  assert.equal(currentStage(revision).id, "synthesis");
  assert.ok(gate.saved.every((f) => revision.saved.includes(f)));
  const again = transition(revision, { type: "next" });
  assert.equal(again.status, "waiting");
  const result = transition(again, { type: "approve" });
  assert.deepEqual(result.decisions, ["revision requested", "approved"]);
});
test("human rejection follows its declared target, not the adjacent stage index", () => {
  const flow = structuredClone(research);
  flow.stages.splice(2, 0, { id: "check", kind: "agent", artifact: "check.md" });
  flow.route = [0, 1, 2, 3];
  const gate = inspectStage(flow, 3);
  const rejected = transition(gate, { type: "reject" });
  assert.equal(currentStage(rejected).id, "synthesis");
  assert.ok(rejected.saved.includes("check.md"));
  assert.equal(currentStage(transition(rejected, { type: "next" })).id, "check");
});
test("a first-stage human gate starts waiting and cannot advance itself", () => {
  const flow = { stages: [{ id: "approval", artifact: "approval.md", kind: "human" }], route: [0] };
  const state = initialState(flow);
  assert.equal(state.status, "waiting");
  assert.equal(transition(state, { type: "next" }), state);
  assert.equal(transition(state, { type: "reject" }), state, "an invalid rejection target cannot move the task");
});
test("carrier handoffs start and end at machine surfaces, including the open side of a review gate", () => {
  for (const flow of workflows) {
    for (let i = 0; i < flow.route.length - 1; i++) {
      const first = visitAt(flow, i).stage, next = visitAt(flow, i + 1).stage;
      const from = dockAt(flow, first),
        to = dockAt(flow, next),
        fg = flow.stages[first].machine === "review",
        tg = flow.stages[next].machine === "review";
      assert.deepEqual(flight(from, to, 0, fg, tg), from);
      assert.deepEqual(flight(from, to, 1, fg, tg), to);
      assert.ok(flight(from, to, 0.5, fg, tg).y < Math.min(from.y, to.y));
    }
  }
});

test("the flat request fits both the intake tray and the receiving brainstorm surface", () => {
  // Actual local SVG work planes; packet corners use its isometric projection.
  const planes = [
    [
      [-51, -5],
      [0, -34.5],
      [51, -5],
      [0, 24.5],
    ],
    [
      [-45, -37],
      [0, -63],
      [45, -37],
      [0, -11],
    ],
  ];
  for (let i = 0; i < 2; i++) {
    const dock = dockAt(coding, i),
      origin = LAYOUTS.coding[i];
    for (const [px, py] of [
      [-16, -13],
      [16, -13],
      [16, 13],
      [-16, 13],
    ]) {
      const x = dock.x - origin[0] + (px - py) * dock.scale;
      const y = dock.y - origin[1] + 10 + (px + py) * 0.5774 * dock.scale;
      assert.ok(
        planes[i].every(([ax, ay], edge) => {
          const [bx, by] = planes[i][(edge + 1) % 4];
          return (bx - ax) * (y - ay) - (by - ay) * (x - ax) >= -0.01;
        }),
        `request corner ${px},${py} must stay on stage ${i + 1}'s surface`,
      );
    }
  }
});
