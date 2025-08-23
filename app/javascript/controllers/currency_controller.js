import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="currency"
export default class extends Controller {
  static targets = ["checkbox", "minimumDeposit"]
  
  connect() {
    console.log("Currency controller connected")
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Listen for currency checkbox changes
    this.checkboxTargets.forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        this.updateAllCurrencyFields()
      })
    })

    // Listen for minimum deposit changes
    this.minimumDepositTargets.forEach(input => {
      input.addEventListener('input', () => {
        this.updateAllCurrencyFields()
      })
    })

    // Setup MutationObserver for dynamically added forms
    this.setupMutationObserver()
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

  // Method called when currency checkboxes change
  updateAllCurrencyFields() {
    console.log("Updating all currency fields...")
    
    // Get selected currencies
    const selectedCurrencies = this.getSelectedCurrencies()
    const minimumDepositCurrencies = this.getMinimumDepositCurrencies()
    
    console.log("Selected currencies:", selectedCurrencies)
    console.log("Minimum deposit currencies:", minimumDepositCurrencies)

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
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    
    // Clear minimum deposit values for both bonus and bonus_template forms
    this.minimumDepositTargets.forEach(input => {
      input.value = ''
    })
    
    // Also clear any bonus_template specific inputs that might not be targets
    const templateInputs = document.querySelectorAll('input[name^="bonus_template[currency_minimum_deposits]"]')
    templateInputs.forEach(input => {
      input.value = ''
    })
    
    this.updateAllCurrencyFields()
  }

  getSelectedCurrencies() {
    return this.checkboxTargets
      .filter(checkbox => checkbox.checked)
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
    const allCurrencies = ["RUB", "EUR", "USD", "UAH", "KZT", "NOK", "PLN", "TRY", "CAD", "AUD", "AZN", "NZD", "BRL", "INR", "ARS", "MXN", "PEN", "NGN", "ZAR", "CLP", "DKK", "SEK", "RON", "HUF", "JPY", "UZS", "GBP", "BTC", "ETH", "LTC", "BCH", "XRP", "TRX", "DOGE", "USDT"];
    const cryptoCurrencies = ["BTC", "ETH", "LTC", "BCH", "XRP", "TRX", "DOGE", "USDT"];
    
    // Show only selected currencies (not all)
    const displayCurrencies = selectedCurrencies.length > 0 ? selectedCurrencies : [];
    
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
