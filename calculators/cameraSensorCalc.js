(function () {
  // Sensor data with dimensions and aspect ratios
  const sensorData = {
    'full-frame': {
      name: 'Full Frame (35mm)',
      width: 36,
      height: 24,
      aspectRatio: 3/2,
      cropFactor: 1.0
    },
    'aps-c': {
      name: 'APS-C',
      width: 23.6,
      height: 15.6,
      aspectRatio: 3/2,
      cropFactor: 1.53
    },
    'micro-four-thirds': {
      name: 'Micro Four Thirds',
      width: 17.3,
      height: 13,
      aspectRatio: 4/3,
      cropFactor: 2.0
    },
    '1-inch': {
      name: '1" Type',
      width: 13.2,
      height: 8.8,
      aspectRatio: 3/2,
      cropFactor: 2.7
    },
    '1-1.7-inch': {
      name: '1/1.7" Type',
      width: 7.44,
      height: 5.58,
      aspectRatio: 4/3,
      cropFactor: 4.7
    },
    '1-2.5-inch': {
      name: '1/2.5" Type',
      width: 5.76,
      height: 4.29,
      aspectRatio: 4/3,
      cropFactor: 6.0
    }
  };

  // Initialize when DOM is loaded
  document.addEventListener('DOMContentLoaded', function() {
    updateSensorInfo();
    addEventListeners();
  });

  function addEventListeners() {
    const form = document.getElementById('sensorForm');
    const sensorSelect = document.getElementById('sensorSize');

    form.addEventListener('submit', calculateResolution);
    sensorSelect.addEventListener('change', updateSensorInfo);
  }

  function updateSensorInfo() {
    const sensorSelect = document.getElementById('sensorSize');
    const sensorInfo = document.getElementById('sensorInfo');
    const selectedSensor = sensorData[sensorSelect.value];

    sensorInfo.innerHTML = `
      <strong>${selectedSensor.name}</strong><br>
      Dimensions: ${selectedSensor.width} x ${selectedSensor.height} mm<br>
      Aspect Ratio: ${formatAspectRatio(selectedSensor.aspectRatio)}<br>
      Crop Factor: ${selectedSensor.cropFactor}x
    `;
  }

  function formatAspectRatio(ratio) {
    if (Math.abs(ratio - 3/2) < 0.01) return '3:2';
    if (Math.abs(ratio - 4/3) < 0.01) return '4:3';
    if (Math.abs(ratio - 16/9) < 0.01) return '16:9';
    return ratio.toFixed(2) + ':1';
  }

  function calculateResolution(event) {
    event.preventDefault();

    const sensorSelect = document.getElementById('sensorSize');
    const megapixelsInput = document.getElementById('megapixels');
    const resultBox = document.getElementById('resultBox');

    const selectedSensor = sensorData[sensorSelect.value];
    const megapixels = parseFloat(megapixelsInput.value);

    if (megapixels <= 0) {
      alert('Please enter a valid number of megapixels');
      return;
    }

    // Calculate total pixels
    const totalPixels = megapixels * 1000000;

    // Calculate dimensions based on aspect ratio
    // width/height = aspectRatio
    // width * height = totalPixels
    // width = sqrt(totalPixels * aspectRatio)
    // height = totalPixels / width
    const width = Math.round(Math.sqrt(totalPixels * selectedSensor.aspectRatio));
    const height = Math.round(totalPixels / width);

    // Display results
    document.getElementById('resolution').textContent = `${width} x ${height} pixels`;
    document.getElementById('totalPixels').textContent = (width * height).toLocaleString() + ' pixels';
    document.getElementById('aspectRatio').textContent = formatAspectRatio(selectedSensor.aspectRatio) +
      ` (${selectedSensor.aspectRatio.toFixed(3)}:1)`;

    resultBox.classList.add('show');
  }
})();
