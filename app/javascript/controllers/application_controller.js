import { isDefined } from "controllers/helpers"
import { Controller } from "@hotwired/stimulus"

export default class ApplicationController extends Controller {
  static values = {
    initialized: { type: Boolean, default: false },
  }

  initialize() {
    if (isDefined(this.initBindings)) { this.initBindings()}
    if (isDefined(this.initLayout)) { this.initLayout() }
    if (isDefined(this.init)) { this.init() }
    this.initializedValue = true
  }
}
