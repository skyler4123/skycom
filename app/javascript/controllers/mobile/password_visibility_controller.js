import { Controller } from "@hotwired/stimulus"

// Reveals/conceals the sign-in password without a page reload.
export default class Mobile_PasswordVisibilityController extends Controller {
  static targets = ["input", "button", "showIcon", "hideIcon"]

  toggle() {
    const isVisible = this.inputTarget.type === "text"
    this.inputTarget.type = isVisible ? "password" : "text"
    this.showIconTarget.classList.toggle("hidden", !isVisible)
    this.hideIconTarget.classList.toggle("hidden", isVisible)
    this.buttonTarget.setAttribute("aria-label", isVisible ? "Show password" : "Hide password")
  }
}
