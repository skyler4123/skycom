// app/javascript/controllers/pagination_controller.js
import { Controller } from "@hotwired/stimulus"

export default class PaginationController extends Controller {
  static values = { 
    data: Object,
  }

  connect() {
    this.render()
  }

  dataValueChanged() {
    this.render()
  }

  render() {
    if (!this.hasDataValue || !this.dataValue) return
    const p = this.dataValue

    this.element.innerHTML = `
      <div class="flex items-center justify-between w-full">
        <div class="flex items-center gap-1">
          ${this.linkHTML(p.page > 1, 1, 'first_page')}
          ${this.linkHTML(p.page > 1, p.page - 1, 'chevron_left')}
          
          <div class="flex items-center gap-1 mx-2">
            ${this.generatePageRange(p).map(n => {
              if (n === '...') {
                return `<span class="px-2 text-slate-400">...</span>`
              }
              return this.numberLinkHTML(n, n === p.page)
            }).join('')}
          </div>

          ${this.linkHTML(p.page < p.last, p.page + 1, 'chevron_right')}
          ${this.linkHTML(p.page < p.last, p.last, 'last_page')}
        </div>
      </div>
    `
  }

  // Helper to generate the numbers to show (e.g. [1, '...', 10, 11, 12, '...', 22])
  generatePageRange(p) {
    const current = p.page
    const last = p.last
    const delta = 1 // Numbers to show on each side of current page
    const range = []

    for (let i = 1; i <= last; i++) {
      if (i === 1 || i === last || (i >= current - delta && i <= current + delta)) {
        range.push(i)
      } else if (range[range.length - 1] !== '...') {
        range.push('...')
      }
    }
    return range
  }

  // Link generator for the specific page numbers
  numberLinkHTML(number, isCurrent) {
    const url = this.dataValue.url_template.replace('P', number)
    const baseClass = "px-3 py-1 text-sm font-medium rounded-lg transition-colors border"
    const activeClass = "bg-blue-600 border-blue-600 text-white pointer-events-none"
    const inactiveClass = "text-slate-600 border-slate-200 hover:bg-slate-50 dark:text-slate-400 dark:border-slate-700 dark:hover:bg-slate-800"

    return `
      <a href="${url}" class="${baseClass} ${isCurrent ? activeClass : inactiveClass}">
        ${number}
      </a>
    `
  }

  linkHTML(enabled, page, icon) {
    const url = this.dataValue.url_template.replace('P', page)
    const baseClass = "flex items-center gap-1 px-2 py-1 text-sm border rounded-lg transition-colors font-medium"
    const disabledClass = "text-slate-300 border-slate-100 cursor-not-allowed pointer-events-none dark:border-slate-800 dark:text-slate-700"
    const enabledClass = "text-slate-600 border-slate-200 hover:bg-slate-50 dark:text-slate-400 dark:border-slate-700 dark:hover:bg-slate-800"

    return `
      <a href="${enabled ? url : '#'}" class="${baseClass} ${enabled ? enabledClass : disabledClass}">
        <span class="material-symbols-outlined text-[20px]">${icon}</span>
      </a>
    `
  }
}