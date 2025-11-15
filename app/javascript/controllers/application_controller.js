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
    if (isDefined(this.initBinding)) { this.initBinding()}
    if (isDefined(this.initLayout)) { this.initLayout() }
    if (isDefined(this.init)) { this.init() }
  }
  
}
