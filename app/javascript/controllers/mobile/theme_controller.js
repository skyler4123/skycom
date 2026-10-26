import { Controller } from "@hotwired/stimulus"

// Toggles the shared `dark` class and persists the choice under the same
// localStorage key the desktop layout pre-applies.
export default class Mobile_ThemeController extends Controller {
  toggle() {
    const isDark = document.documentElement.classList.toggle("dark")
    try {
      localStorage.setItem("darkmode", String(isDark))
    } catch (e) {}
  }
}
