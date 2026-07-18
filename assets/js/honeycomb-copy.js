(() => {
  if (!navigator.clipboard || !navigator.clipboard.writeText) return;

  document.querySelectorAll("[data-honeycomb-copy]").forEach((button) => {
    const source = document.getElementById(button.getAttribute("aria-controls"));
    if (!source) return;

    button.hidden = false;
    button.addEventListener("click", async () => {
      const originalLabel = button.textContent;
      try {
        await navigator.clipboard.writeText(source.textContent);
        button.textContent = "Copied";
      } catch (_error) {
        button.textContent = "Select and copy";
      }
      window.setTimeout(() => { button.textContent = originalLabel; }, 1800);
    });
  });
})();
