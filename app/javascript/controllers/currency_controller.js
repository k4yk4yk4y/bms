import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="currency"
export default class extends Controller {
  static targets = ["checkbox", "minimumDeposit", "project", "checkboxesContainer"]
  static values = { projectCurrencies: Object }
  
  connect() {
    this.hasInitializedProjectCurrencies = false
    this.boundHandleChange = this.handleChange.bind(this)
    this.boundHandleInput = this.handleInput.bind(this)
    this.element.addEventListener("change", this.boundHandleChange)
    this.element.addEventListener("input", this.boundHandleInput)
    this.setupMutationObserver()
    this.updateProjectCurrencies()
    this.selectAllIfNoneChecked()
  }

  disconnect() {
    this.element.removeEventListener("change", this.boundHandleChange)
    this.element.removeEventListener("input", this.boundHandleInput)
  }

  handleChange(event) {
    if (event.target.matches("input.currency-checkbox")) {
      this.updateAllCurrencyFields()
      return
    }

    if (this.hasProjectTarget && event.target === this.projectTarget) {
      this.updateProjectCurrencies()
    }
  }

  handleInput(event) {
    if (event.target.matches('input[name^="bonus[currency_minimum_deposits]"], input[name^="bonus_template[currency_minimum_deposits]"]')) {
      this.updateAllCurrencyFields()
    }
  }

  setupMutationObserver() {
    const targetNode = document.getElementById('type-specific-fields')
    if (!targetNode) return

    let updateTimeout = null
    const observer = new MutationObserver((mutations) => {
      let shouldUpdate = false
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          // Only update if new form elements are added, not input changes
          const hasFormElements = Array.from(mutation.addedNodes).some(node => 
            node.nodeType === Node.ELEMENT_NODE && 
            (node.classList?.contains('card') || node.querySelector?.('.card'))
          )
          if (hasFormElements) {
            shouldUpdate = true
          }
        }
      })
      if (shouldUpdate) {
        // Debounce updates to prevent rapid-fire updates
        if (updateTimeout) clearTimeout(updateTimeout)
        updateTimeout = setTimeout(() => this.updateAllCurrencyFields(), 300)
      }
    })

    observer.observe(targetNode, { childList: true, subtree: false })
  }

  updateProjectCurrencies() {
    if (!this.hasProjectTarget || !this.hasProjectCurrenciesValue) {
      return
    }

    const availableCurrencies = this.projectCurrenciesValue[this.projectTarget.value] || []
    window.currentProjectCurrencies = availableCurrencies
    window.currentProjectCryptoCurrencies = []

    this.rebuildCurrencyCheckboxes(availableCurrencies)
    this.updateAllCurrencyFields()
    this.selectAllIfNoneChecked()
    this.hasInitializedProjectCurrencies = true
  }

  rebuildCurrencyCheckboxes(availableCurrencies) {
    const container = this.hasCheckboxesContainerTarget
      ? this.checkboxesContainerTarget
      : this.element.querySelector(".currencies-checkboxes")

    if (!container) return

    const existingCheckboxes = Array.from(container.querySelectorAll("input.currency-checkbox"))
    const currentCurrencies = existingCheckboxes.map(checkbox => checkbox.value)
    if (currentCurrencies.length === availableCurrencies.length &&
        currentCurrencies.every((currency, index) => currency === availableCurrencies[index])) {
      return
    }

    const selected = this.getSelectedCurrencies()
    const selectedSet = new Set(selected)
    const shouldAutoSelect = !this.hasInitializedProjectCurrencies && selected.length === 0
    const fieldName = container.dataset.currencyName || "bonus[currencies][]"

    container.innerHTML = ""

    availableCurrencies.forEach((currency, index) => {
      const wrapper = document.createElement("div")
      wrapper.className = `form-check${index === availableCurrencies.length - 1 ? "" : " mb-1"}`

      const checkbox = document.createElement("input")
      checkbox.type = "checkbox"
      checkbox.name = fieldName
      checkbox.value = currency
      checkbox.className = "form-check-input currency-checkbox"
      checkbox.id = `currency_${currency}`
      checkbox.dataset.currency = currency
      checkbox.dataset.currencyTarget = "checkbox"
      checkbox.checked = shouldAutoSelect ? true : selectedSet.has(currency)

      const label = document.createElement("label")
      label.className = "form-check-label"
      label.setAttribute("for", checkbox.id)
      label.textContent = currency

      wrapper.appendChild(checkbox)
      wrapper.appendChild(label)
      container.appendChild(wrapper)
    })
  }

  // Method called when currency checkboxes change
  updateAllCurrencyFields() {
    
    // Get selected currencies
    const selectedCurrencies = this.getSelectedCurrencies()
    const minimumDepositCurrencies = this.getMinimumDepositCurrencies()
    
    // Update minimum deposits fields
    this.updateCurrencyMinimumDepositsFields()
    
    // Update all reward forms
    setTimeout(() => {
      this.updateBonusRewardCurrencyFields()
      this.updateFreespinRewardCurrencyFields()
      this.updateBonusBuyRewardCurrencyFields()
    }, 50)
  }

  // Button action to uncheck all currencies
  uncheckAll() {
    this.element.querySelectorAll("input.currency-checkbox").forEach(checkbox => {
      checkbox.checked = false
    })

    this.element.querySelectorAll('input[name^="bonus[currency_minimum_deposits]"], input[name^="bonus_template[currency_minimum_deposits]"]').forEach(input => {
      input.value = ""
    })
    
    this.updateAllCurrencyFields()
  }

  // Button action to check all currencies
  selectAll() {
    this.element.querySelectorAll("input.currency-checkbox").forEach(checkbox => {
      checkbox.checked = true
    })

    this.updateAllCurrencyFields()
  }

  selectAllIfNoneChecked() {
    const checkboxes = Array.from(this.element.querySelectorAll("input.currency-checkbox"))
    if (checkboxes.length === 0) return

    const hasChecked = checkboxes.some(checkbox => checkbox.checked)
    if (hasChecked) return

    checkboxes.forEach(checkbox => {
      checkbox.checked = true
    })

    this.updateAllCurrencyFields()
  }

  getSelectedCurrencies() {
    return Array.from(this.element.querySelectorAll("input.currency-checkbox:checked"))
      .map(checkbox => checkbox.value)
  }

  getMinimumDepositCurrencies() {
    // Check for both bonus and bonus_template forms
    const bonusInputs = document.querySelectorAll('input[name^="bonus[currency_minimum_deposits]"]')
    const templateInputs = document.querySelectorAll('input[name^="bonus_template[currency_minimum_deposits]"]')
    const allInputs = [...bonusInputs, ...templateInputs]
    
    return Array.from(allInputs)
      .map(input => {
        const match = input.name.match(/currency_minimum_deposits\[([^\]]+)\]/)
        return match ? match[1] : null
      })
      .filter(currency => currency !== null)
  }

  updateCurrencyMinimumDepositsFields() {
    // Try to call external function first (for compatibility)
    if (typeof updateCurrencyMinimumDepositsFields === 'function') {
      updateCurrencyMinimumDepositsFields()
      return
    }
    
    // If external function not found, use built-in implementation
    this.updateMinimumDepositsFieldsDirectly()
  }
  
  updateMinimumDepositsFieldsDirectly() {
    const container = document.getElementById('currency-minimum-deposits-container');
    if (!container) return;
    
    const selectedCurrencies = this.getSelectedCurrencies();
    const availableCurrencies = window.currentProjectCurrencies || [];
    const cryptoCurrencies = window.currentProjectCryptoCurrencies || [];
    
    // Show all available currencies when none are selected
    const displayCurrencies = selectedCurrencies.length > 0 ? selectedCurrencies : availableCurrencies;
    
    // Check if update is actually needed by comparing current displayed currencies
    const rowDiv = container.querySelector('.row');
    if (rowDiv) {
      const currentCurrencies = Array.from(rowDiv.querySelectorAll('input[type="number"]'))
        .map(input => {
          const match = input.name.match(/currency_minimum_deposits\[([^\]]+)\]/);
          return match ? match[1] : null;
        })
        .filter(currency => currency !== null);
      
      // If currencies are the same, don't rebuild (but always rebuild if no currencies selected to clear fields)
      if (displayCurrencies.length > 0 && 
          currentCurrencies.length === displayCurrencies.length && 
          currentCurrencies.every(currency => displayCurrencies.includes(currency)) &&
          displayCurrencies.every(currency => currentCurrencies.includes(currency))) {
        return; // No update needed
      }
    }
    
    // Save ALL current values to preserve user input
    const currentValues = {};
    if (rowDiv) {
      rowDiv.querySelectorAll('input[type="number"]').forEach(input => {
        const match = input.name.match(/currency_minimum_deposits\[([^\]]+)\]/);
        if (match) {
          // Save value even if it's being edited or just typed
          const value = input.value || input.getAttribute('value') || '';
          if (value) {
            currentValues[match[1]] = value;
          }
        }
      });
    }
    
    // Clear and rebuild
    if (rowDiv) {
      rowDiv.innerHTML = '';
      
      displayCurrencies.forEach(currency => {
        const colDiv = document.createElement('div');
        colDiv.className = 'col-12 mb-2';
        
        const isCrypto = cryptoCurrencies.includes(currency);
        const step = isCrypto ? '0.00000001' : '0.01';
        const placeholder = isCrypto ? '0.00000000' : '0.00';
        const precision = isCrypto ? 8 : 2;
        
        // Always use current value if it exists to preserve user input
        const currentValue = currentValues[currency] || '';
        
        colDiv.innerHTML = `
          <div class="input-group">
            <span class="input-group-text">${currency}</span>
            <input type="number" 
                   name="bonus[currency_minimum_deposits][${currency}]" 
                   value="${currentValue}"
                   class="form-control currency-input" 
                   step="${step}" 
                   min="0"
                   placeholder="${placeholder}"
                   data-currency="${currency}"
                   data-precision="${precision}"
                   data-currency-target="minimumDeposit">
          </div>
        `;
        
        rowDiv.appendChild(colDiv);
      });
      
      // Ensure all new input fields are properly enabled and focusable
      setTimeout(() => {
        rowDiv.querySelectorAll('input[type="number"]').forEach(input => {
          input.removeAttribute('disabled');
          input.removeAttribute('readonly');
          input.style.pointerEvents = 'auto';
        });
      }, 50);
    }
  }

  updateBonusRewardCurrencyFields() {
    // Update currency bonus amounts from partials (if present)
    if (typeof updateCurrencyBonusAmountsFields === 'function') {
      updateCurrencyBonusAmountsFields()
    }
    
    // Update each bonus reward form individually from _type_specific_form.html.erb
    const bonusForms = document.querySelectorAll('[id^="bonus-reward-"]')
    bonusForms.forEach((form, index) => {
      if (typeof populateBonusRewardCurrencyFields === 'function') {
        populateBonusRewardCurrencyFields(index)
      }
    })
    
    // Also update any bonus amounts grids directly (for _type_specific_form.html.erb)
    const bonusAmountsGrids = document.querySelectorAll('[id^="bonus-amounts-grid-"]')
    bonusAmountsGrids.forEach((grid, index) => {
      if (typeof populateBonusRewardCurrencyFields === 'function') {
        populateBonusRewardCurrencyFields(index)
      }
    })
  }

  updateFreespinRewardCurrencyFields() {
    // Update currency freespin bet levels from partials (if present)
    if (typeof updateCurrencyFreespinBetLevelsFields === 'function') {
      updateCurrencyFreespinBetLevelsFields()
    }
    
    // Update each freespin reward form individually from _type_specific_form.html.erb
    const freespinForms = document.querySelectorAll('[id^="freespin-reward-"]')
    freespinForms.forEach((form, index) => {
      if (typeof populateFreespinCurrencyFields === 'function') {
        populateFreespinCurrencyFields(index)
      }
    })
    
    // Also update any freespin bet levels grids directly (for _type_specific_form.html.erb)
    const freespinBetLevelsGrids = document.querySelectorAll('[id^="freespin-bet-levels-grid-"]')
    freespinBetLevelsGrids.forEach((grid, index) => {
      if (typeof populateFreespinCurrencyFields === 'function') {
        populateFreespinCurrencyFields(index)
      }
    })
  }

  updateBonusBuyRewardCurrencyFields() {
    if (typeof updateCurrencyBonusBuyBetLevelsFields === 'function') {
      updateCurrencyBonusBuyBetLevelsFields()
    }
    
    // Update each bonus buy reward form individually
    const bonusBuyForms = document.querySelectorAll('[id^="bonus-buy-reward-"]')
    bonusBuyForms.forEach((form, index) => {
      if (typeof populateBonusBuyRewardCurrencyFields === 'function') {
        populateBonusBuyRewardCurrencyFields(index)
      }
    })
  }
}
