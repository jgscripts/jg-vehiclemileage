(function () {
  const odometer = document.querySelector(".odometer");
  const value = document.querySelector(".odometer-value");
  const unit = document.querySelector(".odometer-unit");

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
    } else if (data.type === "hide") {
      odometer.style.display = "none";
    }
  });
})();
