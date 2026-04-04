// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  /**
   * Handles the form submission.
   * Linked via data-action="submit->form#submit"
   */
  async submit(event) {
    event.preventDefault()
    
    const formElement = event.currentTarget
    const formData = new FormData(formElement)
    const url = formElement.action
    const method = formElement.getAttribute("method") || "POST"

    // Convert FormData to a plain object for fetchJson
    const body = Object.fromEntries(formData.entries())

    try {
      // Use your global fetchJson (which handles CSRF)
      const response = await window.fetchJson(url, {
        method: method,
        body: body
      })

      // Success Response handling
      window.toast({ 
        type: "success", 
        message: response?.message || "Successfully saved" 
      })

      // If the form is inside a SweetAlert modal, close it
      if (document.querySelector('.swal2-container')) {
        window.closeModal()
      }

      // Dispatch a success event so parent controllers can refresh UI (e.g. reload lists)
      this.dispatch("success", { detail: { response } })

    } catch (error) {
      // Error Response handling
      window.toast({ 
        type: "error", 
        message: error.message || "Failed to process request" 
      })
    }
  }
}