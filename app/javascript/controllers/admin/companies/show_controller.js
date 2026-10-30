import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_Companies_ShowController extends Admin_LayoutController {
  /** @type {Object|null} */ company = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[pathParts.length - 1]

    try {
      const response = await fetchJson(`${Helpers.admin_company_path(companyId)}.json`)
      this.company = response.company
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `Failed to load company${__errDetail ? ": " + __errDetail : ""}` })
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
    const c = this.company
    if (!c) return '<div class="p-8 text-center text-muted-foreground">Company not found.</div>'

    const businessTypeColors = {
      retail: 'bg-primary/10 text-primary ',
      restaurant: 'bg-warning/10 text-warning ',
      hospital: 'bg-danger/10 text-danger ',
      education: 'bg-primary/10 text-primary ',
      hotel: 'bg-warning/10 text-warning ',
      fitness: 'bg-success/10 text-success '
    }

    const detailFields = [
      { label: "Business Type", value: c.business_type, type: "badge", badgeClass: businessTypeColors[c.business_type] || 'bg-background text-foreground ' },
      { label: "Email", value: c.email, type: "link", href: `mailto:${c.email}` },
      { label: "Phone", value: c.phone_number, type: "link", href: `tel:${c.phone_number}` },
      { label: "Website", value: c.website, type: "link", href: c.website },
      { label: "City", value: c.city },
      { label: "Country", value: c.country?.toUpperCase() },
      { label: "Employee Count", value: c.employee_count != null ? String(c.employee_count) : null },
      { label: "Registration Number", value: c.registration_number },
      { label: "Tax ID", value: c.tax_id },
      { label: "VAT ID", value: c.vat_id },
      { label: "Ownership", value: c.ownership_type ? c.ownership_type.replace('_', ' ') : null },
      { label: "Currency", value: c.currency?.toUpperCase() },
      { label: "Timezone", value: c.timezone != null ? `UTC${c.timezone > 0 ? '+' : ''}${c.timezone}` : null },
      { label: "Description", value: c.description, type: "full" }
    ]

    return `
      <div class="p-6">
        <a href="/admin/companies"
          class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6 cursor-pointer">
          <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
          Back to Companies
        </a>

        <div class="bg-card rounded-xl border border-line overflow-hidden">
          <!-- Header -->
          <div class="px-6 py-5 border-b border-line">
            <div class="flex items-start justify-between">
              <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-xl bg-success/10 flex items-center justify-center shrink-0">
                  <span class="material-symbols-outlined text-success text-[24px]">business</span>
                </div>
                <div>
                  <h2 class="text-xl font-bold text-foreground">${c.name || 'Unnamed Company'}</h2>
                  <div class="flex items-center gap-2 mt-1">
                    ${c.code ? `<span class="font-mono text-xs bg-muted px-2 py-0.5 rounded text-muted-foreground">${c.code}</span>` : ''}
                    ${Helpers.statusBadge(c.workflow_status)}
                  </div>
                </div>
              </div>
              <div class="text-right text-xs text-muted-foreground">
                <div>Created (UTC) ${c.created_at ? Helpers.timeFormat(c.created_at) : '—'}</div>
                <div class="mt-0.5">Updated (UTC) ${c.updated_at ? Helpers.timeFormat(c.updated_at) : '—'}</div>
              </div>
            </div>
          </div>

          <!-- Detail Grid -->
          <div class="p-6">
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              ${detailFields.map(field => {
                if (field.value == null || field.value === '') return ''

                switch (field.type) {
                  case 'badge':
                    return `
                      <div>
                        <p class="text-[10px] font-bold text-muted-foreground uppercase mb-1">${field.label}</p>
                        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium capitalize ${field.badgeClass}">${field.value}</span>
                      </div>`
                  case 'link':
                    return `
                      <div>
                        <p class="text-[10px] font-bold text-muted-foreground uppercase mb-1">${field.label}</p>
                        <a href="${field.href}" class="text-sm text-primary hover:text-primary cursor-pointer">${field.value}</a>
                      </div>`
                  case 'full':
                    return `
                      <div class="sm:col-span-2 lg:col-span-3">
                        <p class="text-[10px] font-bold text-muted-foreground uppercase mb-1">${field.label}</p>
                        <p class="text-sm text-foreground">${field.value}</p>
                      </div>`
                  default:
                    return `
                      <div>
                        <p class="text-[10px] font-bold text-muted-foreground uppercase mb-1">${field.label}</p>
                        <p class="text-sm font-medium text-foreground">${field.value}</p>
                      </div>`
                }
              }).join('')}
            </div>
          </div>

          <!-- Owner Section -->
          ${c.user ? `
            <div class="px-6 py-4 border-t border-line">
              <p class="text-[10px] font-bold text-muted-foreground uppercase mb-3">Owner</p>
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                  <span class="text-sm font-bold text-primary">${(c.user.name || '?')[0].toUpperCase()}</span>
                </div>
                <div>
                  <p class="text-sm font-medium text-foreground">${c.user.name || 'Unknown'}</p>
                  <p class="text-sm text-muted-foreground">${c.user.email || ''}</p>
                </div>
              </div>
            </div>
          ` : ''}
        </div>
      </div>
    `
  }
}
