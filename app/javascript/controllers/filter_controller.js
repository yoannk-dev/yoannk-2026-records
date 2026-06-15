import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.#syncActiveChip()
  }

  #syncActiveChip() {
    const currentGenre = new URLSearchParams(window.location.search).get("genre") || ""
    this.element.querySelectorAll(".chip").forEach((chip) => {
      const href = chip.getAttribute("href") || ""
      const chipGenre = new URLSearchParams(new URL(href, window.location.href).search).get("genre") || ""
      const isActive = chipGenre === currentGenre
      chip.classList.toggle("chip--active", isActive)
      chip.setAttribute("aria-current", isActive ? "page" : "false")
    })
  }
}
