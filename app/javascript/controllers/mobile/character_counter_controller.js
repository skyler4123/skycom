import { Controller } from "@hotwired/stimulus"

// Keeps a "0/240" counter in sync with its textarea.
export default class Mobile_CharacterCounterController extends Controller {
  static targets = ["input", "output"]

  connect() {
    this.update()
  }

  update() {
    const max = this.inputTarget.maxLength > 0 ? this.inputTarget.maxLength : 240
    this.outputTarget.textContent = `${this.inputTarget.value.length}/${max}`
  }
}
