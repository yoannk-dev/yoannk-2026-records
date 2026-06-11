import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { loggedIn: Boolean }

  connect() {
    this._onOutsideClick = (e) => {
      if (!this.element.contains(e.target)) this._close()
    }
  }

  open() {
    if (this.loggedInValue) return // sprint 2: open camera flow

    if (this.element.querySelector(".add-prompt")) return

    const prompt = document.createElement("div")
    prompt.className = "add-prompt"
    prompt.innerHTML = "Adding records is reserved for the owner."
    this.element.appendChild(prompt)

    setTimeout(() => document.addEventListener("click", this._onOutsideClick), 0)
  }

  _close() {
    this.element.querySelector(".add-prompt")?.remove()
    document.removeEventListener("click", this._onOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this._onOutsideClick)
  }
}
