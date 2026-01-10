import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "menu"]

  connect() {
    this.setupTurboListeners()
    this.initializeDropdown()
  }

  disconnect() {
    this.destroyDropdown()
    this.removeTurboListeners()
  }

  initializeDropdown() {
    // Destroy any existing dropdown first
    this.destroyDropdown()
    
    // Store bound function references for proper cleanup
    this.boundClickOutside = this.clickOutside.bind(this)
    
    // Add click outside listener
    document.addEventListener('click', this.boundClickOutside)
    
  }

  handleDropdownClick(event) {
    event.preventDefault()
    event.stopPropagation()
    this.toggleDropdown()
  }

  destroyDropdown() {
    // Remove event listeners using stored bound functions
    if (this.boundClickOutside) {
      document.removeEventListener('click', this.boundClickOutside)
    }

    this.hideDropdown()

    // Clear bound function references
    this.boundClickOutside = null
  }

  refreshDropdown() {
    this.initializeDropdown()
  }

  setupTurboListeners() {
    this.boundTurboLoad = this.handleTurboLoad.bind(this)
    this.boundTurboRender = this.handleTurboRender.bind(this)
    this.boundTurboBeforeCache = this.handleTurboBeforeCache.bind(this)

    document.addEventListener('turbo:load', this.boundTurboLoad)
    document.addEventListener('turbo:render', this.boundTurboRender)
    document.addEventListener('turbo:before-cache', this.boundTurboBeforeCache)
  }

  removeTurboListeners() {
    if (this.boundTurboLoad) {
      document.removeEventListener('turbo:load', this.boundTurboLoad)
    }

    if (this.boundTurboRender) {
      document.removeEventListener('turbo:render', this.boundTurboRender)
    }

    if (this.boundTurboBeforeCache) {
      document.removeEventListener('turbo:before-cache', this.boundTurboBeforeCache)
    }

    this.boundTurboLoad = null
    this.boundTurboRender = null
    this.boundTurboBeforeCache = null
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.hideDropdown()
    }
  }

  isOpen() {
    return this.menuTarget.classList.contains('show')
  }

  showDropdown() {
    this.element.classList.add('show')
    this.dropdownTarget.classList.add('show')
    this.menuTarget.classList.add('show')
    this.dropdownTarget.setAttribute('aria-expanded', 'true')
  }

  hideDropdown() {
    if (!this.dropdownTarget || !this.menuTarget) {
      return
    }

    this.element.classList.remove('show')
    this.dropdownTarget.classList.remove('show')
    this.menuTarget.classList.remove('show')
    this.dropdownTarget.setAttribute('aria-expanded', 'false')
  }

  toggleDropdown() {
    if (this.isOpen()) {
      this.hideDropdown()
    } else {
      this.showDropdown()
    }
  }

  // Turbo event handlers - ключевые для решения проблемы
  handleTurboLoad() {
    this.initializeDropdown()
  }

  handleTurboRender() {
    this.initializeDropdown()
  }

  handleTurboBeforeCache() {
    this.destroyDropdown()
  }
}
