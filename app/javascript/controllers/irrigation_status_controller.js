import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    sensorId: Number,
    duration: Number // duração total prevista
  }

  static targets = ["label", "bar"]

  connect() {
    this.refresh()
    this.interval = setInterval(() => this.refresh(), 10000) // 10s
  }

  disconnect() {
    clearInterval(this.interval)
  }

  refresh() {
    fetch(`/sensors/${this.sensorIdValue}/status_info`)
      .then(response => response.json())
      .then(data => {
        const status = data.status
        const remaining = data.remaining_time
        const duration = this.durationValue

        const percentage = status === "irrigando"
          ? Math.round((remaining / duration) * 100)
          : 0

        // Atualizar texto
        this.labelTarget.textContent = status === "irrigando"
          ? `Irrigando (${remaining}s restantes)`
          : "Parado"

        // Atualizar barra
        this.barTarget.style.width = `${percentage}%`
        this.barTarget.className = `h-2 rounded-full transition-all duration-300 ${status === "irrigando" ? 'bg-green-500' : 'bg-gray-400'}`
      })
      .catch(error => {
        console.error("Erro ao atualizar estado de irrigação:", error)
      })
  }
}
