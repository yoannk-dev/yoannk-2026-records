import { Controller } from "@hotwired/stimulus"
import { fetchJSON } from "helpers/fetch_json"

const FOCUSABLE_SELECTOR = 'button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])'

export default class extends Controller {
  static targets = ["overlay", "video", "status", "manualForm", "manualInput", "retryBtn", "barcodeTab", "catnoTab", "manualBtn"]
  static values = { lookupUrl: String, tracklistUrl: String }

  #stream = null
  #scanning = false
  #detector = null
  #retryValue = null
  #lastCandidate = null
  #candidateCount = 0
  #mode = "barcode"
  #abortController = null
  #previousFocus = null

  // Arrow field for stable reference across add/removeEventListener
  #focusTrapHandler = (event) => {
    if (event.key === "Escape") { this.close(); return }
    if (event.key !== "Tab") return
    const focusable = [...this.overlayTarget.querySelectorAll(FOCUSABLE_SELECTOR)]
    if (focusable.length === 0) return
    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault(); last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault(); first.focus()
    }
  }

  disconnect() {
    this.#stopCamera()
    this.#abortController?.abort()
    this.overlayTarget.removeEventListener("keydown", this.#focusTrapHandler)
  }

  async open() {
    this.#previousFocus = document.activeElement
    this.#mode = "barcode"
    this.#setModeActive("barcode")
    this.manualFormTarget.classList.add("u-hidden")
    this.manualBtnTarget.classList.add("u-hidden")
    this.retryBtnTarget.classList.add("u-hidden")
    this.#setStatus("")
    this.#showOverlay()
    await this.#startCamera()
  }

  close() {
    this.#stopCamera()
    this.#hideOverlay()
    this.#previousFocus?.focus()
  }

  async switchMode(event) {
    const mode = event.currentTarget.dataset.mode
    if (mode === this.#mode) return
    this.#mode = mode
    this.#setModeActive(mode)
    this.#stopCamera()
    this.retryBtnTarget.classList.add("u-hidden")
    this.#retryValue = null
    this.manualFormTarget.classList.add("u-hidden")
    this.manualBtnTarget.classList.add("u-hidden")
    this.#setStatus("")
    await this.#startCamera()
  }

  showManual() {
    this.#stopCamera()
    const isBarcode = this.#mode === "barcode"
    this.manualInputTarget.inputMode = isBarcode ? "numeric" : "text"
    this.manualInputTarget.placeholder = isBarcode ? "ex : 0602435688435" : "ex : BLP 1568, ECM 1064"
    this.manualInputTarget.value = ""
    this.#setStatus(isBarcode
      ? "Entrez le code-barres manuellement :"
      : "Entrez le numéro de catalogue inscrit sur l'étiquette :")
    this.manualFormTarget.classList.remove("u-hidden")
    this.manualBtnTarget.classList.add("u-hidden")
    this.manualInputTarget.focus()
  }

  async submitManual(event) {
    event.preventDefault()
    const value = this.manualInputTarget.value.trim()
    if (value) await this.#lookup(value)
  }

  async retry() {
    this.retryBtnTarget.classList.add("u-hidden")
    if (this.#retryValue) await this.#lookup(this.#retryValue)
  }

  async #startCamera() {
    if (this.#mode === "barcode" && !("BarcodeDetector" in window)) {
      try {
        const { BarcodeDetector } = await import("barcode-detector")
        window.BarcodeDetector = BarcodeDetector
      } catch {
        this.#showManualFallback("Votre navigateur ne supporte pas le scan. Entrez le code-barres ci-dessous :")
        return
      }
    }

    try {
      this.#stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "environment" } })
      this.videoTarget.srcObject = this.#stream
      await this.videoTarget.play()

      if (this.#mode === "barcode") {
        this.#detector = new window.BarcodeDetector({ formats: ["ean_13", "upc_a", "upc_e", "ean_8"] })
        this.#setStatus("Scan en cours… pointez la caméra vers le code-barres")
        this.#scanning = true
        this.#scanLoop()
      } else {
        this.#setStatus("Pointez la caméra vers l'étiquette du disque")
      }

      this.manualBtnTarget.classList.remove("u-hidden")
    } catch {
      const isBarcode = this.#mode === "barcode"
      this.#showManualFallback(
        isBarcode ? "Accès caméra refusé. Entrez le code-barres manuellement :" : "Accès caméra refusé. Entrez le numéro de catalogue :",
        "",
        isBarcode ? "numeric" : "text",
        isBarcode ? "ex : 0602435688435" : "ex : BLP 1568, ECM 1064"
      )
    }
  }

  async #scanLoop() {
    if (!this.#scanning) return

    if (this.videoTarget.readyState >= 2) {
      try {
        const results = await this.#detector.detect(this.videoTarget)
        if (results.length > 0) {
          const value = results[0].rawValue
          if (value === this.#lastCandidate) {
            this.#candidateCount++
          } else {
            this.#lastCandidate = value
            this.#candidateCount = 1
          }
          if (this.#candidateCount >= 3) {
            this.#scanning = false
            this.#lastCandidate = null
            this.#candidateCount = 0
            this.#stopCamera()
            await this.#lookup(value)
            return
          }
        } else {
          this.#lastCandidate = null
          this.#candidateCount = 0
        }
      } catch { /* frame not ready yet */ }
    }

    if (this.#scanning) requestAnimationFrame(() => this.#scanLoop())
  }

  async #lookup(value) {
    this.#abortController?.abort()
    this.#abortController = new AbortController()
    this.#setStatus("Recherche sur Discogs…")
    this.manualFormTarget.classList.add("u-hidden")
    this.manualBtnTarget.classList.add("u-hidden")

    const param = this.#mode === "catno" ? "catno" : "barcode"

    try {
      const data = await fetchJSON(
        `${this.lookupUrlValue}?${param}=${encodeURIComponent(value)}`,
        { signal: this.#abortController.signal }
      )

      if (data.discogs_id && this.tracklistUrlValue) {
        this.#setStatus("Récupération de la tracklist…")
        try {
          const tlData = await fetchJSON(
            `${this.tracklistUrlValue}?discogs_id=${encodeURIComponent(data.discogs_id)}`,
            { signal: this.#abortController.signal }
          )
          data.tracklist = JSON.stringify(tlData.tracklist)
        } catch { /* tracklist is optional */ }
      }

      this.#openPanel(data)
      this.#hideOverlay()
    } catch (error) {
      if (error.name === "AbortError") return

      if (error.status === 404) {
        if (this.#mode === "barcode") {
          this.#showManualFallback(
            'Aucun résultat pour ce code-barres. Essayez avec le numéro de catalogue (sur l\'étiquette) via "Catalog #" ci-dessus.',
            value, "numeric", "ex : 0602435688435"
          )
        } else {
          this.#showManualFallback(`Aucun résultat pour "${value}". Vérifiez le numéro de catalogue.`, value, "text", "ex : BLP 1568")
        }
      } else {
        this.#setStatus(
          error.name === "TypeError"
            ? "Erreur réseau. Vérifiez votre connexion."
            : "Erreur lors de la recherche Discogs."
        )
        this.#retryValue = value
        this.retryBtnTarget.classList.remove("u-hidden")
      }
    }
  }

  #openPanel(data) {
    const params = new URLSearchParams()
    for (const [k, v] of Object.entries(data)) {
      if (v != null && v !== "") params.set(k, String(v))
    }
    document.getElementById("panel_content").src = `/records/new?${params}`
    document.dispatchEvent(new CustomEvent("scanner:open-panel"))
  }

  #showManualFallback(message, value = "", inputMode = "numeric", placeholder = "ex : 0602435688435") {
    this.#setStatus(message)
    this.manualInputTarget.value = value
    this.manualInputTarget.inputMode = inputMode
    this.manualInputTarget.placeholder = placeholder
    this.manualFormTarget.classList.remove("u-hidden")
    this.manualBtnTarget.classList.add("u-hidden")
    this.manualInputTarget.focus()
  }

  #stopCamera() {
    this.#scanning = false
    this.#stream?.getTracks().forEach(t => t.stop())
    this.#stream = null
    if (this.hasVideoTarget) this.videoTarget.srcObject = null
  }

  #setStatus(text) {
    this.statusTarget.textContent = text
  }

  #setModeActive(mode) {
    this.barcodeTabTarget.classList.toggle("is-active", mode === "barcode")
    this.catnoTabTarget.classList.toggle("is-active", mode === "catno")
    this.barcodeTabTarget.setAttribute("aria-pressed", String(mode === "barcode"))
    this.catnoTabTarget.setAttribute("aria-pressed", String(mode === "catno"))
  }

  #showOverlay() {
    this.overlayTarget.classList.add("scanner--open")
    this.overlayTarget.removeAttribute("aria-hidden")
    document.body.classList.add("scanner-active")
    this.overlayTarget.addEventListener("keydown", this.#focusTrapHandler)
    this.overlayTarget.querySelector(FOCUSABLE_SELECTOR)?.focus()
  }

  #hideOverlay() {
    this.overlayTarget.classList.remove("scanner--open")
    this.overlayTarget.setAttribute("aria-hidden", "true")
    document.body.classList.remove("scanner-active")
    this.overlayTarget.removeEventListener("keydown", this.#focusTrapHandler)
    this.manualFormTarget.classList.add("u-hidden")
    this.manualBtnTarget.classList.add("u-hidden")
    this.retryBtnTarget.classList.add("u-hidden")
    this.#setStatus("")
    this.#retryValue = null
  }
}
