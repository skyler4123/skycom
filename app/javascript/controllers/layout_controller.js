import ApplicationController from "controllers/application_controller"

export default class LayoutController extends ApplicationController {
  static targets = ['header', 'main', 'aside', 'content', 'footer', 'table']
  static values = {
    pagination: { type: Object, default: {} },
    flash: { type: Object, default: {} },
    data: { type: Object, default: {} },
  }
  static outlets = ['flash', 'modal']

  initializeOutlets() {
    ModalController
    this.element.setAttribute(`data-${this.identifier}-${FlashController.identifier}-outlet`, "body")
    this.element.setAttribute(`data-${this.identifier}-${ModalController.identifier}-outlet`, "body")
  }

  initBinding() {
    this.serverHTML = this.element.innerHTML
    this.paginationController = PaginationController
    this.paginationData = ServerData.pagination
    this.selectController = ChoicesController
    this.choicesController = ChoicesController
    this.tableController = TableController
    this.flashValue = ServerData.flash || {}
    this.paginationValue = ServerData.pagination || {}
  }

  initLayout() {
    this.element.className = 'w-full h-full bg-white dark:bg-gray-900 text-black dark:text-white'
    this.element.innerHTML = this.layoutHTML()
  }

  getTableController() {
    return this.application.getControllerForElementAndIdentifier(this.tableTarget, this.tableController.identifier)
  }

  getPaginationController() {
    return this.application.getControllerForElementAndIdentifier(this.paginationTarget, this.paginationController.identifier)
  }

  layoutHTML() {
    return `
    <header class="flex flex-row w-full h-full" data-${this.identifier}-target="header" data-controller="${identifier(this.headerController)}"></header>
    <main class="relative flex flex-row w-full" data-${this.identifier}-target="main">
      <aside class="open:flex w-1/4 h-screen bg-slate-800 pr-4 pl-4 pt-4" data-${this.identifier}-target="aside" data-controller="${identifier(this.asideController)}"></aside>
      <article class="w-full h-full" data-${this.identifier}-target="content">   
      </article>
    </main>
    <footer class="flex flex-row w-full h-full justify-between items-center py-4 px-20 mt-4 border-t-2" data-${this.identifier}-target="footer" data-controller="${identifier(this.footerController)}"></footer>
    `
  }
  
}
