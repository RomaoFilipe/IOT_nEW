// Stimulus controller para modal + Mapbox GL
import { Controller } from "@hotwired/stimulus"

// Se usares importmap e carregares mapbox-gl via CDN no layout,
// a variável global 'mapboxgl' estará disponível.
// Se usares esbuild/webpack, descomenta as duas linhas abaixo:
// import mapboxgl from "mapbox-gl"
// import "mapbox-gl/dist/mapbox-gl.css"

export default class extends Controller {
  static targets = ["map", "counter", "max", "saveBtn", "modalPanel"]
  static values  = { maxPoints: Number, lat: Number, lng: Number }

  connect() {
    // coloca o valor máximo no UI
    if (this.hasMaxTarget) this.maxTarget.textContent = this.maxPointsValue || 8
    // fecha ao pressionar ESC
    this._onKeyDown = (e) => { if (e.key === "Escape") this.close() }
    document.addEventListener("keydown", this._onKeyDown)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeyDown)
    this.destroyMap()
  }

  open() {
    // mostrar modal
    this.element.classList.remove("hidden")
    this.element.classList.add("flex")

    // coordenadas iniciais (Portugal ou valores passados no botão)
    const lat = this.hasLatValue ? this.latValue : (this._getVal("field_latitude") ?? 41.145)
    const lng = this.hasLngValue ? this.lngValue : (this._getVal("field_longitude") ?? -8.611)

    // cria/garante mapa
    this.ensureMap([lng, lat])

    // prepara estado
    this._coords = []
    this._updateCounter()
  }

  close() {
    this.element.classList.add("hidden")
    this.element.classList.remove("flex")
  }

  reset() {
    this._coords = []
    this._removePolygon()
    this._removeMarkers()
    this._updateCounter()
  }

  save() {
    if (!this._coords || this._coords.length < 3) {
      alert(this._t("fields.boundary.errors.too_few_points", "São necessários pelo menos 3 pontos."))
      return
    }
    const input = document.getElementById("polygonCoordinates")
    if (input) input.value = JSON.stringify(this._coords)
    this.close()
  }

  ensureMap(centerLngLat) {
    // token via CDN (global) ou define aqui:
    if (!window.mapboxgl || !window.mapboxgl.Map) {
      console.error("Mapbox GL não encontrado. Garante JS/CSS no layout.")
      return
    }
    // Define o token se ainda não tiver sido definido
    if (!mapboxgl.accessToken) {
      mapboxgl.accessToken = "pk.eyJ1Ijoicm9tYW9maWxpcGUiLCJhIjoiY204cmpmYzNnMHhkbDJqc2F2enFsZDRxYSJ9.lzMeVTGloDJlV1RHoitdjA"
    }

    if (!this._map) {
      this._markers = []
      this._map = new mapboxgl.Map({
        container: this.mapTarget,
        style: "mapbox://styles/mapbox/satellite-streets-v11",
        center: centerLngLat,
        zoom: 15,
        pitch: 45,
        bearing: -10,
        antialias: true
      })

      this._map.on("load", () => {
        // Terrain opcional
        if (!this._map.getSource("mapbox-dem")) {
          this._map.addSource("mapbox-dem", {
            type: "raster-dem",
            url: "mapbox://mapbox.terrain-rgb",
            tileSize: 512,
            maxzoom: 14
          })
          this._map.setTerrain({ source: "mapbox-dem", exaggeration: 1.2 })
        }
        this._map.resize()
      })

      // clicks para adicionar pontos
      this._map.on("click", (e) => {
        if (this._coords.length >= (this.maxPointsValue || 8)) return
        const { lng, lat } = e.lngLat
        this._coords.push([lng, lat])
        this._addMarker([lng, lat])
        this._drawPolygon()
        this._updateCounter()
      })

      // resize após abrir modal
      requestAnimationFrame(() => this._map.resize())
      setTimeout(() => this._map.resize(), 150)

    } else {
      this._map.setCenter(centerLngLat)
      requestAnimationFrame(() => this._map.resize())
      setTimeout(() => this._map.resize(), 150)
    }
  }

  destroyMap() {
    if (this._map) {
      this._map.remove()
      this._map = null
      this._markers = []
      this._coords = []
    }
  }

  // Helpers internos
  _addMarker(lngLat) {
    const m = new mapboxgl.Marker({ color: "#22c55e" }).setLngLat(lngLat).addTo(this._map)
    this._markers.push(m)
  }

  _removeMarkers() {
    (this._markers || []).forEach(m => m.remove())
    this._markers = []
  }

  _drawPolygon() {
    // remove anterior
    this._removePolygon()
    if (!this._coords || this._coords.length < 2) return

    const poly = {
      type: "Feature",
      geometry: { type: "Polygon", coordinates: [[...this._coords, this._coords[0]]] }
    }

    this._map.addSource("boundary-poly", { type: "geojson", data: poly })
    this._map.addLayer({
      id: "boundary-poly-line",
      type: "line",
      source: "boundary-poly",
      paint: { "line-color": "#10b981", "line-width": 3 }
    })
    this._polyDrawn = true
  }

  _removePolygon() {
    if (!this._map) return
    if (this._map.getLayer("boundary-poly-line")) this._map.removeLayer("boundary-poly-line")
    if (this._map.getSource("boundary-poly")) this._map.removeSource("boundary-poly")
    this._polyDrawn = false
  }

  _updateCounter() {
    if (this.hasCounterTarget) this.counterTarget.textContent = (this._coords?.length || 0)
    if (this.hasSaveBtnTarget) this.saveBtnTarget.disabled = (this._coords?.length || 0) < 3
  }

  _getVal(id) {
    const el = document.getElementById(id)
    if (!el) return null
    const n = parseFloat(el.value)
    return Number.isFinite(n) ? n : null
  }

  _t(i18nKey, fallback) {
    // simples fallback (podes integrar com i18n-js se quiseres)
    return fallback
  }
}
