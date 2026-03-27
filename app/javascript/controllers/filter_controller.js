// app/javascript/controllers/filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class FilterController extends Controller {
  static values = {
    receiverId: { type: String, default: "" },
    url: { type: String, default: "" },
    method: { type: String, default: "GET" },
    appendParams: { type: Boolean, default: true },
  }

  async change(event) {
    event.preventDefault()

    const endpoint = this.urlValue || window.location.pathname
    const name = this.element.name
    const value = this.element.value

    // 1. Initialize params
    let params = {}

    if (this.appendParamsValue) {
      // Get current params from the URL (e.g., page, other filters)
      const urlParams = new URLSearchParams(window.location.search)
      params = Object.fromEntries(urlParams.entries())
    }

    // 2. Add or overwrite the current filter value
    if (value) {
      params[name] = value
    } else {
      delete params[name] // Remove key if value is empty (e.g., "All" option)
    }

    try {
      // 3. Execute request
      const data = await fetchJson(endpoint, { 
        params: params,
        method: this.methodValue.toUpperCase() 
      })

      // 4. Dispatch back to main controller
      this.dispatch("change", { 
        detail: { 
          data: data,
          receiverId: this.receiverIdValue 
        } 
      })
    } catch (error) {
      console.error("Filter update failed:", error)
    }
  }
}
