// app/javascript/controllers/form_controller.js

/**
 * FormController
 * * Purpose: The centralized handler for all Skycom AJAX form submissions.
 * * --- HOW IT WORKS ---
 * 1. Hijacks the standard browser submit event via 'preventDefault()'.
 * 2. Scrapes the form using the native 'FormData' API.
 * 3. NESTING: This is the critical step. It converts flat HTML inputs 
 * (e.g., name="employee[name]") into nested JSON objects: { employee: { name: '...' } }.
 * This ensures Rails 'strong_parameters' can parse the request without modification.
 * 4. Submission: Sends the nested object via the global 'fetchJson' helper.
 * 5. Feedback: 
 * - Success: Shows a success toast, closes any open modal, and dispatches 
 * a 'success' event to notify Index/Table controllers to refresh.
 * - Error: Catches validation errors or server crashes and shows an error toast.
 * * * USAGE (with Helper):
 * ${form({
 * action: "/employees",
 * method: "POST",
 * html: `... fields ...`
 * })}
 * * * MANUAL USAGE:
 * <form data-controller="form" data-action="submit->form#submit" action="/path">
 * <input name="user[email]" type="email">
 * <button type="submit">Save</button>
 * </form>
 */

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  /**
   * Handles the form submission for all Skycom forms.
   * Linked via data-action="submit->form#submit"
   */
  async submit(event) {
    event.preventDefault()
    
    const formElement = event.currentTarget
    const formData = new FormData(formElement)
    const url = formElement.action || pathname()
    const method = (formElement.getAttribute("method") || "POST").toUpperCase()

    // Check for confirm attribute
    if (formElement.dataset.confirm === "true") {
      const message = formElement.dataset.confirmMessage || "Are you sure?"
      if (!confirm(message)) {
        return  // User cancelled - exit early
      }
    }

    // 1. Convert Flat FormData into a Nested Object (The Rails Way)
    const body = this.nestFormData(formData)

    try {
      // 2. Use Skycom global fetchJson
      const response = await fetchJson(url, {
        method: method,
        body: body
      })

      // 3. Success Handling
      if (response && (response.status === "success" || response.id)) {
        toast({ 
          type: "success", 
          message: response?.message || "Successfully saved" 
        })

        // Close Skycom/Swal modals
        if (closeModal) closeModal()

        // 4. Dispatch success for parent IndexControllers to refresh tables
        this.dispatch("success", { detail: { response, form: formElement } })
      } else {
        throw new Error(response?.message || "Validation failed")
      }

    } catch (error) {
      toast({ 
        type: "error", 
        message: error.message || "Failed to process request" 
      })
    }
  }

  /**
   * Converts FormData with bracket notation (e.g., employee[name]) 
   * into a nested object that Rails Strong Params understands.
   */
  nestFormData(formData) {
    const obj = {}
    
    formData.forEach((value, key) => {
      // Regex to find "root[child]" or "root"
      const matches = key.match(/^([^\[]+)(?:\[([^\]]+)\])?/)
      
      if (matches) {
        const root = matches[1]  // e.g., "employee"
        const child = matches[2] // e.g., "name"

        if (child) {
          obj[root] = obj[root] || {}
          obj[root][child] = value
        } else {
          obj[root] = value
        }
      }
    })
    
    return obj
  }
}