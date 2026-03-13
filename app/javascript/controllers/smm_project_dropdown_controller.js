import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    if (this.boundClickOutside) {
      document.removeEventListener("click", this.boundClickOutside)
      this.boundClickOutside = null
    }

    this.hide()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.isOpen()) {
      this.hide()
    } else {
      this.show()
    }
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.hide()
    }
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  isOpen() {
    return this.menuTarget.classList.contains("show")
  }

  show() {
    this.element.classList.add("show")
    this.buttonTarget.classList.add("show")
    this.menuTarget.classList.add("show")
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  hide() {
    if (!this.hasButtonTarget || !this.hasMenuTarget) return

    this.element.classList.remove("show")
    this.buttonTarget.classList.remove("show")
    this.menuTarget.classList.remove("show")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
