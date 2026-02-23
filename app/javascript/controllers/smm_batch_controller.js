import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "quantity", "tbody" ]

  generate() {
    const qty = parseInt(this.quantityTarget.value, 10)
    if (!qty || qty < 1) {
      this.tbodyTarget.innerHTML = ""
      return
    }

    this.tbodyTarget.innerHTML = ""

    for (let index = 0; index < qty; index += 1) {
      const row = document.createElement("tr")
      row.innerHTML = `
        <td class="text-muted">${index + 1}</td>
        <td><input type="text" name="rows[][code]" class="form-control form-control-sm" placeholder="Enter Code"></td>
        <td><input type="text" name="rows[][game]" class="form-control form-control-sm" placeholder="Select Game"></td>
        <td><input type="text" name="rows[][bet_value]" class="form-control form-control-sm" placeholder="0.1 USD"></td>
        <td><input type="number" name="rows[][fs_count]" class="form-control form-control-sm" min="0" placeholder="25"></td>
      `
      this.tbodyTarget.appendChild(row)
    }
  }
}
