import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.innerHTML = this.html()
  }

  html() {
    return `
      <div class="w-48">
        <a class="flex items-center gap-3 px-4 py-2 rounded-md text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20" href="/sign_out">
          <span class="material-symbols-outlined text-sm">logout</span>
          Sign Out
        </a>
      </div>
    `
  }
}
