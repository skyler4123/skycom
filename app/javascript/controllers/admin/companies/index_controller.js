import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_Companies_IndexController extends Admin_LayoutController {
  static targets = ["companiesList"]

  /** @type {Array} */ companies = []
  /** @type {Object} */ pagination = {}

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(Helpers.admin_companies_path())
      this.companies = response.companies || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `Failed to load companies${__errDetail ? ": " + __errDetail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const columns = [
      { key: "name", name: "Company Name" },
      { key: "code", name: "Code" },
      { key: "business_type", name: "Type" },
      { key: "email", name: "Email" },
      { key: "phone_number", name: "Phone" },
      { key: "owner", name: "Owner" },
      { key: "workflow_status", name: "Status" },
      { key: "created_at", name: "Created (UTC)" }
    ]

    return `
      <div class="p-6">
        <div class="bg-card rounded-xl border border-line">
          <div class="flex items-center justify-between px-6 py-4 border-b border-line">
            <h2 class="text-base font-bold text-foreground">All Companies</h2>
            <span class="text-sm text-muted-foreground">${this.companies.length} total</span>
          </div>
          <div class="overflow-x-auto">
            ${table({
              rows: this.companies,
              columns,
              identifier: this.identifier,
              target: "companiesList",
              mappingLookup: {},
              renderers: {
                name: (value, record) => `
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-lg bg-success/10 flex items-center justify-center shrink-0">
                      <span class="material-symbols-outlined text-success text-[18px]!">business</span>
                    </div>
                    <a href="${Helpers.admin_company_path(record.id)}"
                      class="font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
                      ${value || 'Unnamed'}
                    </a>
                  </div>
                `,
                code: (value) => `<span class="font-mono text-xs bg-muted/60 px-2 py-0.5 rounded text-muted-foreground font-medium">${value || '—'}</span>`,
                business_type: (value) => {
                  const colors = {
                    retail: 'bg-primary/10 text-primary ',
                    restaurant: 'bg-warning/10 text-warning ',
                    hospital: 'bg-danger/10 text-danger ',
                    education: 'bg-primary/10 text-primary ',
                    hotel: 'bg-warning/10 text-warning ',
                    fitness: 'bg-success/10 text-success '
                  }
                  const colorClass = colors[value] || 'bg-background text-foreground '
                  return `<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium capitalize ${colorClass}">${value || '—'}</span>`
                },
                email: (value) => value ? `<span class="text-sm text-muted-foreground">${value}</span>` : '<span class="text-muted-foreground/60">—</span>',
                phone_number: (value) => value ? `<span class="text-sm text-muted-foreground">${value}</span>` : '<span class="text-muted-foreground/60">—</span>',
                owner: (value, record) => record.user?.name || '<span class="text-muted-foreground/60">—</span>',
                workflow_status: (value) => `${Helpers.statusBadge(value)}`,
                created_at: (value) => value ? `<span class="text-sm text-muted-foreground">${Helpers.timeFormat(value)}</span>` : '—'
              },
              renderActions: (record) => `
                <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                  <a href="${Helpers.admin_company_path(record.id)}"
                    class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                    <span class="material-symbols-outlined text-[20px]">visibility</span>
                  </a>
                </td>`
            })}
          </div>
          <div class="flex justify-center py-4 border-t border-line">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
