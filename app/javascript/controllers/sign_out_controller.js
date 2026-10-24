import { Controller } from "@hotwired/stimulus"

export default class SignOutController extends Controller {
  handleClick() {
    if (typeof window.clearClientCache === "function") {
      window.clearClientCache()
    }
  }
}