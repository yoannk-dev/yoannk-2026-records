import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { genre: String }

  connect() {
    const params = new URLSearchParams(window.location.search)
    const current = params.get("genre") || ""
    this.element.querySelectorAll(".chip").forEach((chip) => {
      const href = chip.getAttribute("href") || ""
      const chipGenre = new URLSearchParams(new URL(href, window.location.href).search).get("genre") || ""
      chip.classList.toggle("chip--active", chipGenre === current)
    })
  }
}
