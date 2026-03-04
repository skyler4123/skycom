import { Controller } from "@hotwired/stimulus"

export default class ModalController extends Controller {
  close() {
    Helpers.closeModal()
  }
}
