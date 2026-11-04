// A small illustrative state machine, not a Hive runtime or recorded execution.
// Saved artifacts belong to the task; attempts and decisions have separate lives.
export const visitAt = (workflow, position) => {
  const visit = workflow.route[position];
  return typeof visit === "number" ? { stage: visit } : visit;
};
export function initialState(workflow) {
  const first = workflow.stages[visitAt(workflow, 0).stage];
  return {
    workflow,
    position: 0,
    saved: first.kind === "inert" ? [first.artifact] : [],
    status: "ready",
    attempt: 1,
    decisions: [],
    recovered: false,
  };
}
export const currentStage = (state) =>
  state.workflow.stages[visitAt(state.workflow, state.position).stage];
const save = (files, artifact) =>
  artifact === "decision" || files.includes(artifact)
    ? files
    : [...files, artifact];
export function transition(state, action) {
  const stage = currentStage(state);
  switch (action.type) {
    case "next": {
      if (["waiting", "interrupted", "complete"].includes(state.status))
        return state;
      const saved = save(state.saved, stage.artifact);
      if (state.position === state.workflow.route.length - 1)
        return { ...state, saved, status: "complete" };
      const position = state.position + 1;
      const nextStage =
        state.workflow.stages[visitAt(state.workflow, position).stage];
      return {
        ...state,
        position,
        saved,
        attempt: 1,
        status: nextStage.kind === "human" ? "waiting" : "ready",
      };
    }
    case "interrupt":
      return stage.kind === "agent" &&
        !["complete", "waiting", "interrupted"].includes(state.status)
        ? { ...state, status: "interrupted" }
        : state;
    case "retry":
      return state.status === "interrupted"
        ? {
            ...state,
            status: "ready",
            attempt: state.attempt + 1,
            recovered: true,
          }
        : state;
    case "approve":
      return state.status === "waiting"
        ? {
            ...state,
            status: "complete",
            saved: save(state.saved, "approval.md"),
            decisions: [...state.decisions, "approved"],
          }
        : state;
    case "reject":
      return state.status === "waiting"
        ? {
            ...state,
            position: state.position - 1,
            status: "ready",
            saved: save(state.saved, "approval.md"),
            decisions: [...state.decisions, "revision requested"],
          }
        : state;
    default:
      return state;
  }
}
// Station inspection constructs a narrative position; it does not mutate a live task.
export function inspectStage(workflow, index) {
  let state = initialState(workflow);
  const position = workflow.route.findIndex(
    (visit) => (typeof visit === "number" ? visit : visit.stage) === index,
  );
  for (let i = 0; i < position; i++)
    state = transition(state, { type: "next" });
  return state;
}
export const LAYOUTS = {
  coding: [
    [150, 190],
    [330, 294],
    [510, 190],
    [690, 294],
    [870, 190],
    [1050, 294],
    [870, 398],
    [690, 502],
    [510, 398],
  ],
  content: [
    [200, 210],
    [420, 337],
    [640, 210],
    [860, 337],
    [640, 464],
    [420, 591],
  ],
  research: [
    [260, 250],
    [520, 400],
    [780, 250],
  ],
};
const DOCKS = {
  idea: [0, -15, 1.05],
  brainstorm: [-8, -39, 0.85],
  plan: [-12, -67, 0.7],
  build: [25, -107, 0.85],
  pr: [0, -27, 1.2],
  review: [0, -18, 1],
  artifacts: [8, 5, 0.8],
  finalize: [0, -75, 0.8],
  done: [0, -75, 0.9],
};
export function dockAt(workflow, index) {
  const [x, y] = LAYOUTS[workflow.id][index];
  const [dx, dy, scale] = DOCKS[workflow.stages[index].machine];
  return { x: x + dx, y: y + dy, scale };
}
export const clamp = (n, lo = 0, hi = 1) => Math.min(hi, Math.max(lo, n));
const smooth = (p) => p * p * (3 - 2 * p);
const mix = (a, b, p) => a + (b - a) * p;
// Reuses HiveDev's lift → carry → land grammar and surface docks. Review's
// solid scanner is entered from its open right side, not through the roof.
export function flight(from, to, p, fromGate = false, toGate = false) {
  p = clamp(p);
  const departure = from.x + (fromGate ? 90 : 0),
    arrival = to.x + (toGate ? 90 : 0);
  const up = smooth(
    clamp((p - (fromGate ? 0.12 : 0)) / (fromGate ? 0.13 : 0.25)),
  );
  const down = smooth(clamp((p - 0.75) / (toGate ? 0.15 : 0.25)));
  let x = mix(departure, arrival, smooth(clamp((p - 0.25) / 0.5)));
  if (fromGate && p < 0.12) x = mix(from.x, departure, smooth(p / 0.12));
  if (toGate && p > 0.9) x = mix(arrival, to.x, smooth((p - 0.9) / 0.1));
  const cruise = Math.min(from.y, to.y) - 145;
  return {
    x,
    y: mix(from.y, cruise, up) + (to.y - cruise) * down,
    scale: mix(from.scale, to.scale, smooth(p)),
  };
}
