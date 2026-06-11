import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "scrim"]

  connect() {
    this._onKeyDown = (e) => { if (e.key === "Escape") this.close() }
    document.addEventListener("keydown", this._onKeyDown)

    this._onPopState = () => {
      if (!window.location.pathname.match(/\/records\/\d+/)) this._hide()
    }
    window.addEventListener("popstate", this._onPopState)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeyDown)
    window.removeEventListener("popstate", this._onPopState)
  }

  open(event) {
    this._collectionSearch = window.location.search
    const url = event.currentTarget.getAttribute("href")
    history.pushState({}, "", url)
    this._show()
  }

  close() {
    this._hide()
    const base = window.location.pathname.replace(/\/records\/\d+.*/, "/")
    history.pushState({}, "", base + (this._collectionSearch || ""))
    const frame = document.getElementById("panel_content")
    if (frame) frame.innerHTML = ""
  }

  _show() {
    this.panelTarget.classList.add("panel-open")
    this.scrimTarget.classList.add("scrim-open")
  }

  _hide() {
    this.panelTarget.classList.remove("panel-open")
    this.scrimTarget.classList.remove("scrim-open")
  }
}
