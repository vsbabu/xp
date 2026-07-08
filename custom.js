window.addEventListener("load", () => {
  // add specific colors for amounts
  colorifyAmounts: {
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
  }

  //add prev and next links if possible from menu match
  //this is a lot easier than doing in shell.sql using sql.
  //the links only show up after page is loaded though.
  navigationAdder : {
    const urlParams = new URLSearchParams(window.location.search); if (!urlParams) break navigationAdder;
    const t         = urlParams.get("t");                          if (!t) break navigationAdder;
    const h1        = document.querySelector('h1');                if (!h1) break navigationAdder;
    const current   = Array.from(document.querySelectorAll('a'))
                           .find(el => el.innerText.trim() === t); if (!current) break navigationAdder;
    const nxt = current.previousElementSibling;
    const prv = current.nextElementSibling;
    var tobe = h1.innerText;
    if (prv) tobe = tobe + '<div style="display:block; float:right; font-weight: normal; font-size: normal;"><a href="' + prv.getAttribute('href') + '" title="' + prv.innerText + '"> &laquo </a> ';
    if (nxt) tobe = tobe + '<a href="' + nxt.getAttribute('href') + '" title="' + nxt.innerText + '"> &raquo </a><div>';
    h1.innerHTML = tobe;
  }

});
