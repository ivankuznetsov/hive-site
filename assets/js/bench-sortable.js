(function () {
  "use strict";

  function compareRows(a, b, key, type, direction, originalOrder) {
    var aRaw = a.getAttribute("data-sort-" + key) || "";
    var bRaw = b.getAttribute("data-sort-" + key) || "";
    var aMissing = aRaw === "";
    var bMissing = bRaw === "";

    if (aMissing !== bMissing) return aMissing ? 1 : -1;
    if (aMissing && bMissing) return originalOrder.get(a) - originalOrder.get(b);

    var result;
    if (type === "number") {
      result = Number(aRaw) - Number(bRaw);
    } else {
      result = aRaw.localeCompare(bRaw, undefined, { numeric: true, sensitivity: "base" });
    }

    if (result === 0) return originalOrder.get(a) - originalOrder.get(b);
    return direction === "ascending" ? result : -result;
  }

  function initSortableTable(table) {
    var body = table.tBodies[0];
    if (!body) return;

    var headers = Array.from(table.querySelectorAll("[data-sort-key]"));
    var headersByKey = new Map(headers.map(function (button) {
      return [button.getAttribute("data-sort-key"), button];
    }));
    var originalOrder = new Map();
    Array.from(body.rows).forEach(function (row, index) {
      originalOrder.set(row, index);
    });

    var board = table.closest(".bench-board");
    var controls = board && board.querySelector("[data-bench-sort-controls]");
    var select = controls && controls.querySelector("[data-bench-sort-select]");
    var directionButton = controls && controls.querySelector("[data-bench-sort-direction]");
    var activeHeader = headers.find(function (button) {
      return button.closest("th").getAttribute("aria-sort") !== "none";
    }) || headers[0];
    var state = {
      key: activeHeader.getAttribute("data-sort-key"),
      direction: activeHeader.closest("th").getAttribute("aria-sort") || "ascending"
    };

    function sortType(key) {
      var header = headersByKey.get(key);
      return header ? header.getAttribute("data-sort-type") : "text";
    }

    function render() {
      var rows = Array.from(body.rows);
      rows.sort(function (a, b) {
        return compareRows(a, b, state.key, sortType(state.key), state.direction, originalOrder);
      });
      rows.forEach(function (row) { body.appendChild(row); });

      headers.forEach(function (button) {
        var active = button.getAttribute("data-sort-key") === state.key;
        var th = button.closest("th");
        var indicator = button.querySelector("[aria-hidden]");
        th.setAttribute("aria-sort", active ? state.direction : "none");
        if (indicator) indicator.textContent = active ? (state.direction === "ascending" ? "↑" : "↓") : "";
      });

      if (select) select.value = state.key;
      if (directionButton) directionButton.textContent = state.direction === "ascending" ? "Ascending" : "Descending";
    }

    function syncHeaderTabStops() {
      var controlsVisible = controls && window.getComputedStyle(controls).display !== "none";
      var focusedHeader = headers.includes(document.activeElement);
      var focusedControls = controls && controls.contains(document.activeElement);
      headers.forEach(function (button) {
        button.tabIndex = controlsVisible ? -1 : 0;
      });
      if (controlsVisible && focusedHeader && select) select.focus();
      if (!controlsVisible && focusedControls) headersByKey.get(state.key).focus();
    }

    headers.forEach(function (button) {
      button.addEventListener("click", function () {
        var key = button.getAttribute("data-sort-key");
        if (state.key === key) {
          state.direction = state.direction === "ascending" ? "descending" : "ascending";
        } else {
          state.key = key;
          state.direction = sortType(key) === "number" ? "descending" : "ascending";
        }
        render();
      });
    });

    if (select) {
      select.addEventListener("change", function () {
        state.key = select.value;
        state.direction = sortType(state.key) === "number" ? "descending" : "ascending";
        render();
      });
    }

    if (directionButton) {
      directionButton.addEventListener("click", function () {
        state.direction = state.direction === "ascending" ? "descending" : "ascending";
        render();
      });
    }

    window.addEventListener("resize", syncHeaderTabStops);

    syncHeaderTabStops();
    render();
  }

  document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll("[data-bench-sortable]").forEach(initSortableTable);
  });
})();
