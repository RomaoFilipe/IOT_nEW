import consumer from "./consumer"

consumer.subscriptions.create("SensorChannel", {
  connected() {
    console.log("Conectado ao SensorChannel");
  },

  disconnected() {
    console.log("Desconectado do SensorChannel");
  },

  received(data) {
    // Atualiza DOM com os dados recebidos
    const sensorElement = document.getElementById(`sensor-${data.sensor_id}-status`)
    if (!sensorElement) return;

    if (sensorElement.querySelector(".temperature")) {
      sensorElement.querySelector(".temperature").textContent = `${data.temperature}°C`
    }
    if (sensorElement.querySelector(".moisture")) {
      sensorElement.querySelector(".moisture").textContent = `${data.moisture}%`
    }
    if (sensorElement.querySelector(".battery")) {
      sensorElement.querySelector(".battery").textContent = `${data.battery}%`
    }
    if (sensorElement.querySelector(".signal")) {
      sensorElement.querySelector(".signal").textContent = `${data.signal}%`
    }
    if (sensorElement.querySelector(".last-reading")) {
      sensorElement.querySelector(".last-reading").textContent = data.last_reading
    }
  }
})
