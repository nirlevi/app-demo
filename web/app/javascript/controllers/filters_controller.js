import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.timeout = null
  }

  submit(event) {
    if (this.hasFormTarget) {
      this.formTarget.submit()
    }
  }

  debounceSubmit(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.submit(event)
    }, 500) // Wait 500ms after user stops typing
  }

  clear(event) {
    event.preventDefault()
    
    // Clear all form inputs
    const form = this.formTarget || this.element.querySelector('form')
    if (form) {
      const inputs = form.querySelectorAll('input[type="text"], input[type="search"], select, input[type="date"]')
      inputs.forEach(input => {
        if (input.type === 'text' || input.type === 'search' || input.type === 'date') {
          input.value = ''
        } else if (input.tagName === 'SELECT') {
          input.selectedIndex = 0
        }
      })
      
      // Submit the cleared form
      form.submit()
    }
  }
}