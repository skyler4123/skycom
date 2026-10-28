import { Controller } from "@hotwired/stimulus"

// Toggles the shared `dark` class and persists the choice under the same
// localStorage key the desktop layout pre-applies. Mirrors the desktop
// DarkmodeController contract so the theme converges on every boot, Turbo
// navigation and storage change instead of drifting between screens.
export default class Mobile_ThemeController extends Controller {
  static values = {
    darkmode: { type: Boolean, default: false },
  }

  initialize() {
    this.applyStoredTheme()
  }

  connect() {
    this.applyStoredTheme()
    this.storageHandler = () => this.applyStoredTheme()
    try {
      window.addEventListener("storage", this.storageHandler)
    } catch (e) {}
  }

  disconnect() {
    try {
      window.removeEventListener("storage", this.storageHandler)
    } catch (e) {}
  }

  darkmodeValueChanged(value, previousValue) {
    // On boot Stimulus may invoke this once with (default, undefined)
    // before stored state is applied — converge with localStorage instead
    // of trusting the default.
    if (previousValue === undefined) {
      this.applyStoredTheme()
      return
    }
    if (value) {
      this.turnOnDarkmode()
    } else {
      this.turnOffDarkmode()
    }
  }

  toggle() {
    this.darkmodeValue = !document.documentElement.classList.contains("dark")
  }

  applyStoredTheme() {
    let darkmode = false
    try {
      darkmode = localStorage.getItem("darkmode") === "true"
    } catch (e) {}
    if (
      darkmode === this.darkmodeValue &&
      document.documentElement.classList.contains("dark") === darkmode
    ) {
      return
    }
    this.darkmodeValue = darkmode
  }

  turnOnDarkmode() {
    document.documentElement.classList.add("dark")
    try {
      localStorage.setItem("darkmode", "true")
    } catch (e) {}
  }

  turnOffDarkmode() {
    document.documentElement.classList.remove("dark")
    try {
      localStorage.setItem("darkmode", "false")
    } catch (e) {}
  }
}
