const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const layout = fs.readFileSync(path.join(__dirname, "..", "_layouts", "doc.html"), "utf8");
const copyScript = layout.match(/<script>\s*([\s\S]*?)\s*<\/script>/)[1];

function loadCopyButton(response) {
  const clickHandlers = [];
  const timers = [];
  const writes = [];
  const button = {
    textContent: "Copy for LLM",
    disabled: false,
    addEventListener(event, handler) {
      assert.equal(event, "click");
      clickHandlers.push(handler);
    },
  };
  const actions = {
    querySelector(selector) {
      assert.equal(selector, ".llm-copy");
      return button;
    },
    getAttribute(name) {
      assert.equal(name, "data-md-url");
      return "/guide.md";
    },
  };
  const context = {
    document: {
      querySelector(selector) {
        assert.equal(selector, ".llm-actions");
        return actions;
      },
    },
    fetch: async (url) => {
      assert.equal(url, "/guide.md");
      return response;
    },
    navigator: {
      clipboard: {
        writeText: async (text) => writes.push(text),
      },
    },
    setTimeout: (callback, delay) => timers.push({ callback, delay }),
  };

  vm.runInNewContext(copyScript, context);
  assert.equal(clickHandlers.length, 1);

  return {
    button,
    timers,
    writes,
    async click() {
      clickHandlers[0]();
      await new Promise(setImmediate);
    },
  };
}

test("copies markdown from a successful response", async () => {
  const markdown = "# Guide\n";
  const harness = loadCopyButton({
    ok: true,
    status: 200,
    text: async () => markdown,
  });

  await harness.click();

  assert.deepEqual(harness.writes, [markdown]);
  assert.equal(harness.button.textContent, "Copied ✓");
  assert.equal(harness.button.disabled, true);
  assert.equal(harness.timers[0].delay, 1800);
});

test("does not copy an HTTP error response", async () => {
  const errorPage = "<html>origin error</html>";
  let bodyReads = 0;
  const harness = loadCopyButton({
    ok: false,
    status: 500,
    text: async () => {
      bodyReads += 1;
      return errorPage;
    },
  });

  await harness.click();

  assert.equal(bodyReads, 0);
  assert.deepEqual(harness.writes, []);
  assert.equal(harness.button.textContent, "Copy failed");
  assert.equal(harness.button.disabled, false);
  assert.equal(harness.timers[0].delay, 1800);
});
