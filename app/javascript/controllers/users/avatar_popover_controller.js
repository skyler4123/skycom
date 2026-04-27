import { Controller } from "@hotwired/stimulus"
import Users_ShowModalController from "controllers/users/show_modal_controller"

export default class extends Controller {
  connect() {
    this.element.innerHTML = this.html()
  }

  html() {
    return `
      <div class="w-48">
        <button 
          data-action="click->${this.identifier}#openProfileModal"
          class="flex w-full items-center gap-3 rounded-md px-4 py-2 text-sm text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800">
          <span class="material-symbols-outlined text-sm">person</span>
          Profile
        </button>
        <div class="my-1 border-t border-slate-200 dark:border-slate-700"></div>
        <a class="flex items-center gap-3 px-4 py-2 rounded-md text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20" href="/sign_out">
          <span class="material-symbols-outlined text-sm">logout</span>
          Sign Out
        </a>
      </div>
    `
  }

  openProfileModal() {
    openModal({ html: `<div data-controller="${identifier(Users_ShowModalController)}"></div>` })
  }
}