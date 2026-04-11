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
    value: String,   // The current value
    url: String,     // The PATCH endpoint
    type: { type: String, default: "text" }, 
    options: Array,  // For selects: [{ name: "Sales", value: "1" }]
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
    const newValue = input.value
    const previousValue = this.valueValue // Capture the state before updating

    // Skip if value hasn't changed
    if (String(newValue) === String(previousValue)) {
      return this.cancel()
    }

    // Dynamic Confirmation Message
    if (this.confirmValue) {
      const msg = this.confirmMessageValue.replace("{{value}}", newValue)
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
      this.displayElement.innerText = this.valueValue || "..."
    }
  }

  viewHTML() {
    let displayText = this.valueValue || "..."
    
    if (this.typeValue === "select" && this.optionsValue) {
      const match = this.optionsValue.find(o => String(o.value) === String(this.valueValue))
      if (match) displayText = match.name
    }

    // Inject the value into the saved template
    // This preserves ALL your Tailwind classes exactly as they were in the helper
    return this.templateHTML
      .replace("{{value}}", displayText)
      .replace(/>.*<\/span>/, ` data-action="click->editable#toggle">${displayText}</span>`) 
  }

  editHTML() {
    // Use the classes captured from the original tag (h1, p, span, etc.)
    const baseClasses = "editable-input bg-transparent border-none p-0 m-0 focus:ring-0 outline-none w-full"
    const combinedClasses = `${this.textClasses} ${baseClasses}`

    if (this.typeValue === "select") {
      const options = (this.optionsValue || []).map(opt => `
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