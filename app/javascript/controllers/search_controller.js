import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  #timer = null

  connect() {
    document.addEventListener("keydown", this.#onKeydown)

    const pos = sessionStorage.getItem("search_caret")
    if (pos !== null) {
      sessionStorage.removeItem("search_caret")
      this.inputTarget.focus()
      const i = parseInt(pos, 10)
      this.inputTarget.setSelectionRange(i, i)
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.#onKeydown)
    clearTimeout(this.#timer)
  }

  search() {
    clearTimeout(this.#timer)
    this.#timer = setTimeout(() => this.#navigate(), 300)
  }

  clear() {
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.#navigate()
  }

  #navigate() {
    sessionStorage.setItem("search_caret", this.inputTarget.selectionStart)

    const params = new URLSearchParams(window.location.search)
    const q = this.inputTarget.value.trim()
    if (q) {
      params.set("q", q)
    } else {
      params.delete("q")
    }
    params.delete("page")
    Turbo.visit(`/?${params}`, { action: "replace" })
  }

  #onKeydown = (e) => {
    if (
      e.key === "/" &&
      document.activeElement !== this.inputTarget &&
      !["INPUT", "TEXTAREA"].includes(document.activeElement.tagName)
    ) {
      e.preventDefault()
      this.inputTarget.focus()
      this.inputTarget.select()
    }
  }
}
