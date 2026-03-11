// app/javascript/controllers/filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class FilterController extends Controller {
  static values = {
    receiverId: { type: String, default: "" },
  }
  
  // Triggered by data-action="change->filter#change" on the container
  change(event) {
    // Dispatch a generic 'filter-changed' event
    this.dispatch("changed", { 
      detail: { 
        url: randomId(),
        receiverId: this.receiverIdValue // Pass the ID in the detail
      } 
    })
  }
}