import ApplicationController from "controllers/application_controller"
export default class Retail_Pos_LayoutController extends ApplicationController {

  initLayout() {
    // set body class and innerHTML
    this.element.className = 'min-h-screen flex flex-col'
    this.element.innerHTML = this.layoutHTML()
  }

  disconnect() {
    this.element.innerHTML = ""
  }

}
