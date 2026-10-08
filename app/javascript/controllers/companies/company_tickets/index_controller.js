import Companies_LayoutController from "controllers/companies/layout_controller"

// Help Center ticket list — enum filters (status/priority/category).
// Ticket taxonomy is the inline `ticket_category` enum, NOT the
// Category/PropertyMapping system, so there is no `category_id` filter here.
// Depends on BE: Companies::CompanyTicketsController#index
// Endpoints: GET <pathname>.json?status=&priority=&ticket_category=&mine=1 (open_count included)
// Docs: docs/superpowers/plans/2026-10-07-company-support-center.md
export default class Companies_CompanyTickets_IndexController extends Companies_LayoutController {
  static targets = ["ticketsList"]

  /** @type {any[]} */
  tickets = []

  /** @type {number} */
  openCount = 0

  async connect() {
    super.connect()

    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.tickets = response.company_tickets || []
      this.pagination = response.pagination || {}
      this.openCount = response.open_count || 0
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load tickets") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  statusOptions() {
    return ["open", "in_progress", "waiting_customer", "resolved", "closed", "cancelled"]
      .map((v) => ({ value: v, name: this.humanize(v) }))
  }

  priorityOptions() {
    return ["low", "medium", "high", "urgent"].map((v) => ({ value: v, name: this.humanize(v) }))
  }

  categoryOptions() {
    return ["billing", "technical", "account", "feature_request", "other"]
      .map((v) => ({ value: v, name: this.humanize(v) }))
  }

  humanize(value) {
    return value.split("_").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const columns = [
      { key: "name", name: translate("Title") },
      { key: "ticket_category", name: translate("Category") },
      { key: "priority", name: translate("Priority") },
      { key: "status", name: translate("Status") },
      { key: "employee", name: translate("Raised by") },
      { key: "assigned_user", name: translate("Assignee") },
      { key: "updated_at", name: translate("Updated") }
    ]

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <div class="flex items-center gap-3">
              <h2 class="text-lg font-bold text-slate-900 dark:text-white">${translate("Support Tickets")}</h2>
              <span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">${this.openCount} ${translate("Open")}</span>
            </div>
            <a href="${Helpers.new_company_company_ticket_path(currentCompany().id)}"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm whitespace-nowrap cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("New Ticket")}
            </a>
          </div>

          <form method="get" action="${pathname()}" class="flex flex-wrap items-end gap-3 mb-6">
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Status")}</label>
              <select name="status" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                ${selectOptionsHTML(this.statusOptions(), urlParams.get("status"), translate("All"))}
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Priority")}</label>
              <select name="priority" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                ${selectOptionsHTML(this.priorityOptions(), urlParams.get("priority"), translate("All"))}
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Category")}</label>
              <select name="ticket_category" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                ${selectOptionsHTML(this.categoryOptions(), urlParams.get("ticket_category"), translate("All"))}
              </select>
            </div>
            <label class="flex items-center gap-2 h-[38px] px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 cursor-pointer">
              <input type="checkbox" name="mine" value="1" ${urlParams.get("mine") === "1" ? "checked" : ""} class="h-4 w-4 rounded border-slate-300 text-blue-600 cursor-pointer">
              ${translate("Mine only")}
            </label>
            <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm flex items-center gap-2 cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">search</span>
              ${translate("Search")}
            </button>
          </form>

          <div class="overflow-x-auto">
            ${table({
              rows: this.tickets,
              columns,
              identifier: this.identifier,
              target: "ticketsList",
              renderers: {
                name: (value, record) => `
                  <a href="${Helpers.company_company_ticket_path(currentCompany().id, record.id)}"
                    class="font-medium text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                    ${escapeHtml(value) || translate("Untitled ticket")}
                  </a>`,
                ticket_category: (value) => `<span class="text-sm text-slate-600 dark:text-slate-300">${value ? this.humanize(value) : "—"}</span>`,
                priority: (value) => `${Helpers.statusBadge(value || "medium")}`,
                status: (value) => `${Helpers.statusBadge(value || "open")}`,
                employee: (value) => `<span class="text-sm text-slate-600 dark:text-slate-300">${escapeHtml(value?.name) || "—"}</span>`,
                assigned_user: (value) => `<span class="text-sm text-slate-600 dark:text-slate-300">${escapeHtml(value?.name || value?.email) || "—"}</span>`,
                updated_at: (value) => `<span class="text-xs text-slate-500 dark:text-slate-400">${value ? new Date(value).toLocaleString() : "—"}</span>`
              }
            })}
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>`
  }
}
