window.addEventListener("load", () => {
  // add specific colors for amounts
  colorifyAmounts: {
    const rupeeFormatter = new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0,
    });
    var tbls = document.getElementsByClassName("amount_table");
    for (var i = 0; i < tbls.length; i++) {
      var tbl = tbls[i];
      var cells = tbl.getElementsByTagName("td");
      for (var j = 0; j < cells.length; j++) {
        var cell = cells[j];
        if (cell.innerText.includes("₹")) {
          var val = parseFloat(cell.innerText.replace(/[₹,]/g, ""));
          if (!isNaN(val)) {
            if (val == 0) {
              cell.style.color = "transparent";
            } else if (val > 0) {
              cell.style.color = "#0ca678"; //sqlpage teal
            } else {
              cell.style.color = "#f76707"; //sqlpage orange
            }
            cell.innerText = rupeeFormatter.format(val);
          }
        }
      }
    }
    var big_number_bar = document.getElementById("colorfull_dashboard");
    var boxes = big_number_bar.getElementsByClassName("h1 mb-0")
    for (var i = 0; i < boxes.length; i++) {
      var cell = boxes[i];
      if (cell.innerText.includes("₹")) {
        const val = parseFloat(cell.innerText.replace(/[₹,]/g, ""));
        cell.innerText = rupeeFormatter.format(val);
      }
    }
    var other_amounts = document.getElementsByClassName("hr-text");
    for (var i = 0; i < other_amounts.length; i++) {
      var cell = other_amounts[i];
      if (cell.innerText.includes("₹")) {
        const text = cell.innerText;
        const startingIndex = text.indexOf("₹")+1;
        const prefix = text.slice(0, startingIndex-1);
        const match = text.slice(startingIndex).match(/^[-\d.]+/);
        const suffix = text.slice(startingIndex + match[0].length)
        const extractedNumber = match ? Number(match[0]) : null;
        const val = parseFloat(extractedNumber, "");
        const ftext = rupeeFormatter.format(val);
        cell.innerText = prefix + ftext + suffix;
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

  //FIXME: this doesn't reset the multi-select boxes; so for now, using simple redirect to one button clear the form
  formReset : {
    const form = document.getElementById('filter_form');
    if (form) {
      console.log("Form identitied in window load");
      form.addEventListener('reset', () => {
          console.log('Form reset');
          const formInputs = document.querySelectorAll("#filter_form input");
          formInputs.forEach(input => {
              console.log(input.name + " -> " + input.type + '|' + input.value);
              switch (input.type) {
                  case 'radio':
                  case 'checkbox':
                    input.checked = false;
                    input.value = 0;
                    break;
                  case 'text':
                    input.value = '';
                    break;
                  default:
                    break;
              }
          })
      });
    }
  }

});
