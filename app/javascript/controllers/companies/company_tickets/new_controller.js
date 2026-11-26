import Companies_LayoutController from "controllers/companies/layout_controller"

// New support ticket — traditional submit (data-turbo=false); the server
// redirects to the ticket page on success (DASHBOARD_PATTERN convention).
// Visibility defaults to only-me; the creator can share with the company later.
// Depends on BE: Companies::CompanyTicketsController#new (reference data) + #create (HTML redirect)
// Endpoints: GET <pathname>.json — { ticket_categories, priorities, visibilities, default_visibility };
//            POST /companies/:id/company_tickets
// Docs: docs/superpowers/plans/2026-11-26-company-ticket-visibility.md
export default class Companies_CompanyTickets_NewController extends Companies_LayoutController {
  /** @type {string[]} */
  categories = []

  /** @type {string[]} */
  priorities = []

  /** @type {string[]} */
  visibilities = []

  /** @type {string} */
  defaultVisibility = "only_me"

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.categories = response.ticket_categories || []
      this.priorities = response.priorities || []
      this.visibilities = response.visibilities || []
      this.defaultVisibility = response.default_visibility || "only_me"
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
    const visibilityOptions = Helpers.companyTicketVisibilityOptions()
      .filter((option) => this.visibilities.length === 0 || this.visibilities.includes(option.value))

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Ticket")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Title")}</label>
            <input type="text" name="company_ticket[name]" required placeholder="${translate("e.g. Cannot access billing")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="company_ticket[description]" rows="4"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"></textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Category")}</label>
            <select name="company_ticket[ticket_category]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${categories.map((v) => `<option value="${v}">${this.humanize(v)}</option>`).join("")}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Priority")}</label>
            <select name="company_ticket[priority]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${priorities.map((v) => `<option value="${v}" ${v === "medium" ? "selected" : ""}>${this.humanize(v)}</option>`).join("")}
            </select>
          </div>

          <div class="col-span-2 space-y-2">
            <p class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Who can see this?")}</p>
            <div class="grid gap-2">
              ${visibilityOptions.map((option) => `
                <label class="flex items-start gap-3 px-3 py-2 border border-line rounded-lg bg-card cursor-pointer">
                  <input type="radio" name="company_ticket[visibility]" value="${option.value}"
                    ${option.value === this.defaultVisibility ? "checked" : ""}
                    class="mt-1 h-4 w-4 text-primary border-line cursor-pointer">
                  <span class="flex flex-col gap-0.5">
                    <span class="text-sm font-medium text-foreground">${option.label}</span>
                    <span class="text-xs text-muted-foreground">${option.description}</span>
                  </span>
                </label>`).join("")}
            </div>
            <p class="text-xs text-muted-foreground">${translate("Skycom Support can always see every ticket.")}</p>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Attach files")}</label>
            <input type="file" name="company_ticket[file_attachments][]" multiple
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-muted-foreground cursor-pointer">
          </div>
        </div>

        <div class="flex justify-end pt-6 border-t border-line">
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
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
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" enctype="multipart/form-data"`,
          html: fields
        })}
      </div>
    `
  }
}
