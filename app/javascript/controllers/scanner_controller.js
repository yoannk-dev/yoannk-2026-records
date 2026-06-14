import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "video", "status", "manualForm", "manualInput", "retryBtn", "barcodeTab", "catnoTab"]
  static values = { lookupUrl: String, tracklistUrl: String }

  connect() {
    this._stream = null
    this._scanning = false
    this._detector = null
    this._retryValue = null
    this._lastCandidate = null
    this._candidateCount = 0
    this._mode = "barcode"
  }

  disconnect() {
    this._stopCamera()
  }

  async open() {
    this._mode = "barcode"
    this._setModeActive("barcode")
    this._showOverlay()

    if (!("BarcodeDetector" in window)) {
      try {
        const { BarcodeDetector } = await import("barcode-detector")
        window.BarcodeDetector = BarcodeDetector
      } catch {
        this._showManual("Votre navigateur ne supporte pas le scan. Entrez le code-barres ci-dessous :")
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
      this._setStatus("Scan en cours… pointez la caméra vers le code-barres")
      this._scanning = true
      this._scanLoop()
    } catch {
      this._showManual("Accès caméra refusé. Entrez le code-barres manuellement :")
    }
  }

  close() {
    this._stopCamera()
    this._hideOverlay()
  }

  async switchMode(event) {
    const mode = event.currentTarget.dataset.mode
    if (mode === this._mode) return
    this._mode = mode
    this._setModeActive(mode)
    this._stopCamera()
    this.retryBtnTarget.classList.add("hidden")
    this._retryValue = null

    if (mode === "catno") {
      this._showManual("Entrez le numéro de catalogue inscrit sur l'étiquette :", "", "text", "ex : BLP 1568, ECM 1064")
    } else {
      this._showManual("Entrez le code-barres manuellement :", "", "numeric", "ex : 0602435688435")
    }
  }

  async submitManual(event) {
    event.preventDefault()
    const value = this.manualInputTarget.value.trim()
    if (value) await this._lookup(value)
  }

  async retry() {
    this.retryBtnTarget.classList.add("hidden")
    if (this._retryValue) await this._lookup(this._retryValue)
  }

  async _scanLoop() {
    if (!this._scanning) return

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

  async _lookup(value) {
    this._setStatus("Recherche sur Discogs…")
    this.manualFormTarget.classList.add("hidden")

    const param = this._mode === "catno" ? "catno" : "barcode"

    try {
      const resp = await fetch(
        `${this.lookupUrlValue}?${param}=${encodeURIComponent(value)}`,
        { headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" } }
      )
      const data = await resp.json()

      if (resp.ok) {
        if (data.discogs_id && this.tracklistUrlValue) {
          this._setStatus("Récupération de la tracklist…")
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
        if (this._mode === "barcode") {
          this._showManual(
            'Aucun résultat pour ce code-barres. Essayez avec le numéro de catalogue (sur l\'étiquette) via "Catalog #" ci-dessus.',
            value,
            "numeric",
            "ex : 0602435688435"
          )
        } else {
          this._showManual(`Aucun résultat pour "${value}". Vérifiez le numéro de catalogue.`, value, "text", "ex : BLP 1568")
        }
      } else {
        this._setStatus("Erreur lors de la recherche Discogs.")
        this._retryValue = value
        this.retryBtnTarget.classList.remove("hidden")
      }
    } catch {
      this._setStatus("Erreur réseau. Vérifiez votre connexion.")
      this._retryValue = value
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

  _showManual(message, value = "", inputMode = "numeric", placeholder = "ex : 0602435688435") {
    this._setStatus(message)
    this.manualInputTarget.value = value
    this.manualInputTarget.inputMode = inputMode
    this.manualInputTarget.placeholder = placeholder
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

  _setModeActive(mode) {
    this.barcodeTabTarget.classList.toggle("active", mode === "barcode")
    this.catnoTabTarget.classList.toggle("active", mode === "catno")
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
    this._retryValue = null
  }
}
