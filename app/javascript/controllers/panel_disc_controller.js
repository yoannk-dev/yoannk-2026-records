import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._timer = setTimeout(() => this.element.classList.add("panel-disc-out"), 50)
  }

  disconnect() {
    clearTimeout(this._timer)
    this.element.classList.remove("panel-disc-out")
  }
}
