import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer" // Importmap padrão Rails

export default class extends Controller {
  static values = { sensorId: Number }
  static targets = ["soilValue", "soilBadge", "tempValue", "tempBadge", "humValue", "luxValue"]

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "SensorLiveChannel", sensor_id: this.sensorIdValue },
      { received: (data) => this.updateCards(data) }
    )
  }

  disconnect() {
    if (this.subscription) consumer.subscriptions.remove(this.subscription)
  }

  updateCards(data) {
    if (this.hasSoilValueTarget && data.soil_pct != null) {
      this.soilValueTarget.textContent = Number(data.soil_pct).toFixed(1)
      this.updateSoilBadge(Number(data.soil_pct))
    }
    if (this.hasTempValueTarget && data.temp_c != null) {
      this.tempValueTarget.textContent = Number(data.temp_c).toFixed(1)
      this.updateTempBadge(Number(data.temp_c))
    }
    if (this.hasHumValueTarget && data.hum_air != null) {
      this.humValueTarget.textContent = Number(data.hum_air).toFixed(0)
    }
    if (this.hasLuxValueTarget && data.lux != null) {
      this.luxValueTarget.textContent = Number(data.lux).toFixed(0)
    }
  }

  updateSoilBadge(v) {
    if (!this.hasSoilBadgeTarget) return
    const el = this.soilBadgeTarget
    const warn = v < 10 // ajusta thresholds
    el.textContent = warn ? "Atenção" : "Normal"
    el.className = warn
      ? "inline-block px-2 py-1 rounded bg-rose-100 text-rose-700 text-xs"
      : "inline-block px-2 py-1 rounded bg-green-100 text-green-700 text-xs"
  }

  updateTempBadge(v) {
    if (!this.hasTempBadgeTarget) return
    const el = this.tempBadgeTarget
    const warn = (v < 5 || v > 35)
    el.textContent = warn ? "Atenção" : "Normal"
    el.className = warn
      ? "inline-block px-2 py-1 rounded bg-rose-100 text-rose-700 text-xs"
      : "inline-block px-2 py-1 rounded bg-green-100 text-green-700 text-xs"
  }
}
