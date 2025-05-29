import consumer from "./consumer"

export function subscribeToSensorReadings(sensorId) {
  consumer.subscriptions.create(
    { channel: "SensorReadingsChannel", id: sensorId },
    {
      received(data) {
        console.log("🔄 Atualização via WebSocket:", data)

        if (data.temperature !== undefined) {
          const tempEl = document.getElementById(`temperature-${sensorId}`)
          if (tempEl) tempEl.textContent = `${data.temperature}°C`
        }

        if (data.moisture !== undefined) {
          const moistEl = document.getElementById(`moisture-${sensorId}`)
          if (moistEl) moistEl.textContent = `${data.moisture}%`
        }

        if (data.battery !== undefined) {
          const batteryEl = document.getElementById(`battery-${sensorId}`)
          if (batteryEl) batteryEl.textContent = `${data.battery}%`
        }
      }
    }
  )
}
