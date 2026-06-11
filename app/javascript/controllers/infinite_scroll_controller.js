import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this._observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) this._loadMore()
    }, { rootMargin: "200px" })
    this._observer.observe(this.element)
  }

  disconnect() {
    this._observer?.disconnect()
  }

  async _loadMore() {
    this._observer.disconnect()

    const response = await fetch(this.urlValue, {
      headers: { Accept: "text/html", "X-Requested-With": "XMLHttpRequest" }
    })
    if (!response.ok) return

    const html = await response.text()
    const doc = new DOMParser().parseFromString(html, "text/html")
    const grid = document.getElementById("records-grid")

    doc.querySelectorAll(".cell").forEach((cell) => {
      grid.appendChild(document.adoptNode(cell))
    })

    const nextSentinel = doc.querySelector("[data-controller='infinite-scroll']")
    if (nextSentinel) {
      this.element.replaceWith(document.adoptNode(nextSentinel))
    } else {
      this.element.remove()
    }
  }
}
