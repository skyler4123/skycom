/**
 * LanguageController
 *
 * Purpose: Updates the language preference in localStorage and reloads the UI
 * to apply changes across all controllers and components.
 *
 * On Android, each bottom tab is its own WebView. The native bridge refreshes
 * every loaded tab; a browser has no bridge and reloads the current page.
 */

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    languageCode: { type: String, default: "en" }
  };

  connect() {
    // Sync internal value with localStorage on load
    this.languageCodeValue = localStorage.getItem("languageCode") || "en";
  }

  changeLanguage(event) {
    const newLang = event.params.code;

    if (newLang && newLang !== this.languageCodeValue) {
      // 1. Save new language to local storage
      localStorage.setItem("languageCode", newLang);

      // 2. Refresh every mobile tab through the native bridge when present.
      //    Browser fallback: hard reload to reset the current page state.
      let handledByNative = false;
      try {
        handledByNative = window.SkycomMobile?.reloadTabs?.() === true;
      } catch (e) {
        handledByNative = false;
      }

      if (!handledByNative) {
        window.location.reload();
      }
    }
  }
}
