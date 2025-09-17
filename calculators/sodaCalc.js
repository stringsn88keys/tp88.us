(function () {
  addHooks();
})();

function calculatePrices(event) {
  event.preventDefault();
  
  const selectedSize = document.getElementById('packageSize').value;
  const price = parseFloat(document.getElementById('price').value);
  
  if (!selectedSize || !price || price <= 0) {
    alert('Please select a package size and enter a valid price.');
    return;
  }
  
  // Find the selected package using the function from soda_options.js.erb
  const selectedPackage = getPackageById(selectedSize);
  if (!selectedPackage) {
    alert('Invalid package size selected.');
    return;
  }
  
  // Calculate unit price per ounce
  const unitPricePerOunce = price / selectedPackage.ounces;
  
  // Calculate prices for all other packages using the function from soda_options.js.erb
  const allPackages = getAllPackages();
  const priceEquivalents = allPackages
    .filter(pkg => pkg.id !== selectedSize) // Exclude the selected package
    .map(pkg => ({
      ...pkg,
      price: unitPricePerOunce * pkg.ounces,
      unitPrice: unitPricePerOunce
    }))
    .sort((a, b) => a.price - b.price); // Sort by price ascending
  
  displayResults(priceEquivalents, selectedPackage, price, unitPricePerOunce);
}

function displayResults(priceEquivalents, selectedPackage, originalPrice, unitPricePerOunce) {
  const resultsDiv = document.getElementById('results');
  const priceListDiv = document.getElementById('priceList');
  
  // Clear previous results
  priceListDiv.innerHTML = '';
  
  // Add header showing the selected package and unit price
  const headerHtml = `
    <div class="price-item" style="border-left-color: #ffd93d;">
      <div class="row align-items-center">
        <div class="col-md-6">
          <span class="package-size">${selectedPackage.name}</span>
          <div class="package-details">[${selectedPackage.containers} containers, ${selectedPackage.unit}: ${selectedPackage.size}]</div>
        </div>
        <div class="col-md-3 text-center">
          <span class="price-value">$${originalPrice.toFixed(2)}</span>
        </div>
        <div class="col-md-3 text-center">
          <span class="unit-price">$${unitPricePerOunce.toFixed(4)}/oz</span>
        </div>
      </div>
    </div>
  `;
  priceListDiv.innerHTML = headerHtml;
  
  // Add all other package prices
  priceEquivalents.forEach(pkg => {
    const priceItemHtml = `
      <div class="price-item">
        <div class="row align-items-center">
          <div class="col-md-6">
            <span class="package-size">${pkg.name}</span>
            <div class="package-details">[${pkg.containers} containers, ${pkg.unit}: ${pkg.size}]</div>
          </div>
          <div class="col-md-3 text-center">
            <span class="price-value">$${pkg.price.toFixed(2)}</span>
          </div>
          <div class="col-md-3 text-center">
            <span class="unit-price">$${pkg.unitPrice.toFixed(4)}/oz</span>
          </div>
        </div>
      </div>
    `;
    priceListDiv.innerHTML += priceItemHtml;
  });
  
  // Show results
  resultsDiv.style.display = 'block';
  
  // Scroll to results
  resultsDiv.scrollIntoView({ behavior: 'smooth' });
}

function addHooks() {
  const form = document.getElementById('sodaForm');
  if (form) {
    form.addEventListener('submit', calculatePrices);
  }
}
