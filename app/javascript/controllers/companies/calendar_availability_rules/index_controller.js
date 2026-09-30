import Companies_LayoutController from "controllers/companies/layout_controller"

// Working hours list (Calendar/Schedule module — docs/CALENDAR.md).
//
// Raw weekly windows per practitioner or per room, plus blackout blocks for
// leave. Skycom does NOT compute free slots from these yet — that is the
// Calendar::Adapter#available_slots seam (docs/CALENDAR.md §6).
//
// Days are submitted as calendar_availability_rule[days_of_week][] — the array
// form strong params needs (a bare symbol would be silently dropped).
//
// Depends on BE: GET    /companies/:company_id/calendar_availability_rules.json
//            DELETE /companies/:company_id/calendar_availability_rules/:id.json
export default class Companies_CalendarAvailabilityRules_IndexController extends Companies_LayoutController {
  static targets = ["list"]

  /** @type {Object[]} */
  rules = []

  /** @type {{page: number, pages: number}} */
  pagination = {}

  /** @type {string} */
  searchTerm = ""

  /** @type {string} */
  ownerFilter = ""

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
      const response = await fetchJson(`${Helpers.company_calendar_availability_rules_path(currentCompany().id)}.json`, {
        params: { q: this.searchTerm || undefined }
      })
      this.rules = response.calendar_availability_rules || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load working hours")}${__errDetail ? ": " + __errDetail : ""}` })
    }
  }

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
      const response = await fetchJson(Helpers.company_calendar_availability_rule_path(currentCompany().id, id), { method: "DELETE" })
      toast({ type: "success", message: response.message })
      await this.load()
      this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete") })
    }
  }

  // "Mon–Fri" / "Sat, Sun" / "All days"
  daysSummary(days) {
    if (!days || days.length === 0) return translate("All days")
    const names = { 1: translate("Monday"), 2: translate("Tuesday"), 3: translate("Wednesday"),
      4: translate("Thursday"), 5: translate("Friday"), 6: translate("Saturday"), 7: translate("Sunday") }
    const weekdays = days.filter((d) => d <= 5).sort()
    const weekend = days.filter((d) => d >= 6).sort()
    const short = (list) => list.map((d) => names[d]?.slice(0, 3) || d).join(", ")
    return [short(weekdays), short(weekend)].filter(Boolean).join(" / ") || translate("All days")
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 mb-6">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Working hours")}</h2>
            <div class="flex items-center gap-2">
              <input type="text" value="${this.searchTerm}" placeholder="${translate("Search working hours")}"
                data-action="input->companies--calendar-availability-rules--index#search"
                class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800">
              <a href="${Helpers.new_company_calendar_availability_rule_path(currentCompany().id)}"
                class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("Add Working Hours")}
              </a>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Name")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Applies To")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Days")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Window")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Type")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="list" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.rules.length === 0 ? `
                  <tr><td colspan="6" class="py-10 text-center text-sm text-slate-500">${translate("No working hours yet")}</td></tr>
                ` : this.rules.map(r => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">${r.name || "—"}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${r.owner_label || "—"}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${this.daysSummary(r.days_of_week)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${r.start_time} – ${r.end_time}</td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${r.is_unavailable
                        ? "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300"
                        : "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300"}">
                        ${r.is_unavailable ? translate("Blackout") : translate("Working hours")}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                      <a href="${Helpers.edit_company_calendar_availability_rule_path(currentCompany().id, r.id)}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                      <button data-action="click->companies--calendar-availability-rules--index#destroy" data-id="${r.id}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </td>
                  </tr>
                `).join("")}
              </tbody>
            </table>
          </div>
          <div class="flex justify-center pt-6">${pagination(this.pagination)}</div>
        </div>
      </div>
    `
  }
}
