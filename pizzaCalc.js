(function () {
  addHooks();
})();

// Function to update prices dynamically based on the first input
function updatePrices() {
  const form = document.getElementById('pizzaForm');
  const diameterInputs = form.querySelectorAll('input[id$="diameter"]');
  syncPizzaPrices({ target: diameterInputs[0] });
}

// Initialize prices on page load
document.addEventListener('DOMContentLoaded', updatePrices);

function syncPizzaPrices(event) {
  console.log(event);
  targetId = event.target.id;
  targetSize = targetId.match(/size\d+/);
  if (targetId.includes('diameter')) {
    unitPrice = document.getElementById(targetSize + 'price').value / (Math.PI * Math.pow(event.target.value / 2, 2));
  }
  if (targetId.includes('price')) {
    unitPrice = event.target.value / (Math.PI * Math.pow(document.getElementById(targetSize + 'diameter').value / 2, 2));
  }
  document.querySelectorAll('input[id$="price"]').forEach(element => {
    if (event.target !== element) {
      sizeElement = document.getElementById(element.id.match(/size\d+/) + 'diameter');
      element.value = (unitPrice * (Math.PI * Math.pow(sizeElement.value / 2, 2))).toFixed(2);
    }
  });
}

function addHooks() {
  document.querySelectorAll('input[type="number"]').forEach(element => {
    element.addEventListener('change', syncPizzaPrices)
  });
}