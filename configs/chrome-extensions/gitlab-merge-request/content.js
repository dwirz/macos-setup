(function () {
  document.addEventListener("keydown", (event) => {
    if (["INPUT", "TEXTAREA"].includes(document.activeElement?.tagName ?? "")) {
      return;
    }

    if (event.key === "]") {
      const nextButton = document.querySelector(
        '[data-testid="gl-pagination-next"]',
      );
      if (nextButton) nextButton.click();
      return;
    }

    if (event.key === "[") {
      const prevButton = document.querySelector(
        '[data-testid="gl-pagination-prev"]',
      );
      if (prevButton) prevButton.click();
      return;
    }

    if (event.key === "o") {
      const menu = document.querySelector("ul.view-modes-menu");
      const onionItem =
        menu &&
        Array.from(menu.querySelectorAll("li")).find((li) =>
          li.textContent.trim().includes("Onion skin"),
        );
      if (onionItem) onionItem.click();
      return;
    }

    if (event.key === "m") {
      const addedFrame = document.querySelector(".added.frame");
      if (addedFrame) {
        addedFrame.style.opacity = "50%";
      }
      return;
    }

    if (event.key === "r") {
      const addedFrame = document.querySelector(".added.frame");
      if (addedFrame) {
        addedFrame.style.opacity = "100%";
      }
      return;
    }
  });
})();
