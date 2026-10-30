import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_DiscountGroups_IndexController extends Companies_LayoutController {
  // Discounts dashboard — campaign groups (DiscountGroup) with budget progress + status.
  // Static columns (config/ledger model — no PropertyMapping/TableConfig).
  // Depends on BE: Companies::DiscountGroupsController#index
  // Endpoints: GET <pathname>.json — DB-scoped paginated list (no filters form)
  // Docs: docs/DISCOUNTS.md, docs/superpowers/specs/2026-09-22-discounts-frontend-design.md
  static targets = ["groupsList"]

  /** @type {any[]} */
  groups = []

  async connect() {
    super.connect()

    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.groups = response.discount_groups || []
      this.pagination = response.pagination || {}
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load discount campaigns") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  formatMoney(cents) {
    if (cents === null || cents === undefined) return "—"
    return Number(cents / 100).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }

  budgetBar(record) {
    if (!record.total_budget_cents) return `<span class="text-muted-foreground/60">—</span>`
    const pct = Math.min(100, Math.round((record.current_spent_cents / record.total_budget_cents) * 100))
    return `
      <div class="flex flex-col gap-1 min-w-[120px]">
        <span class="text-xs text-muted-foreground">${this.formatMoney(record.current_spent_cents)} / ${this.formatMoney(record.total_budget_cents)}</span>
        <div class="h-1.5 w-full rounded-full bg-muted">
          <div class="h-1.5 rounded-full ${pct >= 100 ? "bg-danger/100" : "bg-primary"}" style="width:${pct}%"></div>
        </div>
      </div>`
  }

  contentHTML() {
    const columns = [
      { key: "name", name: translate("Name") },
      { key: "prefix", name: translate("Prefix") },
      { key: "discount_type", name: translate("Type") },
      { key: "budget", name: translate("Budget") },
      { key: "campaign_status", name: translate("Status") },
      { key: "validity", name: translate("Validity") },
      { key: "generated_codes_count", name: translate("Codes") }
    ]

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">

          <div class="flex items-center justify-between gap-4 mb-6">
            <h2 class="text-lg font-bold text-foreground">${translate("Discounts")}</h2>
            <a href="${Helpers.new_company_discount_group_path(currentCompany().id)}"
              class="flex items-center justify-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("New Campaign")}
            </a>
          </div>

          <div class="overflow-x-auto">
            ${table({
              rows: this.groups,
              columns,
              identifier: this.identifier,
              target: "groupsList",
              renderers: {
                name: (value, record) => `
                  <a href="${Helpers.company_discount_group_path(currentCompany().id, record.id)}"
                    class="font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
                    ${value || translate("Unnamed Campaign")}
                  </a>`,
                prefix: (value) => `<span class="font-mono text-xs bg-muted/60 px-2 py-0.5 rounded text-muted-foreground font-medium">${value || "—"}</span>`,
                discount_type: (value, record) => `<span class="text-sm text-muted-foreground">${value === "percentage" ? `${record.percentage}%` : this.formatMoney(record.amount_cents)}</span>`,
                budget: (value, record) => this.budgetBar(record),
                campaign_status: (value) => `${Helpers.statusBadge(value)}`,
                validity: (value, record) => `<span class="text-xs text-muted-foreground">${record.start_at ? new Date(record.start_at).toLocaleDateString() : "—"} → ${record.end_at ? new Date(record.end_at).toLocaleDateString() : "—"}</span>`,
                generated_codes_count: (value) => `<span class="text-sm font-medium text-foreground">${value ?? 0}</span>`
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.edit_company_discount_group_path(currentCompany().id, record.id)}"
                    class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">edit</span>
                  </a>
                </td>`
            })}
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>`
  }
}
