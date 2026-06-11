import { Controller } from "@hotwired/stimulus"

const LS_KEY = "vinyle.theme"

export default class extends Controller {
  connect() {
    const saved = localStorage.getItem(LS_KEY)
    if (saved) document.documentElement.setAttribute("data-theme", saved)
  }

  toggle() {
    const current = document.documentElement.getAttribute("data-theme") || "light"
    const next = current === "dark" ? "light" : "dark"
    document.documentElement.setAttribute("data-theme", next)
    localStorage.setItem(LS_KEY, next)
  }
}
