import { Controller } from "@hotwired/stimulus"

// Server-rendered flash banners: dismiss on close or after a short delay.
export default class Mobile_FlashController extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), 4000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    clearTimeout(this.timeout)
    this.element.remove()
  }
}
