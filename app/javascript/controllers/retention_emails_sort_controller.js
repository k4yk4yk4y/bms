import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "item" ]
  static values = {
    url: String,
    enabled: Boolean
  }

  connect() {
    if (!this.enabledValue) return

    this.handleDragStart = this.handleDragStart.bind(this)
    this.handleDragOver = this.handleDragOver.bind(this)
    this.handleDragEnd = this.handleDragEnd.bind(this)

    this.itemTargets.forEach((item) => {
      item.addEventListener("dragstart", this.handleDragStart)
      item.addEventListener("dragover", this.handleDragOver)
      item.addEventListener("dragend", this.handleDragEnd)
    })
  }

  disconnect() {
    if (!this.enabledValue) return

    this.itemTargets.forEach((item) => {
      item.removeEventListener("dragstart", this.handleDragStart)
      item.removeEventListener("dragover", this.handleDragOver)
      item.removeEventListener("dragend", this.handleDragEnd)
    })
  }

  handleDragStart(event) {
    this.draggedItem = event.currentTarget
    this.draggedItem.classList.add("table-active")
    event.dataTransfer.effectAllowed = "move"
  }

  handleDragOver(event) {
    event.preventDefault()
    const target = event.currentTarget
    if (!this.draggedItem || target === this.draggedItem) return

    const rect = target.getBoundingClientRect()
    const shouldInsertBefore = event.clientY < rect.top + rect.height / 2

    if (shouldInsertBefore) {
      target.parentNode.insertBefore(this.draggedItem, target)
    } else {
      target.parentNode.insertBefore(this.draggedItem, target.nextSibling)
    }
  }

  handleDragEnd() {
    if (!this.draggedItem) return

    this.draggedItem.classList.remove("table-active")
    this.draggedItem = null
    this.persistOrder()
  }

  persistOrder() {
    const order = this.itemTargets.map((item) => item.dataset.id)
    const token = document.querySelector("meta[name=\"csrf-token\"]")?.content

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-Requested-With": "XMLHttpRequest",
        "X-CSRF-Token": token
      },
      body: JSON.stringify({ order: order })
    })
  }
}
