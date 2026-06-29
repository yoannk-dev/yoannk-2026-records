import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  #onOutsideClick = (e) => {
    if (!this.element.contains(e.target)) this.close()
  }

  toggle() {
    const isOpen = this.element.classList.toggle("sort--open")
    this.element.querySelector("[aria-expanded]")?.setAttribute("aria-expanded", isOpen)
    if (isOpen) {
      document.addEventListener("click", this.#onOutsideClick)
    } else {
      document.removeEventListener("click", this.#onOutsideClick)
    }
  }

  close() {
    this.element.classList.remove("sort--open")
    this.element.querySelector("[aria-expanded]")?.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.#onOutsideClick)
  }

  select(e) {
    const params = new URLSearchParams(window.location.search)
    params.set("sort", e.currentTarget.dataset.sortValue)
    params.delete("page")
    this.close()
    Turbo.visit(`/?${params}`, { action: "replace" })
  }

  disconnect() {
    document.removeEventListener("click", this.#onOutsideClick)
  }
}
