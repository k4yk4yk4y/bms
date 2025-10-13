import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "menu"]

  connect() {
    this.initializeDropdown()
  }

  disconnect() {
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
        })
        
        this.dropdownTarget.addEventListener('click', this.boundDropdownClick)
        
      } catch (error) {
      }
    }
    
    // Highlight current project in dropdown
    this.highlightCurrentProject()
    
    // Add click outside listener
    document.addEventListener('click', this.boundClickOutside)
    
    // Add keyboard navigation
    this.dropdownTarget.addEventListener('keydown', this.boundKeydown)
    
    // Add loading indicator for project links
    this.addLoadingIndicators()
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
      } catch (error) {
      }
    }
    
    // Clear bound function references
    this.boundDropdownClick = null
    this.boundClickOutside = null
    this.boundKeydown = null
  }

  refreshDropdown() {
    this.initializeDropdown()
  }

  highlightCurrentProject() {
    const urlParams = new URLSearchParams(window.location.search)
    const currentProjectId = urlParams.get('project_id')
    const currentProject = urlParams.get('project')
    
    if (currentProjectId || currentProject) {
      const projectLinks = this.menuTarget.querySelectorAll('a[href*="project"]')
      projectLinks.forEach(link => {
        const linkParams = new URLSearchParams(link.search)
        const linkProjectId = linkParams.get('project_id')
        const linkProject = linkParams.get('project')
        
        if ((currentProjectId && linkProjectId === currentProjectId) || 
            (currentProject && linkProject === currentProject)) {
          link.classList.add('active', 'fw-bold')
        }
      })
    }
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

  addLoadingIndicators() {
    const projectLinks = this.menuTarget.querySelectorAll('a[href*="project"]')
    projectLinks.forEach(link => {
      // Remove existing click listeners to prevent duplicates
      link.removeEventListener('click', this.handleProjectLinkClick)
      
      // Add new click listener
      link.addEventListener('click', this.handleProjectLinkClick.bind(this))
    })
  }

  handleProjectLinkClick(event) {
    const link = event.currentTarget
    link.innerHTML += ' <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>'
  }

  // Turbo event handlers
  handleTurboLoad() {
    this.initializeDropdown()
  }

  handleTurboRender() {
    this.initializeDropdown()
  }

  handleTurboBeforeRender() {
    this.destroyDropdown()
  }
}
