import Companies_LayoutController from "controllers/companies/layout_controller"

// Equipment list page (Calendar/Schedule module — docs/CALENDAR.md).
//
// Plain table + server-side ?q= search. The calendar module is deliberately
// isolated from the dynamic-property + Meilisearch stack, so there is no
// dynamic table config and no table_config_id value here.
//
// Depends on BE: GET /companies/:company_id/calendar_equipments.json
export default class Companies_CalendarEquipments_IndexController extends Companies_LayoutController {
  static targets = ["list"]

  /** @type {{id: string, name: string, code: string|null}[]} */
  calendar_equipments = []

  /** @type {{page: number, pages: number}} */
  pagination = {}

  /** @type {string} */
  searchTerm = ""

  async connect() {
    super.connect()
    await this.load()
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  async load() {
    try {
      const response = await fetchJson(`${Helpers.company_calendar_equipments_path(currentCompany().id)}.json`, {
        params: { q: this.searchTerm || undefined }
      })
      this.calendar_equipments = response.calendar_equipments || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load equipment")}${__errDetail ? ": " + __errDetail : ""}` })
    }
  }

  // Fired by the search input (see contentHTML).
  async search(event) {
    this.searchTerm = event.target.value.trim()
    await this.load()
    this.renderContent()
  }

  async destroy(event) {
    event.preventDefault()
    event.stopPropagation()
    const id = event.currentTarget.dataset.id
    try {
      const response = await fetchJson(Helpers.company_calendar_equipment_path(currentCompany().id, id), { method: "DELETE" })
      toast({ type: "success", message: response.message })
      await this.load()
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete") })
    }
  }


  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 mb-6">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Equipment")}</h2>
            <div class="flex items-center gap-2">
              <input type="text" value="${this.searchTerm}" placeholder="${translate("Search equipment")}"
                data-action="input->companies--calendar-equipments--index#search"
                class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800">
              <a href="${Helpers.new_company_calendar_equipment_path(currentCompany().id)}"
                class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("Add Equipment")}
              </a>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Name")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Code")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Quantity")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Bookable")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="list" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.calendar_equipments.length === 0 ? `
                  <tr><td colspan="5" class="py-10 text-center text-sm text-slate-500">${translate("No records yet")}</td></tr>
                ` : this.calendar_equipments.map(r => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_calendar_equipment_path(currentCompany().id, r.id)}"
                        class="text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${r.name}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${r.code}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${r.quantity}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${r.bookable ? 'Yes' : 'No'}</td>
                    <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                      <a href="${Helpers.edit_company_calendar_equipment_path(currentCompany().id, r.id)}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                      <button data-action="click->companies--calendar-equipments--index#destroy" data-id="${r.id}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </td>
                  </tr>
                `).join("")}
              </tbody>
            </table>
          </div>
          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
