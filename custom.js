window.addEventListener("load", () => {
  var tbls = document.getElementsByClassName("amount_table");
  for (var i = 0; i < tbls.length; i++) {
    var tbl = tbls[i];
    var cells = tbl.getElementsByTagName("td");
    for (var j = 0; j < cells.length; j++) {
      var cell = cells[j];
      if (cell.innerText.startsWith("₹")) {
        var val = parseFloat(cell.innerText.slice(1), 10);
        if (!isNaN(val)) {
          if (val == 0) {
            cell.style.color = "transparent";
          } else if (val > 0) {
            cell.style.color = "#0ca678"; //sqlpage teal
          } else {
            cell.style.color = "#f76707"; //sqlpage orange
          }
        }
      }
    }
  }
});
