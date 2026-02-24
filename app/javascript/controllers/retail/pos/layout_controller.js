import { Controller } from "@hotwired/stimulus"

export default class Retail_Pos_LayoutController extends Controller {

  initialize() {
    this.initLayout()
  }
    
  initLayout() {
    // set body class and innerHTML
    this.element.className = 'min-h-screen flex flex-col'
    this.element.innerHTML = this.layoutHTML()
  }

  disconnect() {
    this.element.innerHTML = ""
  }

}
