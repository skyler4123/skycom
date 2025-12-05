import ApplicationController from "controllers/application_controller"
import { currentCompanyGroup } from "controllers/helpers"
export default class Retail_Pos_LayoutController extends ApplicationController {
  
  initBinding() {

  }

  initLayout() {
    // add headTags to head
    document.head.insertAdjacentHTML("beforeend", this.headTags())

    // set body class and innerHTML
    this.element.className = 'min-h-screen flex flex-col'
    this.element.innerHTML = this.layoutHTML()
  }
  

  headTags() {
    return `
      <!-- Disable Turbo Prefetching -->
      <meta name="turbo-prefetch" content="false">
      <link href="https://fonts.googleapis.com/css2?family=Lexend:wght@100..900&amp;display=swap" rel="stylesheet" />
      <link
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200"
        rel="stylesheet" />
    `
  }
  
  layoutHTML() {
    return `
      
    `
  }

}
