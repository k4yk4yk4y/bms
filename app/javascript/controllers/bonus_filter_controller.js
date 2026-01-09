import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "select" ]

  connect() {
    this.options = Array.from(this.selectTarget.options).map((option) => ({
      value: option.value,
      label: option.text,
      selected: option.selected
    }))
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    this.selectTarget.innerHTML = ""

    this.options
      .filter((option) => option.label.toLowerCase().includes(query))
      .forEach((option) => {
        const opt = document.createElement("option")
        opt.value = option.value
        opt.textContent = option.label
        opt.selected = option.selected
        this.selectTarget.appendChild(opt)
      })
  }
}
