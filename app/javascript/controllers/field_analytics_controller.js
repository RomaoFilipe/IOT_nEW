// app/javascript/controllers/field_analytics_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  async reload() {
    const params = new URLSearchParams({
      granularity: this.currentGranularity() || "5m", // teste → 5m
      from: this.fromISO(),
      to:   this.toISO()
    })
    const res = await fetch(`${this.urlValue}?${params.toString()}`, {
      headers: { "Accept": "application/json" }
    })
    if (!res.ok) return console.error("Falha a obter analytics", res.status)
    const data = await res.json()
    this.updateCards(data)
    this.updateCharts(data.series)
  }

  // --- helpers de UI (ajusta aos teus inputs) ---
  currentGranularity() { return document.querySelector("[data-gran] .is-active")?.dataset.gran }
  fromISO() { return document.querySelector("#analytics-from")?.value || "" }
  toISO()   { return document.querySelector("#analytics-to")?.value   || "" }

  updateCards(data) {
    // exemplo: preencher cartões
    const n = (v, u="") => (v==null ? "—" : `${(+v).toFixed(1)}${u}`)
    document.querySelector("#kpi-soil")?.replaceChildren(n(data.series.soil_moisture?.at(-1)))
    document.querySelector("#kpi-temp")?.replaceChildren(n(data.max_temp, "°C"))
    document.querySelector("#kpi-hum") ?.replaceChildren(n(data.avg_humidity, "%"))
  }

  updateCharts(series) {
    // alimenta o teu ApexCharts existente
    // ex.: chart.updateSeries([{ name:"Solo %", data: series.times.map((t,i)=>[new Date(t).getTime(), series.soil_moisture[i]]) }])
  }
}
