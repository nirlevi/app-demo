import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateTime()
    this.timer = setInterval(() => {
      this.updateTime()
    }, 1000)
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  updateTime() {
    const now = new Date()
    this.element.textContent = now.toLocaleTimeString('en-US', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    })
  }
}