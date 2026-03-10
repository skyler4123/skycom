// app/javascript/controllers/filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class FilterController extends Controller {
  static values = {
    receiverId: { type: String, default: "" },
  }
  
  // Triggered by data-action="change->filter#change" on the container
  change(event) {
    event.preventDefault()
    console.log(event)

    this.dispatch("change", { detail: { url: randomId() } })
  }
}