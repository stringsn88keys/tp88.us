(function () {
  addHooks();
})();

function syncDewPrices(event) {
  targetId = event.target.id;
  unitPrice = event.target.value / event.target.getAttribute("weight");

  document.querySelectorAll('input[type="number"]').forEach(element => {
    if (event.target !== element) {
      element.value = (unitPrice * element.getAttribute("weight")).toFixed(2);
    }
  });
}

function addHooks() {
  document.querySelectorAll('input[type="number"]').forEach(element => {
    element.addEventListener('change', syncDewPrices)
  });
}
