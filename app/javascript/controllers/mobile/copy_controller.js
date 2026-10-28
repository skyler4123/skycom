import { Controller } from "@hotwired/stimulus"

// Copies a read-only value (e.g. the employee email) and reports the result.
export default class Mobile_CopyController extends Controller {
  static targets = ["source"]

  copy() {
    const text = this.hasSourceTarget ? this.sourceTarget.textContent.trim() : ""
    if (!text) return

    navigator.clipboard.writeText(text).then(() => {
      toast({ type: "success", message: translate("Copied to clipboard") })
    }).catch(() => {
      toast({ type: "error", message: translate("Copy failed — select the text manually") })
    })
  }
}
