import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Events_ShowController extends Companies_LayoutController {
  // Event detail — core fields + time window + link sections + warnings banner.
  // Depends on BE: Companies::EventsController#show (event + warnings)
  // Endpoints: GET <event>.json
  // Docs: docs/EVENTS.md
  /** @type {Event | null} */
  event = null

  /** @type {string[]} */
  warnings = []

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_event_path(companyId, recordId)}.json`)
      this.event = response.event
      this.warnings = response.warnings || []

      if (this.event?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.event.category_id)
        this.propertyMetadata = propertyMapping?.metadata?.properties || []
      }

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load event.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-slate-300 dark:text-slate-700">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-slate-50 text-slate-700 dark:bg-slate-800 dark:text-slate-400'}">${value ? translate("True") : translate("False")}</span>`
      case 'integer':
        return `<span class="font-mono text-slate-900 dark:text-slate-100">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-blue-600 dark:text-blue-400">${Number(value).toFixed(2)}</span>`
      case 'datetime': {
        const d = new Date(value)
        return `<span class="text-sm text-slate-900 dark:text-white">${d.toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-slate-900 dark:text-white">${value}</span>`
    }
  }

  linkListHTML(title, icon, items, nameKey = "name") {
    if (!items || items.length === 0) return ''
    return `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate(title)}</h3>
        <div class="flex flex-wrap gap-2">
          ${items.map(item => `
            <span class="inline-flex items-center gap-1 px-3 py-1 text-sm rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
              <span class="material-symbols-outlined text-[16px]">${icon}</span>
              ${item[nameKey] || item.id}${item.quantity ? ` × ${item.quantity}` : ''}
            </span>
          `).join('')}
        </div>
      </div>
    `
  }

  showHTML() {
    const e = this.event
    if (!e) return `<div class="p-8 text-center">${translate("Event not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === e.category_id)

    const warningsHTML = this.warnings.length > 0 ? `
      <div class="mb-6 p-4 rounded-xl border border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-900/20">
        <p class="text-sm font-bold text-amber-700 dark:text-amber-300 mb-2">${translate("Warnings")}</p>
        <ul class="list-disc list-inside text-sm text-amber-700 dark:text-amber-300 space-y-1">
          ${this.warnings.map(w => `<li>${w}</li>`).join('')}
        </ul>
      </div>
    ` : ''

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${field.name}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${this.formatDisplayValue(e[field.key], field.type)}</p>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_events_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Events")}
          </a>

          ${warningsHTML}

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-indigo-100 dark:border-indigo-900/30 bg-indigo-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-indigo-600 dark:text-indigo-400">event</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${e.name}</h2>
              <p class="font-semibold text-indigo-600 dark:text-indigo-400">${e.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-indigo-100 dark:bg-indigo-900/40 px-3 py-1 text-xs font-bold text-indigo-700 dark:text-indigo-300 uppercase">${e.code || translate("N/A")}</span>
                ${Helpers.statusBadge(e.workflow_status)}
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400">
                <span class="material-symbols-outlined">schedule</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Start At")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${e.start_at ? new Date(e.start_at).toLocaleString() : translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400">
                <span class="material-symbols-outlined">schedule</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("End At")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${e.end_at ? new Date(e.end_at).toLocaleString() : translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Category")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${category?.name || e.category?.name || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Type")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.capitalize(e.business_type?.replace('_', ' ') || 'appointment')}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}
          ${this.linkListHTML("Customers", "person", e.customers)}
          ${this.linkListHTML("Employees", "badge", e.employees)}
          ${this.linkListHTML("Services", "concierge", e.services)}
          ${this.linkListHTML("Facilities", "meeting_room", e.facilities)}
          ${this.linkListHTML("Stocks", "inventory", e.stocks)}
          ${this.linkListHTML("Orders", "order_approve", e.orders)}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
            <a href="${Helpers.company_calendar_path(companyId)}"
              class="inline-flex items-center px-6 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Calendar")}
            </a>
            <a href="${Helpers.edit_company_event_path(companyId, e.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Event")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
