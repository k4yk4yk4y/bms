import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "project", "currencies" ]
  static values = { currenciesByProject: Object }

  connect() {
    this.updateCurrencies()
  }

  updateCurrencies() {
    const projectId = this.projectTarget.value
    const currencyList = this.currenciesByProjectValue[projectId] || []

    this.currenciesTarget.innerHTML = ""

    if (!currencyList.length) {
      const empty = document.createElement("div")
      empty.className = "text-muted"
      empty.textContent = "Select a project to see currencies."
      this.currenciesTarget.appendChild(empty)
      return
    }

    currencyList.forEach((currency) => {
      const wrapper = document.createElement("div")
      wrapper.className = "form-check"
      const input = document.createElement("input")
      input.className = "form-check-input"
      input.type = "checkbox"
      input.name = "smm_preset[currencies][]"
      input.value = currency
      input.id = `preset_currency_${projectId}_${currency}`
      input.checked = true

      const label = document.createElement("label")
      label.className = "form-check-label"
      label.setAttribute("for", input.id)
      label.textContent = currency

      wrapper.appendChild(input)
      wrapper.appendChild(label)
      this.currenciesTarget.appendChild(wrapper)
    })
  }
}
