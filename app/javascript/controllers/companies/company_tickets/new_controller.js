import Companies_LayoutController from "controllers/companies/layout_controller"

// New support ticket — traditional submit (data-turbo=false); the server
// redirects to the ticket page on success (DASHBOARD_PATTERN convention).
// Depends on BE: Companies::CompanyTicketsController#new (reference data) + #create (HTML redirect)
// Endpoints: GET <pathname>.json — { ticket_categories, priorities }; POST /companies/:id/company_tickets
// Docs: docs/superpowers/plans/2026-10-07-company-support-center.md
export default class Companies_CompanyTickets_NewController extends Companies_LayoutController {
  /** @type {string[]} */
  categories = []

  /** @type {string[]} */
  priorities = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.categories = response.ticket_categories || []
      this.priorities = response.priorities || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load ticket options") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  humanize(value) {
    return value.split("_").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
  }

  contentHTML() {
    // Fallbacks keep the selects usable when the reference fetch fails (FLAKY_TESTS §6).
    const categories = this.categories.length > 0 ? this.categories : ["billing", "technical", "account", "feature_request", "other"]
    const priorities = this.priorities.length > 0 ? this.priorities : ["low", "medium", "high", "urgent"]

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Ticket")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Title")}</label>
            <input type="text" name="company_ticket[name]" required placeholder="${translate("e.g. Cannot access billing")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="company_ticket[description]" rows="4"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"></textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Category")}</label>
            <select name="company_ticket[ticket_category]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${categories.map((v) => `<option value="${v}">${this.humanize(v)}</option>`).join("")}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Priority")}</label>
            <select name="company_ticket[priority]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${priorities.map((v) => `<option value="${v}" ${v === "medium" ? "selected" : ""}>${this.humanize(v)}</option>`).join("")}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Attach files")}</label>
            <input type="file" name="company_ticket[file_attachments][]" multiple
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-600 dark:text-slate-300 cursor-pointer">
          </div>
        </div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Ticket")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_company_tickets_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" enctype="multipart/form-data"`,
          html: fields
        })}
      </div>
    `
  }
}
