// app/javascript/controllers/irrigation_status_controller.js
import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static values = {
    sensorId: Number
  }

  static targets = ["label", "bar"]

  connect() {
    if (!this.sensorIdValue) return;

    this.subscription = consumer.subscriptions.create(
      { channel: "IrrigationStatusChannel", sensor_id: this.sensorIdValue },
      {
        received: (data) => this.updateStatus(data)
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
  }

  updateStatus(data) {
    const { status, remaining_time, duration } = data

    if (!this.hasLabelTarget || !this.hasBarTarget) return

    if (status === "irrigando") {
      this.labelTarget.textContent = `Irrigando (${remaining_time}s restantes)`
      this.labelTarget.classList.remove("text-gray-600")
      this.labelTarget.classList.add("text-green-600")
      this.barTarget.classList.remove("bg-gray-400")
      this.barTarget.classList.add("bg-green-500")
    } else {
      this.labelTarget.textContent = "Parado"
      this.labelTarget.classList.remove("text-green-600")
      this.labelTarget.classList.add("text-gray-600")
      this.barTarget.classList.remove("bg-green-500")
      this.barTarget.classList.add("bg-gray-400")
    }

    const percent = duration > 0 ? Math.max((remaining_time * 100) / duration, 0) : 0
    this.barTarget.style.width = `${percent}%`
  }
}
