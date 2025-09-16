import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = { sensorId: Number, total: Number, remaining: Number }
  static targets = ["bar", "label", "state"]

  connect() {
    this._paint()                       // pinta estado inicial
    this._startLocalTimerIfNeeded()     // começa a descer 1s/1s

    // sincroniza por WebSocket quando o servidor emitir start/stop/updates
    this.sub = consumer.subscriptions.create(
      { channel: "IrrigationChannel", sensor_id: this.sensorIdValue },
      { received: (data) => this._sync(data) }
    )
  }

  disconnect() {
    this._clearTimer()
    if (this.sub) consumer.subscriptions.remove(this.sub)
  }

  // ----- privados -----
  _startLocalTimerIfNeeded() {
    if (this.remainingValue > 0 && this.totalValue > 0) {
      this._clearTimer()
      this.timer = setInterval(() => {
        this.remainingValue = Math.max(this.remainingValue - 1, 0)
        this._paint()
        if (this.remainingValue === 0) this._clearTimer()
      }, 1000)
    }
  }

  _clearTimer() {
    if (this.timer) { clearInterval(this.timer); this.timer = null }
  }

  _sync(data) {
    // servidor envia { remaining_time: N, total_time: M }
    const total = Number(data.total_time || 0)
    const rem   = Number(data.remaining_time || 0)

    this.totalValue     = total
    this.remainingValue = rem

    if (this.hasStateTarget) this.stateTarget.textContent = rem > 0 ? "Irrigando" : "Parado"

    if (rem > 0) this._startLocalTimerIfNeeded()
    else this._clearTimer()

    this._paint()
  }

  _paint() {
    // label “Faltam:”
    if (this.hasLabelTarget) this.labelTarget.textContent = this._fmt(this.remainingValue)

    // barra de progresso
    if (this.hasBarTarget && this.totalValue > 0) {
      const pct = Math.min(100, Math.max(0, ((this.totalValue - this.remainingValue) / this.totalValue) * 100))
      this.barTarget.style.width = `${pct.toFixed(2)}%`
    }
  }

  _fmt(s) {
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60
    const pad = n => String(n).padStart(2, "0")
    return `${pad(h)}h ${pad(m)}m ${pad(sec)}s`
  }
}
