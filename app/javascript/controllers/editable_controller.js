// app/javascript/controllers/editable_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    name: String,    // e.g., "employee[name]"
    value: String,   // The raw value
    url: String,     // PATCH endpoint
    type: { type: String, default: "text" }, // text, select, number, etc.
    options: Array,  // For selects: [{ name: "Sales", value: "1" }]
    confirm: { type: Boolean, default: true }
  }

  connect() {
    this.isEditing = false
    // Cache the classes from the initial span to apply to the input later
    const initialSpan = this.element.querySelector("span")
    this.textClasses = initialSpan ? initialSpan.className : ""
    this.render()
  }

  // --- Actions ---

  toggle(e) {
    if (this.isEditing) return
    this.isEditing = true
    this.render()

    const input = this.element.querySelector(".editable-input")
    if (input) {
      input.focus()
      if (this.typeValue !== "select") input.select()
    }
  }

  async save(e) {
    // Only trigger on Enter for keyboard events
    if (e.type === "keydown") {
      if (e.key === "Escape") return this.cancel()
      if (e.key !== "Enter") return
      e.preventDefault()
    }

    const input = this.element.querySelector(".editable-input")
    const newValue = input.value

    // 1. Skip if value hasn't changed
    if (String(newValue) === String(this.valueValue)) {
      return this.cancel()
    }

    // 2. Confirm Logic (Default true)
    if (this.confirmValue) {
      if (!confirm(`Are you sure you want to update this to "${newValue}"?`)) {
        return
      }
    }

    try {
      // Global fetchJson
      await fetchJson(this.urlValue, {
        method: "PATCH",
        body: { [this.nameValue]: newValue }
      })

      this.valueValue = newValue
      this.isEditing = false
      this.render()
      
      // Global toast
      toast({ type: "success", message: "Successfully updated!" })
    } catch (error) {
      toast({ type: "error", message: "Update failed. Please try again." })
      this.cancel()
    }
  }

  cancel() {
    this.isEditing = false
    this.render()
  }

  // --- Rendering ---

  render() {
    this.element.innerHTML = this.isEditing ? this.editHTML() : this.viewHTML()
  }

  viewHTML() {
    let displayText = this.valueValue || "..."
    
    // Resolve Enum name for display if it's a select
    if (this.typeValue === "select" && this.optionsValue) {
      const match = this.optionsValue.find(o => String(o.value) === String(this.valueValue))
      if (match) displayText = match.name
    }

    return `
      <span class="${this.textClasses} cursor-pointer hover:opacity-70 transition-opacity" 
            data-action="click->editable#toggle">
        ${displayText}
      </span>
    `
  }

  editHTML() {
    // Reset standard input styles to match text exactly
    const baseClasses = "editable-input bg-transparent border-none p-0 m-0 focus:ring-0 outline-none w-full"
    const combinedClasses = `${this.textClasses} ${baseClasses}`

    if (this.typeValue === "select") {
      const options = this.optionsValue.map(opt => `
        <option value="${opt.value}" ${String(opt.value) === String(this.valueValue) ? 'selected' : ''}>
          ${opt.name}
        </option>
      `).join("")

      return `
        <select class="${combinedClasses} cursor-pointer" 
                data-action="change->editable#save blur->editable#cancel keydown->editable#save">
          ${options}
        </select>
      `
    }

    return `
      <input type="${this.typeValue}" 
             value="${this.valueValue}" 
             class="${combinedClasses}" 
             data-action="keydown->editable#save blur->editable#cancel" 
             autocomplete="off" />
    `
  }
}