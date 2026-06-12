import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "video", "status", "manualForm", "manualInput", "retryBtn"]
  static values = { lookupUrl: String }

  connect() {
    this._stream = null
    this._scanning = false
    this._detector = null
    this._retryBarcode = null
  }

  disconnect() {
    this._stopCamera()
  }

  async open() {
    this._showOverlay()

    if (!("BarcodeDetector" in window)) {
      this._showManual("Your browser doesn't support camera scanning. Enter the barcode number below:")
      return
    }

    try {
      this._stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" }
      })
      this.videoTarget.srcObject = this._stream
      await this.videoTarget.play()
      this._detector = new window.BarcodeDetector({
        formats: ["ean_13", "upc_a", "upc_e", "ean_8"]
      })
      this._setStatus("Scanning… point your camera at the barcode")
      this._scanning = true
      this._scanLoop()
    } catch {
      this._showManual("Camera access denied. Enter the barcode number below:")
    }
  }

  close() {
    this._stopCamera()
    this._hideOverlay()
  }

  async submitManual(event) {
    event.preventDefault()
    const barcode = this.manualInputTarget.value.trim()
    if (barcode) await this._lookup(barcode)
  }

  async retry() {
    this.retryBtnTarget.classList.add("hidden")
    if (this._retryBarcode) await this._lookup(this._retryBarcode)
  }

  async _scanLoop() {
    if (!this._scanning) return
    try {
      const results = await this._detector.detect(this.videoTarget)
      if (results.length > 0) {
        this._scanning = false
        this._stopCamera()
        await this._lookup(results[0].rawValue)
        return
      }
    } catch { /* frame not ready yet */ }
    if (this._scanning) requestAnimationFrame(() => this._scanLoop())
  }

  async _lookup(barcode) {
    this._setStatus("Looking up on Discogs…")
    this.manualFormTarget.classList.add("hidden")

    try {
      const resp = await fetch(
        `${this.lookupUrlValue}?barcode=${encodeURIComponent(barcode)}`,
        { headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" } }
      )
      const data = await resp.json()

      if (resp.ok) {
        this._openPanel(data)
        this._hideOverlay()
      } else if (resp.status === 404) {
        this._showManual(`No Discogs result for "${barcode}". Try another barcode or enter it manually:`, barcode)
      } else {
        this._setStatus("Discogs lookup failed.")
        this._retryBarcode = barcode
        this.retryBtnTarget.classList.remove("hidden")
      }
    } catch {
      this._setStatus("Network error. Check your connection.")
      this._retryBarcode = barcode
      this.retryBtnTarget.classList.remove("hidden")
    }
  }

  _openPanel(data) {
    const params = new URLSearchParams()
    for (const [k, v] of Object.entries(data)) {
      if (v != null && v !== "") params.set(k, String(v))
    }
    document.getElementById("panel_content").src = `/records/new?${params}`
    document.dispatchEvent(new CustomEvent("scanner:open-panel"))
  }

  _showManual(message, value = "") {
    this._setStatus(message)
    this.manualInputTarget.value = value
    this.manualFormTarget.classList.remove("hidden")
    this.manualInputTarget.focus()
  }

  _stopCamera() {
    this._scanning = false
    this._stream?.getTracks().forEach(t => t.stop())
    this._stream = null
    this.videoTarget.srcObject = null
  }

  _setStatus(text) {
    this.statusTarget.textContent = text
  }

  _showOverlay() {
    this.overlayTarget.classList.add("scanner-open")
    document.body.classList.add("scanner-active")
  }

  _hideOverlay() {
    this.overlayTarget.classList.remove("scanner-open")
    document.body.classList.remove("scanner-active")
    this.manualFormTarget.classList.add("hidden")
    this.retryBtnTarget.classList.add("hidden")
    this._setStatus("")
    this._retryBarcode = null
  }
}
