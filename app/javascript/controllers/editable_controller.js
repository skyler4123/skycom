import { Controller } from "@hotwired/stimulus"

export default class EditableController extends Controller {
  static values = {
    resource: String,
    id: String,
    name: String,
    value: String, // Simplified to String for your text-only requirement
    url: String,
    type: { type: String, default: "text" },
    confirm: { type: Boolean, default: true },
    dispatch: String,
    successMessage: { type: String, default: "Updated successfully!" },
    errorMessage: { type: String, default: "Update failed." },
    confirmMessage: { type: String, default: "Update to \"{{value}}\"?" },
    className: String
  }

  connect() {
    this.isEditing = false
    this.displayElement = this.element.firstElementChild
    
    if (!this.displayElement) {
      console.warn("EditableController: No display element found inside:", this.element)
      return
    }

    // 1. Setup Display Element
    this.displayElement.setAttribute("data-action", "click->editable#toggle")
    this.displayElement.classList.add("cursor-pointer", "hover:opacity-70", "transition-opacity")

    // 2. Setup Input Element (The Twin)
    this.prepareInput()
  }

  prepareInput() {
    if (this.element.querySelector(".editable-input")) return

    // Typography mirroring: Copy classes from the H2/Span
    const baseClasses = "editable-input hidden bg-transparent border-none p-0 m-0 focus:ring-0 outline-none w-full"
    const combinedClasses = `${this.displayElement.className} ${this.classNameValue || ''} ${baseClasses}`
    
    // Cleanup JSON quotes from the valueValue
    const cleanValue = String(this.valueValue || "").replace(/^"|"$/g, '')
    
    const inputHtml = `
      <input type="${this.typeValue}" 
             value="${cleanValue}" 
             class="${combinedClasses}" 
             data-action="keydown->editable#handleKey blur->editable#cancel" 
             autocomplete="off" />
    `.trim()

    this.element.insertAdjacentHTML("beforeend", inputHtml)
    this.inputElement = this.element.querySelector(".editable-input")
  }

  toggle() {
    if (this.isEditing) return
    
    this.isEditing = true
    this.displayElement.classList.add("hidden")
    this.inputElement.classList.remove("hidden")
    
    // Use a slight timeout to ensure visibility before focusing
    setTimeout(() => {
      this.inputElement.focus()
      this.inputElement.select()
    }, 10)
  }

  handleKey(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      this.save()
    } else if (e.key === "Escape") {
      this.cancel()
    }
  }

  async save() {
    const newValue = this.inputElement.value
    const previousValue = String(this.valueValue || "").replace(/^"|"$/g, '')

    if (newValue === previousValue) return this.cancel()

    if (this.confirmValue) {
      const msg = this.confirmMessageValue.replace("{{value}}", newValue)
      if (!window.confirm(msg)) return this.cancel()
    }

    this.inputElement.disabled = true
    this.element.classList.add("opacity-50")

    try {
      const response = await fetchJson(this.urlValue, {
        method: "PATCH",
        body: { [this.nameValue]: newValue }
      })

      // Update State
      this.valueValue = newValue
      this.displayElement.innerText = newValue
      
      toast({ type: "success", message: this.successMessageValue })

      if (this.hasDispatchValue) {
        // Dispatching with 'editable:' prefix is a Stimulus convention
        this.dispatch(this.dispatchValue, { detail: { data: response, value: newValue } })
      }

      this.close()
    } catch (error) {
      toast({ type: "error", message: this.errorMessageValue })
      this.cancel()
    } finally {
      this.inputElement.disabled = false
      this.element.classList.remove("opacity-50")
    }
  }

  cancel() {
    this.inputElement.value = String(this.valueValue || "").replace(/^"|"$/g, '')
    this.close()
  }

  close() {
    this.isEditing = false
    this.inputElement.classList.add("hidden")
    this.displayElement.classList.remove("hidden")
  }
}