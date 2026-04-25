import { Controller } from "@hotwired/stimulus"
import Companies_NewModalController from "controllers/companies/new_modal_controller"

export default class Home_IndexController extends Controller {
  openNewCompanyModal() {
    openModal({
      html: `<div data-controller="${identifier(Companies_NewModalController)}"></div>`
    })
  }
}
