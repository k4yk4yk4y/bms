import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "select" ]
  static values = {
    url: String
  }

  connect() {
    this.debounceId = null
    this.ensureSelectedCache()
  }

  search() {
    if (!this.hasUrlValue) return
    if (this.debounceId) {
      clearTimeout(this.debounceId)
    }

    this.debounceId = setTimeout(() => {
      this.fetchOptions(this.inputTarget.value.trim())
    }, 300)
  }

  fetchOptions(query) {
    const url = new URL(this.urlValue, window.location.origin)
    if (query.length > 0) {
      url.searchParams.set("q", query)
    }

    fetch(url.toString(), {
      headers: {
        Accept: "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
      .then((response) => response.json())
      .then((data) => {
        this.renderOptions(data)
      })
      .catch(() => {
        // Keep existing options on error.
      })
  }

  renderOptions(results) {
    this.ensureSelectedCache()
    const selectedIds = new Set(this.selectedOptions.map((option) => option.id.toString()))

    this.selectTarget.innerHTML = ""

    this.selectedOptions.forEach((option) => {
      this.selectTarget.appendChild(this.buildOption(option, true))
    })

    results.forEach((bonus) => {
      if (selectedIds.has(bonus.id.toString())) return
      this.selectTarget.appendChild(this.buildOption(bonus, false))
    })
  }

  buildOption(bonus, selected) {
    const option = document.createElement("option")
    option.value = bonus.id
    option.textContent = this.formatLabel(bonus)
    option.selected = selected
    return option
  }

  formatLabel(bonus) {
    if (bonus.label) {
      return bonus.label
    }
    const code = bonus.code ? ` (${bonus.code})` : ""
    return `${bonus.name}${code}`
  }

  ensureSelectedCache() {
    this.selectedOptions = Array.from(this.selectTarget.selectedOptions).map((option) => ({
      id: option.value,
      label: option.textContent
    }))
  }
}
