document.addEventListener("DOMContentLoaded", function () {
    const modal = document.getElementById("field-modal");
    const closeModal = document.getElementById("close-modal");
  
    document.querySelectorAll(".open-modal").forEach(button => {
      button.addEventListener("click", function () {
        const fieldId = this.dataset.id;
  
        fetch(`/fields/${fieldId}.json`)
          .then(response => response.json())
          .then(data => {
            document.getElementById("field-name").innerText = data.name;
            document.getElementById("field-status").innerText = data.status;
            document.getElementById("field-crop").innerText = data.crop;
            document.getElementById("field-area").innerText = data.area;
            document.getElementById("field-soil-quality").innerText = data.soil_quality;
            document.getElementById("field-sensors").innerText = data.sensors_count;
            document.getElementById("field-updated").innerText = data.updated_at;
            document.getElementById("field-moisture").innerText = data.moisture_level;
            document.getElementById("field-temperature").innerText = data.temperature;
            document.getElementById("field-health").innerText = data.health;
            document.getElementById("field-irrigation").innerText = data.irrigation;
  
            modal.classList.remove("hidden");
          });
      });
    });
  
    closeModal.addEventListener("click", function () {
      modal.classList.add("hidden");
    });
  });
  