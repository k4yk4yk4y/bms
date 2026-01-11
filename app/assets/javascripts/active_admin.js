//= require active_admin/base

(() => {
  const parseCurrencies = (value) => {
    if (!value) return []
    return value
      .split(/[;,]/)
      .map((code) => code.trim().toUpperCase())
      .filter((code) => code.length > 0)
  }

  const initProjectCurrencies = () => {
    const hiddenInput = document.getElementById("project_currencies")
    const entryInput = document.getElementById("project_currencies_entry")
    const tagsContainer = document.getElementById("project_currencies_tags")
    if (!hiddenInput || !entryInput || !tagsContainer) return

    let currencies = Array.from(new Set(parseCurrencies(hiddenInput.value)))

    const syncHidden = () => {
      hiddenInput.value = currencies.join(";")
    }

    const renderTags = () => {
      tagsContainer.innerHTML = ""
      currencies.forEach((code) => {
        const tag = document.createElement("span")
        tag.className = "project-currency-tag"
        tag.textContent = code

        const remove = document.createElement("button")
        remove.type = "button"
        remove.className = "project-currency-remove"
        remove.textContent = "x"
        remove.addEventListener("click", () => {
          currencies = currencies.filter((currency) => currency !== code)
          syncHidden()
          renderTags()
        })

        tag.appendChild(remove)
        tagsContainer.appendChild(tag)
      })
    }

    const addFromEntry = () => {
      const incoming = parseCurrencies(entryInput.value)
      if (incoming.length === 0) return
      currencies = Array.from(new Set(currencies.concat(incoming)))
      entryInput.value = ""
      syncHidden()
      renderTags()
    }

    entryInput.addEventListener("keydown", (event) => {
      if (event.key === ";" || event.key === "Enter") {
        event.preventDefault()
        addFromEntry()
      }
    })

    entryInput.addEventListener("blur", () => {
      addFromEntry()
    })

    syncHidden()
    renderTags()
  }

  const initBonusCurrenciesSelectAll = () => {
    const button = document.getElementById("select-all-currencies-btn")
    const checkboxes = Array.from(document.querySelectorAll("input.currency-checkbox"))
    if (checkboxes.length > 0 && document.querySelectorAll("input.currency-checkbox:checked").length === 0) {
      checkboxes.forEach((checkbox) => {
        checkbox.checked = true
      })
    }

    if (!button) return
    if (button.dataset.selectAllInitialized === "true") return
    button.dataset.selectAllInitialized = "true"

    button.addEventListener("click", () => {
      checkboxes.forEach((checkbox) => {
        checkbox.checked = true
      })
      button.dispatchEvent(new Event("change", { bubbles: true }))
    })
  }

  const initActiveAdmin = () => {
    initProjectCurrencies()
    initBonusCurrenciesSelectAll()
  }

  document.addEventListener("DOMContentLoaded", initActiveAdmin)
  document.addEventListener("turbo:load", initActiveAdmin)
  document.addEventListener("turbolinks:load", initActiveAdmin)
})()
