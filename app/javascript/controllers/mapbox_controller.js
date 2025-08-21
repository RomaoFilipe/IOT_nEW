import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    lat: Number,
    lng: Number,
    zoom: { type: Number, default: 13 },
    token: String
  }

  connect() {
    if (!window.mapboxgl || !mapboxgl.Map) return
    if (this.element.dataset.initialized === "true") return

    const token = (this.tokenValue || "").startsWith("pk.")
      ? this.tokenValue
      : (window.MAPBOX_PUBLIC_TOKEN || "")

    if (!token || !token.startsWith("pk.")) {
      console.warn("Mapbox: token público (pk.*) em falta.")
      return
    }

    this.element.style.minHeight = this.element.style.minHeight || "240px"
    this.element.dataset.initialized = "true"

    mapboxgl.accessToken = token

    this.map = new mapboxgl.Map({
      container: this.element.id,
      style: "mapbox://styles/mapbox/outdoors-v12",
      center: [this.lngValue, this.latValue],
      zoom: this.zoomValue,
      attributionControl: false
    })

    this.map.on("load", () => {
      new mapboxgl.Marker({ color: "#059669" })
        .setLngLat([this.lngValue, this.latValue])
        .addTo(this.map)
      setTimeout(() => this.map.resize(), 80)
    })

    this._beforeCache = () => this.teardown()
    document.addEventListener("turbo:before-cache", this._beforeCache, { once: true })
  }

  disconnect() {
    this.teardown()
  }

  teardown() {
    try { this.map && this.map.remove() } catch(_) {}
    if (this.element) this.element.dataset.initialized = "false"
    if (this._beforeCache) {
      document.removeEventListener("turbo:before-cache", this._beforeCache)
      this._beforeCache = null
    }
  }
}
