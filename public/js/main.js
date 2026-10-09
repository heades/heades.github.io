(() => {
  // <stdin>
  var filter = document.querySelector("#filter-input");
  var items = document.querySelectorAll(".activity-feed-item");
  var yearHeadings = document.querySelectorAll(".activity-feed-item-year");
  filter.addEventListener("input", () => {
    const query = filter.value.trim().toLowerCase();
    items.forEach((item) => {
      const title = item.getAttribute("data-title")?.toLowerCase() ?? "";
      const tags = item.getAttribute("data-tags")?.toLowerCase() ?? "";
      const year = item.getAttribute("data-year")?.toLowerCase() ?? "";
      const matches = title.includes(query) || tags.includes(query) || year.includes(query);
      if (matches) {
        item.style.display = "";
        document.querySelector(`#year-${year}`).style.display = "";
      } else {
        item.style.display = "none";
        document.querySelector(`#year-${year}`).style.display = "none";
      }
    });
  });
})();
