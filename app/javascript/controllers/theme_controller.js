import { Controller } from "@hotwired/stimulus"

const LS_KEY = "vinyle.theme"

export default class extends Controller {
  initialize() {
    const saved = localStorage.getItem(LS_KEY)
    if (saved) document.documentElement.setAttribute("data-theme", saved)
  }

  toggle() {
    const current = document.documentElement.getAttribute("data-theme") || "light"
    const next = current === "dark" ? "light" : "dark"
    document.documentElement.setAttribute("data-theme", next)
    localStorage.setItem(LS_KEY, next)
    // Update ARIA state if the controller element is (or contains) the toggle button
    const btn = this.element.matches("button") ? this.element : this.element.querySelector("button")
    btn?.setAttribute("aria-pressed", String(next === "dark"))
  }
}
