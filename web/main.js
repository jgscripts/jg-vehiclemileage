(function () {
  const odometer = document.querySelector(".odometer");
  const value = document.querySelector(".odometer-value");
  const unit = document.querySelector(".odometer-unit");

  function elementPosition(position) {
    element = odometer;
    element.style.top = '';
    element.style.bottom = '';
    element.style.left = '';
    element.style.right = '';
    element.style.transform = '';

    switch (position) {
      
      case 'bottom-right':
        element.style.bottom = '0';
        element.style.right = '0';
        break;
      case 'bottom-left':
        element.style.bottom = '0';
        element.style.left = '0';
        break;
      case 'top-right':
        element.style.top = '0';
        element.style.right = '0';
        break;
      case 'top-left':
        element.style.top = '0';
        element.style.left = '0';
        break;
      case 'bottom-center':
        element.style.bottom = '0';
        element.style.left = '50%';
        element.style.transform = 'translateX(-50%)';
        break;
      case 'top-center':
        element.style.top = '0';
        element.style.left = '50%';
        element.style.transform = 'translateX(-50%)';
        break;
      default:
        element.style.bottom = '0';
        element.style.right = '0';
        break;
    }
  }

  window.addEventListener("message", (evt) => {
    const { data } = evt;

    if (!data) return false;

    if (data.type === "show") {
      odometer.style.display = "flex";
      value.innerHTML = Math.floor(
        data.value * (data.unit === "miles" ? 0.621371 : 1)
      )
        .toString()
        .padStart(6, "0");
      unit.innerHTML = data.unit === "miles" ? "MI" : "KM";
      elementPosition(data.position);
    } else if (data.type === "hide") {
      odometer.style.display = "none";
    }
  });
})();
