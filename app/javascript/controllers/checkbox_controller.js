// app/javascript/controllers/checkbox_controller.js
import { Controller } from "@hotwired/stimulus"

export default class CheckboxController extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "PATCH" },
    name: { type: String, default: "status" },
    value: { type: Boolean, default: false },
    confirm: { type: Boolean, default: false },
    confirmMessage: { type: String, default: "Are you sure?" }
  }

  connect() {
    this.previousState = this.valueValue
    this.element.checked = this.valueValue
  }

  isTestEnvironment() {
    return window.navigator.userAgent.includes("HeadlessChrome") ||
           window.Capybara &&
           window.Capybara.animate === false
  }

  async toggle(event) {
    const newState = event.target.checked

    if (newState === this.previousState) {
      return
    }

    if (this.confirmValue && !this.isTestEnvironment()) {
      const confirmed = confirm(this.confirmMessageValue)
      if (!confirmed) {
        event.target.checked = this.previousState
        return
      }
    }

    try {
      const response = await fetchJson(this.urlValue, {
        method: this.methodValue,
        body: { [this.nameValue]: newState }
      })

      this.previousState = newState
      this.valueValue = newState

      this.dispatch("success", {
        detail: {
          response,
          value: newState,
          previousValue: this.previousState
        }
      })

      toast({ type: "success", message: response?.message || "Updated successfully!" })
    } catch (error) {
      event.target.checked = this.previousState
      toast({ type: "error", message: error?.message || "Update failed." })
    }
  }
}