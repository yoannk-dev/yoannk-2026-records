import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "scrim"]

  #collectionSearch = ""
  #previousFocus = null

  // Arrow fields capture `this` without .bind() and maintain stable references for removeEventListener
  #onKeyDown = (event) => { if (event.key === "Escape") this.close() }
  #onPopState = () => { if (!window.location.pathname.match(/\/records\/\d+/)) this.#hide() }
  #onScannerOpen = () => {
    this.#collectionSearch = window.location.search
    this.#show()
  }

  connect() {
    window.addEventListener("keydown", this.#onKeyDown)
    window.addEventListener("popstate", this.#onPopState)
    document.addEventListener("scanner:open-panel", this.#onScannerOpen)
  }

  disconnect() {
    window.removeEventListener("keydown", this.#onKeyDown)
    window.removeEventListener("popstate", this.#onPopState)
    document.removeEventListener("scanner:open-panel", this.#onScannerOpen)
  }

  open(event) {
    this.#previousFocus = document.activeElement
    this.#collectionSearch = window.location.search
    const url = event.currentTarget.getAttribute("href")
    history.pushState({}, "", url)
    this.#show()
  }

  close() {
    this.#hide()
    const base = window.location.pathname.replace(/\/records\/\d+.*/, "/")
    history.pushState({}, "", base + (this.#collectionSearch || ""))
    const frame = document.getElementById("panel_content")
    if (frame) frame.innerHTML = ""
    this.#previousFocus?.focus()
  }

  #show() {
    this.panelTarget.classList.add("panel--open")
    this.scrimTarget.classList.add("scrim--open")
    this.panelTarget.removeAttribute("aria-hidden")
  }

  #hide() {
    this.panelTarget.classList.remove("panel--open")
    this.scrimTarget.classList.remove("scrim--open")
    this.panelTarget.setAttribute("aria-hidden", "true")
  }
}
