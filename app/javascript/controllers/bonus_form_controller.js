// app/javascript/controllers/bonus_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "dslTag", "project"]

  connect() {
    console.log("Bonus Form Controller connected!")
    this.fetchTemplateData() // Fetch initial data if form is pre-filled
  }

  fetchTemplateData() {
    const name = this.nameTarget.value
    const dslTagId = this.dslTagTarget.value
    const projectId = this.projectTarget.value

    if (name && dslTagId && projectId) {
      console.log(`Fetching template for: Name=${name}, DslTagId=${dslTagId}, ProjectId=${projectId}`)
      fetch(`/bonus_templates/find?name=${name}&dsl_tag_name=${this.dslTagTarget.options[this.dslTagTarget.selectedIndex].text}&project_name=${this.projectTarget.options[this.projectTarget.selectedIndex].text}`)
        .then(response => response.json())
        .then(data => {
          console.log("Template data received:", data)
          if (data.template) {
            // Pre-fill form fields with data
            // Assuming template returns minimum_deposit and wager
            const form = this.element // The form element itself
            const minimumDepositInput = form.querySelector('#bonus_minimum_deposit') // Assuming ID
            const wagerInput = form.querySelector('#bonus_wager') // Assuming ID

            if (minimumDepositInput) {
              minimumDepositInput.value = data.template.minimum_deposit
            }
            if (wagerInput) {
              wagerInput.value = data.template.wager
            }
          }
        })
        .catch(error => console.error("Error fetching template:", error))
    }
  }

  // Actions to trigger fetchTemplateData on change
  nameChanged() {
    this.fetchTemplateData()
  }

  dslTagChanged() {
    this.fetchTemplateData()
  }

  projectChanged() {
    this.fetchTemplateData()
  }
}
