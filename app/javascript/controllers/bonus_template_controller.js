import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "dslTag", "project", "status", "form"]
  
  connect() {
    this.initializeEventListeners()
    this.initializeMaximumWinningsHandler()
    this.initializePageLoad()
  }
  
  initializeEventListeners() {
    // Add event listeners to form fields
    if (this.hasNameTarget) {
      this.nameTarget.addEventListener('input', () => this.searchTemplate())
    }
    
    if (this.hasDslTagTarget) {
      this.dslTagTarget.addEventListener('input', () => this.searchTemplate())
    }
    
    if (this.hasProjectTarget) {
      this.projectTarget.addEventListener('change', () => this.searchTemplate())
    }
  }
  
  initializeMaximumWinningsHandler() {
    const maxWinningsTypeSelect = document.getElementById('maximum_winnings_type_select')
    const maxWinningsSuffix = document.getElementById('maximum_winnings_suffix')
    
    if (maxWinningsTypeSelect && maxWinningsSuffix) {
      maxWinningsTypeSelect.addEventListener('change', function() {
        if (this.value === 'multiplier') {
          maxWinningsSuffix.textContent = 'x'
        } else {
          maxWinningsSuffix.textContent = 'EUR'
        }
      })
    }
  }
  
  initializePageLoad() {
    // Initialize type-specific fields if event is already selected
    const bonusTypeSelect = document.querySelector('select[name="bonus[event]"]')
    if (bonusTypeSelect && bonusTypeSelect.value) {
      // Create a mock event object for initialization
      const mockEvent = { target: { value: bonusTypeSelect.value } }
      this.toggleTypeSpecificFields(mockEvent)
    }

    // Check if template_id is provided in URL and show success message
    const urlParams = new URLSearchParams(window.location.search)
    const templateId = urlParams.get('template_id')
    if (templateId) {
      this.showTemplateStatus('found', 'Template applied from URL')
    }
  }
  
  searchTemplate() {
    // Clear previous timeout
    if (this.templateSearchTimeout) {
      clearTimeout(this.templateSearchTimeout)
    }

    // Get current values
    const name = this.hasNameTarget ? this.nameTarget.value.trim() : ''
    const dslTag = this.hasDslTagTarget ? this.dslTagTarget.value.trim() : ''
    const project = this.hasProjectTarget ? this.projectTarget.value : ''

    // Create search params string to avoid duplicate searches
    const searchParams = `${name}|${dslTag}|${project}`
    
    // Don't search if params haven't changed
    if (searchParams === this.lastSearchParams) {
      return
    }

    this.lastSearchParams = searchParams

    // Only search if ALL three parameters are provided
    if (!name || !dslTag || !project) {
      // Hide any existing status
      this.showTemplateStatus('none')
      return
    }

    // Debounce the search (wait 500ms after user stops typing)
    this.templateSearchTimeout = setTimeout(async () => {
      // Show loading state
      this.showTemplateStatus('loading')

      try {
        // Build API URL with all three parameters
        const apiUrl = `/bonuses/find_template?dsl_tag=${encodeURIComponent(dslTag)}&name=${encodeURIComponent(name)}&project=${encodeURIComponent(project)}`

        // Make request to find template
        const response = await fetch(apiUrl)
        const data = await response.json()

        if (response.ok && data.template) {
          this.applyTemplate(data.template)
          this.showTemplateStatus('found', `Template "${data.template.name}" applied (${data.found_by})`)
        } else {
          this.showTemplateStatus('not-found')
        }
      } catch (error) {
        this.showTemplateStatus('not-found')
      }
    }, 500)
  }
  
  applyTemplate(template) {

    // Apply template values to form fields
    if (template.dsl_tag && this.hasDslTagTarget && !this.dslTagTarget.value) {
      this.dslTagTarget.value = template.dsl_tag
    }

    if (template.project && template.project !== 'All' && this.hasProjectTarget && !this.projectTarget.value) {
      this.projectTarget.value = template.project
    }

    if (template.event) {
      const eventSelect = document.querySelector('select[name="bonus[event]"]')
      if (eventSelect) {
        eventSelect.value = template.event
        // Trigger the change event to update type-specific fields
        const mockEvent = { target: { value: template.event } }
        this.toggleTypeSpecificFields(mockEvent)
      }
    }

    if (template.wager) {
      const wagerInput = document.querySelector('input[name="bonus[wager]"]')
      if (wagerInput && !wagerInput.value) {
        wagerInput.value = template.wager
      }
    }

    if (template.maximum_winnings) {
      const maxWinningsInput = document.querySelector('input[name="bonus[maximum_winnings]"]')
      if (maxWinningsInput && !maxWinningsInput.value) {
        maxWinningsInput.value = template.maximum_winnings
      }
    }

    if (template.no_more) {
      const noMoreInput = document.querySelector('input[name="bonus[no_more]"]')
      if (noMoreInput && !noMoreInput.value) {
        noMoreInput.value = template.no_more
      }
    }

    if (template.totally_no_more) {
      const totallyNoMoreInput = document.querySelector('input[name="bonus[totally_no_more]"]')
      if (totallyNoMoreInput && !totallyNoMoreInput.value) {
        totallyNoMoreInput.value = template.totally_no_more
      }
    }

    if (template.groups && template.groups.length > 0) {
      const groupsInput = document.querySelector('input[name="bonus[groups]"]')
      if (groupsInput && !groupsInput.value) {
        groupsInput.value = Array.isArray(template.groups) ? template.groups.join(', ') : template.groups
      }
    }

    if (template.description) {
      const descriptionInput = document.querySelector('textarea[name="bonus[description]"]')
      if (descriptionInput && !descriptionInput.value) {
        descriptionInput.value = template.description
      }
    }

    if (template.currencies && template.currencies.length > 0) {
      // Clear current currency checkboxes
      const currencyCheckboxes = document.querySelectorAll('input.currency-checkbox')
      currencyCheckboxes.forEach(checkbox => checkbox.checked = false)
      
      // Select currencies from template
      const currencies = Array.isArray(template.currencies) ? template.currencies : template.currencies.split(' ')
      currencies.forEach(currency => {
        const checkbox = document.querySelector(`input.currency-checkbox[value="${currency.trim()}"]`)
        if (checkbox) {
          checkbox.checked = true
        }
      })
    }

    // Apply currency minimum deposits if present
    if (template.currency_minimum_deposits && Object.keys(template.currency_minimum_deposits).length > 0) {
      Object.entries(template.currency_minimum_deposits).forEach(([currency, amount]) => {
        const input = document.querySelector(`input[name="bonus[currency_minimum_deposits][${currency}]"]`)
        if (input && !input.value) {
          input.value = amount
        }
      })
    }
  }
  
  showTemplateStatus(status, message = '') {
    const statusContainer = document.getElementById('template-status')
    const loadingEl = document.getElementById('template-loading')
    const foundEl = document.getElementById('template-found')
    const notFoundEl = document.getElementById('template-not-found')
    const messageEl = document.getElementById('template-found-message')

    if (!statusContainer) return

    // Hide all status elements first
    loadingEl.style.display = 'none'
    foundEl.style.display = 'none'
    notFoundEl.style.display = 'none'

    switch (status) {
      case 'loading':
        statusContainer.style.display = 'block'
        loadingEl.style.display = 'block'
        break
      case 'found':
        statusContainer.style.display = 'block'
        foundEl.style.display = 'block'
        if (message && messageEl) {
          messageEl.textContent = message
        }
        // Hide status after 3 seconds
        setTimeout(() => {
          statusContainer.style.display = 'none'
        }, 3000)
        break
      case 'not-found':
        statusContainer.style.display = 'block'
        notFoundEl.style.display = 'block'
        // Hide status after 2 seconds
        setTimeout(() => {
          statusContainer.style.display = 'none'
        }, 2000)
        break
      default:
        statusContainer.style.display = 'none'
    }
  }
  
  toggleTypeSpecificFields(event) {
    // Safety check for event object
    if (!event || !event.target || !event.target.value) {
      console.warn('Invalid event object passed to toggleTypeSpecificFields:', event)
      return
    }
    
    const bonusType = event.target.value
    const minimumDepositField = document.getElementById('minimum-deposit-field')
    const currencyMinimumDepositsSection = document.getElementById('currency-minimum-deposits-section')
    
    // Типы бонусов, которые не должны показывать minimum_deposit
    const nonDepositTypes = ['input_coupon', 'manual', 'collection', 'groups_update', 'scheduler']
    
    if (nonDepositTypes.includes(bonusType)) {
      // Скрываем поле minimum_deposit для типов, которые его не используют
      if (minimumDepositField) {
        minimumDepositField.style.display = 'none'
        // Очищаем значение поля
        const minimumDepositInput = minimumDepositField.querySelector('input')
        if (minimumDepositInput) {
          minimumDepositInput.value = ''
        }
      }
      // Скрываем секцию минимальных депозитов по валютам
      if (currencyMinimumDepositsSection) {
        currencyMinimumDepositsSection.style.display = 'none'
        // Очищаем значения полей минимальных депозитов
        const currencyInputs = currencyMinimumDepositsSection.querySelectorAll('input[type="number"]')
        currencyInputs.forEach(input => input.value = '')
      }
    } else if (bonusType === 'deposit') {
      // Для депозитных бонусов тоже скрываем старое поле, но показываем новую секцию
      if (minimumDepositField) {
        minimumDepositField.style.display = 'none'
        const minimumDepositInput = minimumDepositField.querySelector('input')
        if (minimumDepositInput) {
          minimumDepositInput.value = ''
        }
      }
      // Показываем секцию минимальных депозитов по валютам
      if (currencyMinimumDepositsSection) {
        currencyMinimumDepositsSection.style.display = 'block'
      }
    } else {
      // Показываем поле для других типов (если они появятся в будущем)
      if (minimumDepositField) {
        minimumDepositField.style.display = 'block'
      }
      // Скрываем секцию минимальных депозитов по валютам для других типов
      if (currencyMinimumDepositsSection) {
        currencyMinimumDepositsSection.style.display = 'none'
        const currencyInputs = currencyMinimumDepositsSection.querySelectorAll('input[type="number"]')
        currencyInputs.forEach(input => input.value = '')
      }
    }
    
  }
  
  // Properties
  get templateSearchTimeout() {
    if (!this._templateSearchTimeout) {
      this._templateSearchTimeout = null
    }
    return this._templateSearchTimeout
  }
  
  set templateSearchTimeout(value) {
    this._templateSearchTimeout = value
  }
  
  get lastSearchParams() {
    if (!this._lastSearchParams) {
      this._lastSearchParams = ''
    }
    return this._lastSearchParams
  }
  
  set lastSearchParams(value) {
    this._lastSearchParams = value
  }
}
