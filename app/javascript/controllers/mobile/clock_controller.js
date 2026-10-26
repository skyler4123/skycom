import { Controller } from "@hotwired/stimulus"

// Live local clock for the home punch card.
export default class Mobile_ClockController extends Controller {
  static targets = ["time", "period"]

  connect() {
    this.render()
    this.interval = setInterval(() => this.render(), 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  render() {
    const now = new Date()
    const hours = now.getHours()
    const displayHours = String(hours % 12 || 12).padStart(2, "0")
    const minutes = String(now.getMinutes()).padStart(2, "0")
    const seconds = String(now.getSeconds()).padStart(2, "0")

    if (this.hasTimeTarget) this.timeTarget.textContent = `${displayHours}:${minutes}:${seconds}`
    if (this.hasPeriodTarget) this.periodTarget.textContent = hours >= 12 ? "PM" : "AM"
  }
}
