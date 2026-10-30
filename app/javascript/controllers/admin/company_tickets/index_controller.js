import Admin_LayoutController from "controllers/admin/layout_controller"

// Admin ticket pool — cross-company triage list with enum filters.
// List page polls; it never fans out to N company channels.
// Depends on BE: Admin::CompanyTicketsController#index|assign
// Endpoints: GET /admin/company_tickets.json?status=&priority=&unassigned=1 (+ open_count)
// Docs: docs/superpowers/plans/2026-10-07-company-support-center.md
export default class Admin_CompanyTickets_IndexController extends Admin_LayoutController {
  static targets = ["ticketsList"]

  /** @type {any[]} */
  tickets = []

  /** @type {number} */
  openCount = 0

  async connect() {
    super.connect()

    await this.refresh()

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  async refresh() {
    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${Helpers.admin_company_tickets_path()}.json?${urlParams.toString()}`)
      this.tickets = response.company_tickets || []
      this.pagination = response.pagination || {}
      this.openCount = response.open_count || 0
      if (this.hasContentTarget) this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to load tickets" })
    }
  }

  async pickUp(event) {
    event.preventDefault()
    const { ticketId } = event.params
    try {
      await fetchJson(Helpers.assign_admin_company_ticket_path(ticketId), { method: "POST" })
      await this.refresh()
      toast({ type: "success", message: "Ticket assigned to you" })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to pick up ticket" })
    }
  }

  humanize(value) {
    if (!value) return "—"
    return value.split("_").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const statuses = ["open", "in_progress", "waiting_customer", "resolved", "closed", "cancelled"]
    const columns = [
      { key: "company", name: "Company" },
      { key: "name", name: "Title" },
      { key: "priority", name: "Priority" },
      { key: "status", name: "Status" },
      { key: "assigned_user", name: "Assignee" },
      { key: "updated_at", name: "Updated (UTC)" },
      { key: "actions", name: "" }
    ]

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">

          <div class="flex items-center gap-3 mb-6">
            <h2 class="text-lg font-bold text-foreground">Support Pool</h2>
            <span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-primary/10 text-primary ">${this.openCount} Open</span>
          </div>

          <form method="get" action="${pathname()}" class="flex flex-wrap items-end gap-3 mb-6">
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">Status</label>
              <select name="status" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                ${selectOptionsHTML(statuses.map((v) => ({ value: v, name: this.humanize(v) })), urlParams.get("status"), "All")}
              </select>
            </div>
            <div class="flex items-center gap-2 pb-2">
              <input type="checkbox" name="unassigned" value="1" ${urlParams.get("unassigned") ? "checked" : ""}
                class="h-4 w-4 rounded border-line text-primary cursor-pointer">
              <label class="text-sm text-muted-foreground">Unassigned only</label>
            </div>
            <button type="submit" class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm flex items-center gap-2 cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">search</span>
              Search
            </button>
          </form>

          <div class="overflow-x-auto">
            ${table({
              rows: this.tickets,
              columns,
              identifier: this.identifier,
              target: "ticketsList",
              renderers: {
                company: (value) => `<span class="text-sm text-muted-foreground">${escapeHtml(value?.name) || "—"}</span>`,
                name: (value, record) => `
                  <a href="${Helpers.admin_company_ticket_path(record.id)}"
                    class="font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
                    ${escapeHtml(value) || "Untitled ticket"}
                  </a>`,
                priority: (value) => `${Helpers.statusBadge(value || "medium")}`,
                status: (value) => `${Helpers.statusBadge(value || "open")}`,
                assigned_user: (value) => `<span class="text-sm text-muted-foreground">${escapeHtml(value?.name || value?.email) || "—"}</span>`,
                updated_at: (value) => `<span class="text-xs text-muted-foreground">${value ? Helpers.timeFormat(value) : "—"}</span>`,
                actions: (value, record) => record.assigned_user
                  ? ""
                  : `<button type="button" data-action="click->${this.identifier}#pickUp" data-${this.identifier}-ticket-id-param="${record.id}" class="px-3 py-1 text-xs font-medium text-primary hover:bg-primary/10 rounded-lg cursor-pointer">Pick Up</button>`
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
