import { Controller } from "@hotwired/stimulus"

/**
 * Keeps the app-UI language preference aligned with the homepage locale when
 * the visitor explicitly chooses a language. Navigation is intentionally not
 * intercepted: the anchor remains the canonical, crawlable way to switch.
 */
export default class Home_LanguageController extends Controller {
  sync(event) {
    const code = event.params?.code
    if (!code) return

    try {
      localStorage.setItem("languageCode", code)
    } catch (_) {
      // Private browsing or storage disabled: the URL still carries the locale.
    }
  }
}
