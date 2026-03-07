// app/javascript/controllers/pagination_controller.js
import { Controller } from "@hotwired/stimulus"

export default class PaginationController extends Controller {
  static values = { 
    data: Object,
  }

  connect() {
    this.render()
  }

  // Whenever the dataValue changes, re-render the pagination
  dataValueChanged() {
    this.render()
  }

  render() {
    if (!this.hasDataValue || !this.dataValue) return
    const p = this.dataValue

    this.element.innerHTML = `
      <div class="flex items-center justify-between w-full">
        <div class="flex items-center gap-2">
          ${this.linkHTML(p.page > 1, 1, 'first_page')}
          ${this.linkHTML(p.page > 1, p.page - 1, 'chevron_left')}
          
          <span class="text-sm font-medium text-slate-700 dark:text-slate-300 px-2">
            Page ${p.page} of ${p.last}
          </span>

          ${this.linkHTML(p.page < p.last, p.page + 1, 'chevron_right')}
          ${this.linkHTML(p.page < p.last, p.last, 'last_page')}
        </div>
      </div>
    `
  }

  linkHTML(enabled, page, icon) {
    // Generate the URL by replacing the "P" placeholder from your Rails response
    const url = this.dataValue.url_template.replace('P', page)
    
    const baseClass = "flex items-center gap-1 px-3 py-1 text-sm border rounded-lg transition-colors font-medium"
    const disabledClass = "text-slate-300 border-slate-100 cursor-not-allowed pointer-events-none dark:border-slate-800 dark:text-slate-700"
    const enabledClass = "text-slate-600 border-slate-200 hover:bg-slate-50 dark:text-slate-400 dark:border-slate-700 dark:hover:bg-slate-800"

    return `
      <a 
        href="${enabled ? url : '#'}"
        class="${baseClass} ${enabled ? enabledClass : disabledClass}"
        data-page="${page}"
        data-action="click->pagination#navigate"
      >
        <span class="material-symbols-outlined text-[18px]">${icon}</span>
      </a>
    `
  }

  // navigate(event) {
  //   // Prevent the browser from doing a full page reload
  //   event.preventDefault()
  //   const page = event.currentTarget.dataset.page
  //   const url = event.currentTarget.getAttribute('href')

  //   // Dispatch the custom event with both the page and the URL
  //   this.dispatch("change", { detail: { page: page, url: url } })
  // }
}

