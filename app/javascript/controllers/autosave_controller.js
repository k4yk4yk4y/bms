import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "status" ]
  static values = {
    url: String,
    method: String
  }

  connect() {
    this.handleInput = this.handleInput.bind(this)
    this.handleChange = this.handleChange.bind(this)
    this.handleSubmit = this.handleSubmit.bind(this)
    this.element.addEventListener("input", this.handleInput)
    this.element.addEventListener("change", this.handleChange)
    this.element.addEventListener("submit", this.handleSubmit)
  }

  disconnect() {
    this.element.removeEventListener("input", this.handleInput)
    this.element.removeEventListener("change", this.handleChange)
    this.element.removeEventListener("submit", this.handleSubmit)
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  handleInput() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }

    this.setStatus("Saving...")
    this.timeoutId = setTimeout(() => this.submit(), 800)
  }

  handleChange() {
    this.handleInput()
  }

  handleSubmit() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
    this.setStatus("Saving...")
  }

  submit() {
    const formData = new FormData(this.element)
    const csrfToken = document.querySelector("meta[name=\"csrf-token\"]")?.content
    let method = (this.methodValue || "post").toUpperCase()

    if (method !== "POST") {
      formData.set("_method", method.toLowerCase())
      method = "POST"
    }

    fetch(this.urlValue, {
      method,
      headers: {
        Accept: "application/json",
        "X-Requested-With": "XMLHttpRequest",
        ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {})
      },
      body: formData
    })
      .then(async (response) => {
        const payload = await response.json().catch(() => ({}))
        if (!response.ok) {
          throw new Error(payload.errors ? payload.errors.join(", ") : "Autosave failed")
        }

        if (payload.update_url && payload.edit_url && this.methodValue.toLowerCase() === "post") {
          this.methodValue = "patch"
          this.urlValue = payload.update_url
          this.element.action = payload.update_url
          this.ensureMethodOverride()
          window.history.replaceState({}, "", payload.edit_url)
        }

        this.setStatus("Saved")
      })
      .catch((error) => {
        this.setStatus(error.message || "Autosave failed")
      })
  }

  ensureMethodOverride() {
    let methodField = this.element.querySelector("input[name=\"_method\"]")
    if (!methodField) {
      methodField = document.createElement("input")
      methodField.type = "hidden"
      methodField.name = "_method"
      this.element.appendChild(methodField)
    }
    methodField.value = "patch"
  }

  setStatus(message) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
  }
}
