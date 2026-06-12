import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "video", "status", "manualForm", "manualInput", "retryBtn"]
  static values = { lookupUrl: String, tracklistUrl: String }

  connect() {
    this._stream = null
    this._scanning = false
    this._detector = null
    this._retryBarcode = null
    this._lastCandidate = null
    this._candidateCount = 0
  }

  disconnect() {
    this._stopCamera()
  }

  async open() {
    this._showOverlay()

    if (!("BarcodeDetector" in window)) {
      try {
        const { BarcodeDetector } = await import("barcode-detector")
        window.BarcodeDetector = BarcodeDetector
      } catch {
        this._showManual("Your browser doesn't support camera scanning. Enter the barcode number below:")
        return
      }
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

    // Wait for the video to have actual pixel data before scanning
    if (this.videoTarget.readyState >= 2) {
      try {
        const results = await this._detector.detect(this.videoTarget)
        if (results.length > 0) {
          const value = results[0].rawValue
          if (value === this._lastCandidate) {
            this._candidateCount++
          } else {
            this._lastCandidate = value
            this._candidateCount = 1
          }
          // Require 3 consistent reads before trusting the result
          if (this._candidateCount >= 3) {
            this._scanning = false
            this._lastCandidate = null
            this._candidateCount = 0
            this._stopCamera()
            await this._lookup(value)
            return
          }
        } else {
          this._lastCandidate = null
          this._candidateCount = 0
        }
      } catch { /* frame not ready yet */ }
    }

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
        if (data.discogs_id && this.tracklistUrlValue) {
          this._setStatus("Fetching tracklist…")
          try {
            const tlResp = await fetch(
              `${this.tracklistUrlValue}?discogs_id=${encodeURIComponent(data.discogs_id)}`,
              { headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" } }
            )
            if (tlResp.ok) {
              const tlData = await tlResp.json()
              data.tracklist = JSON.stringify(tlData.tracklist)
            }
          } catch { /* tracklist is optional */ }
        }
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
