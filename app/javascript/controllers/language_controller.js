/**
 * LanguageController
 * 
 * Purpose: Updates the language preference in localStorage and reloads
 * the page to apply changes across all controllers and components.
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
      
      // 2. Hard reload to reset the entire page state
      window.location.reload();
    }
  }
}