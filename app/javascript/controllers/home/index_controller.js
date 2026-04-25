import { Controller } from "@hotwired/stimulus"
import Home_NewModalController from "controllers/home/new_modal_controller"

export default class Home_IndexController extends Controller {
  openNewModal() {
    openModal({
      html: `<div data-controller="${identifier(Home_NewModalController)}"></div>`
    })
  }
}
