// app/javascript/controllers/filter_controller.js

/**
 * FilterController (Legacy/Advanced)
 * * --- ARCHITECTURE NOTE ---
 * USE NATIVE FORM SUBMISSION BY DEFAULT. 
 * Use a <form method="get" data-turbo-action="advance"> and let the server 
 * refresh the page or Turbo Frame. It is simpler and handles URL history better.
 * For standard filtering, WE SHOULD USE NATIVE FORM SUBMISSION:
 * 1. Use a standard <form method="get"> with Turbo.
 * 2. Allow the page to refresh/morph with the server response.
 * 3. This is simpler, more accessible, and keeps the URL in sync automatically.
 * ----------------------------
 * * Use this JS-based controller ONLY when:
 * 1. You need to update multiple non-standard UI components that aren't 
 * part of a single Turbo Frame/Stream.
 * 2. You are managing high-frequency filtering in a heavy JSON-only environment 
 * where a full page morph is too expensive.
 * --------------------------
 * * HOW IT WORKS:
 * 1. Attaches to an input/select element.
 * 2. On change, it captures its own 'name' and 'value'.
 * 3. It merges these into the current URL parameters (preserving page, sort, etc.).
 * 4. It performs an AJAX request (fetchJson) to the specified endpoint.
 * 5. It dispatches the server response so a parent controller can update the UI.
 * * USAGE:
 * <select 
 * name="status" 
 * data-controller="filter" 
 * data-action="change->filter#change"
 * data-filter-url-value="/employees"
 * data-filter-receiver-id-value="employee-table"
 * >
 * <option value="active">Active</option>
 * <option value="resigned">Resigned</option>
 * </select>
 * * VALUES:
 * - url: The endpoint to hit (defaults to current path).
 * - receiverId: ID passed back in the dispatch detail to identify which UI part to update.
 * - appendParams: (Boolean) Whether to keep existing URL query strings (default: true).
 */

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
