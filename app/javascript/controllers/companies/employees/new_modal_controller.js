import { Controller } from "@hotwired/stimulus"

export default class Companies_Employees_NewModalController extends Controller {
  connect() {
    this.initActions()
  }

  initActions() {
    addAction(this.element, `click->${this.identifier}#open`)
  }

  open(event) {
    console.log(event)
    openModal({ html: this.modalHTML() })
  }

  modalHTML() {
    return `
      <div class="bg-red-500">
        Add content for new form here
      </div>
    `
  }
}
