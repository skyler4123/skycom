// app/javascript/controllers/editable_controller.js
import { Controller } from "@hotwired/stimulus"

/**
 * EditableController
 * * Switches text to an input/select on click and saves via PATCH request.
 * Requires an internal element (like a <span>) to provide typography classes.
 * * Example Usage:
 * <div 
 * data-controller="editable" 
 * data-editable-confirm-value="true"
 * data-editable-name-value="name" 
 * data-editable-value-value="${e.name}" 
 * data-editable-url-value="${Helpers.edit_company_employee_path(currentCompany().id, e.id)}"
 * >
 * <span class="text-2xl font-black text-slate-900 dark:text-white">
 * ${e.name}
 * </span>
 * </div>
 */
export default class EditableController extends Controller {
  static values = {
    resource: String,
    id: String,
    name: String,    // The parameter key (e.g., "name", "description")
    value: [String, Array],   // The current value (string or array for multi-select)
    url: String,     // The PATCH endpoint
    type: { type: String, default: "text" }, 
    options: Array,  // For selects: [{ name: "Sales", value: "1" }]
    className: String, // Additional CSS classes for input/select
    multiple: { type: Boolean, default: false }, // For multi-select
    confirm: { type: Boolean, default: true },
    dispatch: String,
    successMessage: { type: String, default: "Updated successfully!" },
    errorMessage: { type: String, default: "Update failed." },
    confirmMessage: { type: String, default: "Update to \"{{value}}\"?" }
  }

  connect() {
    this.isEditing = false
    // 1. Grab the element exactly as the user provided it in the helper
    this.displayElement = this.element.firstElementChild
    
    // 2. Capture classes so the Input can look the same
    this.textClasses = this.displayElement.className
    
    // 3. Set the initial action
    this.displayElement.setAttribute("data-action", "click->editable#toggle")
    this.displayElement.classList.add("cursor-pointer")
  }

  // --- Actions ---

  toggle(e) {
    if (this.isEditing) return
    this.isEditing = true
    this.render()

    const input = this.element.querySelector(".editable-input")
    if (input) {
      input.focus()
      // Use select() for text inputs to make editing faster
      if (this.typeValue !== "select") input.select()
    }
  }

  async save(e) {
    // Keyboard Handling
    if (e.type === "keydown") {
      if (e.key === "Escape") return this.cancel()
      if (e.key !== "Enter") return
      e.preventDefault()
    }

    const input = this.element.querySelector(".editable-input")
    let newValue
    let previousValue

    // Handle multi-select vs single select
    if (this.multipleValue && input.multiple) {
      // Multi-select: get array of selected values
      newValue = Array.from(input.selectedOptions).map(opt => opt.value)
      previousValue = Array.isArray(this.valueValue) ? this.valueValue : []
    } else {
      // Single select or text input
      newValue = input.value
      previousValue = this.valueValue
    }

    // Skip if value hasn't changed
    if (JSON.stringify(newValue) === JSON.stringify(previousValue)) {
      return this.cancel()
    }

    // Dynamic Confirmation Message
    if (this.confirmValue) {
      const msg = this.confirmMessageValue.replace("{{value}}", this.formatValueForDisplay(newValue))
      if (!confirm(msg)) return
    }

    try {
      const response = await fetchJson(this.urlValue, {
        method: "PATCH",
        body: { [this.nameValue]: newValue }
      })

      // Update internal state
      this.valueValue = newValue
      this.isEditing = false
      this.render()

      this.dispatch(this.dispatchValue, { 
        detail: { 
          data: response
        } 
      })
      
      toast({ type: "success", message: this.successMessageValue })
    } catch (error) {
      toast({ type: "error", message: this.errorMessageValue })
      this.cancel()
    }
  }

  cancel() {
    this.isEditing = false
    this.render()
  }

  // --- Rendering ---

  render() {
    if (this.isEditing) {
      // Switch to input mode
      this.displayElement.classList.add("hidden")
      // Only create the input if it doesn't exist to avoid focus issues
      if (!this.element.querySelector(".editable-input")) {
        this.element.insertAdjacentHTML("beforeend", this.editHTML())
        const input = this.element.querySelector(".editable-input")
        input.focus()
        if (this.typeValue !== "select") input.select()
      }
    } else {
      // Switch to view mode
      const input = this.element.querySelector(".editable-input")
      input?.remove()
      
      this.displayElement.classList.remove("hidden")
      
      // For select types, look up the display name from options
      const displayValue = this.formatValueForDisplay(this.valueValue)
      
      this.displayElement.innerText = displayValue || "..."
    }
  }

  viewHTML() {
    const displayText = this.formatValueForDisplay(this.valueValue) || "..."

    // Inject the value into the saved template
    // This preserves ALL your Tailwind classes exactly as they were in the helper
    return this.templateHTML
      .replace("{{value}}", displayText)
      .replace(/>.*<\/span>/, ` data-action="click->editable#toggle">${displayText}</span>`) 
  }

  formatValueForDisplay(value) {
    if (Array.isArray(value)) {
      return value.map(v => {
        const match = (this.optionsValue || []).find(o => String(o.value) === String(v))
        return match ? match.name : v
      }).join(", ")
    }
    // Single value
    const match = (this.optionsValue || []).find(o => String(o.value) === String(value))
    return match ? match.name : value
  }

  editHTML() {
    // Use the classes captured from the original tag (h1, p, span, etc.)
    const baseClasses = "editable-input bg-transparent border-none p-0 m-0 focus:ring-0 outline-none w-full"
    const combinedClasses = `${this.textClasses} ${this.classNameValue} ${baseClasses}`

    if (this.typeValue === "select") {
      const currentValues = Array.isArray(this.valueValue) ? this.valueValue : [this.valueValue]
      const options = (this.optionsValue || []).map(opt => `
        <option value="${opt.value}" ${currentValues.includes(opt.value) ? 'selected' : ''}>
          ${opt.name}
        </option>
      `).join("")

      const multipleAttr = this.multipleValue ? 'multiple' : ''
      const sizeAttr = this.multipleValue ? 'size="4"' : ''

      return `
        <select class="${combinedClasses} cursor-pointer" ${multipleAttr} ${sizeAttr}
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