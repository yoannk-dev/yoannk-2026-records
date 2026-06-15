import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  #observer = null
  #abortController = null

  connect() {
    this.#observer = new IntersectionObserver(
      (entries) => { if (entries[0].isIntersecting) this.#loadMore() },
      { rootMargin: "200px" }
    )
    this.#observer.observe(this.element)
  }

  disconnect() {
    this.#observer?.disconnect()
    this.#abortController?.abort()
  }

  async #loadMore() {
    this.#observer.disconnect()
    this.#abortController = new AbortController()

    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "text/html", "X-Requested-With": "XMLHttpRequest" },
        signal: this.#abortController.signal
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const html = await response.text()
      const doc = new DOMParser().parseFromString(html, "text/html")
      const grid = document.getElementById("records-grid")

      doc.querySelectorAll(".cell").forEach((cell) => grid.appendChild(document.adoptNode(cell)))

      const nextSentinel = doc.querySelector("[data-controller='infinite-scroll']")
      if (nextSentinel) {
        this.element.replaceWith(document.adoptNode(nextSentinel))
      } else {
        this.element.remove()
      }
    } catch (error) {
      if (error.name === "AbortError") return
      // Reconnect observer on error to allow retry on next scroll
      this.#observer.observe(this.element)
    }
  }
}
