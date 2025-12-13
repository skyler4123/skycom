import { isDefined } from "controllers/helpers"
import { Controller } from "@hotwired/stimulus"

export default class ApplicationController extends Controller {
  static get identifier() {
    let identifier
    identifier = this.name
    identifier = identifier.replace('Controller', '')
    identifier = identifier.replaceAll('_', 'NAMESPACE')
    identifier = identifier
    .match(/[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+/g)
    .map(x => x.toLowerCase())
    .join('-');
    identifier = identifier.replaceAll('namespace', '')
    // identifier = "data-controller=" + identifier
    return identifier
  }

  initialize() {
    if (isDefined(this.initBindings)) { this.initBindings()}
    if (isDefined(this.initLayout)) { this.initLayout() }
    if (isDefined(this.init)) { this.init() }
  }

  // to be implemented in LinkController
  openByPathname() {
    return `data-link-target="openByPathname"`
  }

  // to be implemented in DarkmodeController
  darkmode() {
    return `data-controller="darkmode"`
  }

  // to be implemented in LanguageController
  translate(key) {
    return `data-language-key="${key}"`
  }
  
  triggerLanguageDropdown() {
    return `data-language-target="triggerDropdown"`
  }

  languageCodeTextTarget() {
    return `data-language-target="codeText"`
  }

  // Append new action
  addAction(element, action) {
    const existingActions = element.getAttribute("data-action") || "";
    // Use a Set to ensure all actions are unique.
    const actionSet = new Set(existingActions.split(" ").filter(Boolean));
    actionSet.add(action);
    element.setAttribute("data-action", Array.from(actionSet).join(" "));
  }
}
