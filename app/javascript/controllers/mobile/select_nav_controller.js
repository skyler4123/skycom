import { Controller } from "@hotwired/stimulus"

// Navigates as soon as a <select> changes; option values are full URLs.
export default class Mobile_SelectNavController extends Controller {
  navigate(event) {
    if (event.target.value) window.location.assign(event.target.value)
  }
}
