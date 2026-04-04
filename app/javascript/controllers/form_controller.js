// app/javascript/controllers/form_controller.js
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