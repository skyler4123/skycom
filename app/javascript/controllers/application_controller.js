import * as Helpers from "controllers/helpers"
import { Controller } from "@hotwired/stimulus"

export default class ApplicationController extends Controller {
  static values = {
    initialized: { type: Boolean, default: false },
  }

  initialize() {
    if (Helpers.isDefined(this.initBindings)) { this.initBindings()}
    if (Helpers.isDefined(this.initLayout)) { this.initLayout() }
    if (Helpers.isDefined(this.init)) { this.init() }
    this.initializedValue = true
  }
}
