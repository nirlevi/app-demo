import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { channel: String }

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create("DashboardLiveChannel", {
      connected: () => {
        console.log("Connected to DashboardLiveChannel")
      },
      
      disconnected: () => {
        console.log("Disconnected from DashboardLiveChannel")
      },
      
      received: (data) => {
        this.handleUpdate(data)
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  handleUpdate(data) {
    if (data.type === 'dashboard_update') {
      this.updateDashboard(data.data)
    }
  }

  updateDashboard(data) {
    // Update recent calls table
    if (data.recent_calls) {
      this.updateRecentCallsTable(data.recent_calls)
    }
    
    // Update stats if available
    if (data.active_calls !== undefined) {
      this.updateStatCard('active-calls', data.active_calls)
    }
    if (data.total_calls_today !== undefined) {
      this.updateStatCard('calls-today', data.total_calls_today)
    }
  }

  updateRecentCallsTable(calls) {
    const tbody = this.element.querySelector('tbody')
    if (!tbody) return

    tbody.innerHTML = calls.map(call => `
      <tr>
        <td>${call.time}</td>
        <td>${call.number}</td>
        <td>${call.duration}</td>
        <td><span class="status ${call.status}">${call.status}</span></td>
        <td>${call.agent}</td>
      </tr>
    `).join('')
  }

  updateStatCard(type, value) {
    const card = document.querySelector(`[data-stat="${type}"] .stat-value`)
    if (card) {
      card.textContent = value
    }
  }
}