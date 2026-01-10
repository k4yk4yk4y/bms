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
    
    // Highlight current project in dropdown
    this.highlightCurrentProject()
    
    // Add click outside listener
    document.addEventListener('click', this.boundClickOutside)
    
    // Add loading indicator for project links
    this.addLoadingIndicators()
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

  handleTurboBeforeCache() {
    this.destroyDropdown()
  }
}
