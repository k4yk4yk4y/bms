import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "menu"]

  connect() {
    console.log("Settings dropdown controller connected")
    this.initializeDropdown()
  }

  disconnect() {
    console.log("Settings dropdown controller disconnected")
    this.destroyDropdown()
  }

  initializeDropdown() {
    // Destroy any existing dropdown first
    this.destroyDropdown()
    
    // Store bound function references for proper cleanup
    this.boundDropdownClick = this.handleDropdownClick.bind(this)
    this.boundClickOutside = this.clickOutside.bind(this)
    this.boundKeydown = this.handleKeydown.bind(this)
    
    // Initialize Bootstrap dropdown manually after Turbo navigation
    if (window.bootstrap && window.bootstrap.Dropdown) {
      try {
        // Check if dropdown already has an instance
        const existingInstance = window.bootstrap.Dropdown.getInstance(this.dropdownTarget)
        if (existingInstance) {
          existingInstance.dispose()
        }
        
        // Create new Bootstrap dropdown instance
        this.bootstrapDropdown = new window.bootstrap.Dropdown(this.dropdownTarget, {
          autoClose: true,
          boundary: 'viewport'
        })
        console.log("Settings Bootstrap dropdown initialized")
        
        // Add click event listener to the dropdown button
        this.dropdownTarget.addEventListener('click', this.boundDropdownClick)
        
      } catch (error) {
        console.error("Error initializing Settings Bootstrap dropdown:", error)
      }
    }
    
    // Add click outside listener
    document.addEventListener('click', this.boundClickOutside)
    
    // Add keyboard navigation
    this.dropdownTarget.addEventListener('keydown', this.boundKeydown)
  }

  handleDropdownClick(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.bootstrapDropdown) {
      // Toggle dropdown manually
      const isShown = this.dropdownTarget.classList.contains('show')
      if (isShown) {
        this.bootstrapDropdown.hide()
      } else {
        this.bootstrapDropdown.show()
      }
    }
  }

  destroyDropdown() {
    // Remove event listeners using stored bound functions
    if (this.dropdownTarget && this.boundDropdownClick) {
      this.dropdownTarget.removeEventListener('click', this.boundDropdownClick)
    }
    
    if (this.boundClickOutside) {
      document.removeEventListener('click', this.boundClickOutside)
    }
    
    if (this.dropdownTarget && this.boundKeydown) {
      this.dropdownTarget.removeEventListener('keydown', this.boundKeydown)
    }
    
    // Destroy Bootstrap dropdown instance
    if (this.bootstrapDropdown) {
      try {
        this.bootstrapDropdown.dispose()
        this.bootstrapDropdown = null
        console.log("Settings Bootstrap dropdown destroyed")
      } catch (error) {
        console.error("Error destroying Settings Bootstrap dropdown:", error)
      }
    }
    
    // Clear bound function references
    this.boundDropdownClick = null
    this.boundClickOutside = null
    this.boundKeydown = null
  }

  refreshDropdown() {
    console.log("Refreshing settings dropdown")
    this.initializeDropdown()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      if (this.bootstrapDropdown) {
        this.bootstrapDropdown.hide()
      }
    }
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      if (this.bootstrapDropdown) {
        this.bootstrapDropdown.hide()
      }
    }
  }

  // Turbo event handlers - ключевые для решения проблемы
  handleTurboLoad() {
    console.log("Turbo load event - reinitializing settings dropdown")
    this.initializeDropdown()
  }

  handleTurboRender() {
    console.log("Turbo render event - reinitializing settings dropdown")
    this.initializeDropdown()
  }

  handleTurboBeforeRender() {
    console.log("Turbo before render event - destroying settings dropdown")
    this.destroyDropdown()
  }
}
