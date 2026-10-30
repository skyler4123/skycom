import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Invoices_ShowController extends Companies_LayoutController {
  /** @type {(Invoice & { category?: { id: string, name: string } }) | null} */
  invoice = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const invoiceId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_invoice_path(companyId, invoiceId)}.json`)
      this.invoice = response.invoice

      if (this.invoice?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.invoice.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load invoice.")}</div>`
          return true
        }
        return false
      })
    }
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-muted-foreground/60">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-success/10 text-success' : 'bg-background text-foreground'}">${value ? translate("True") : translate("False")}</span>`
      case 'integer':
        return `<span class="font-mono text-foreground">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-primary">${Number(value).toFixed(2)}</span>`
      case 'datetime':
        return `<span class="text-sm text-foreground">${new Date(value).toLocaleString()}</span>`
      default:
        return `<span class="text-sm text-foreground">${value}</span>`
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  showHTML() {
    const i = this.invoice
    if (!i) return `<div class="p-8 text-center">${translate("Invoice not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === i.category_id)

    const businessTypeLabel = i.business_type === 'subscription' ? translate("Subscription")
      : i.business_type?.charAt(0).toUpperCase() + i.business_type?.slice(1) || translate("Sales")

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-muted-foreground">${field.name}</p>
                <p class="text-sm font-semibold text-foreground">${this.formatDisplayValue(i[field.key], field.type)}</p>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_invoices_path(companyId)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Invoices")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-warning/10 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-warning">receipt</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${i.name || translate("Unnamed Invoice")}</h2>
              <p class="font-semibold text-warning">${i.description || ''}</p>
              <span class="inline-flex items-center rounded-lg bg-warning/10 px-3 py-1 text-xs font-bold text-warning uppercase mt-2">${i.code || translate("N/A")}</span>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Type")}</p>
                <p class="text-sm font-semibold text-foreground">${businessTypeLabel}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning">
                <span class="material-symbols-outlined">toggle_on</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Status")}</p>
                <p class="text-sm font-semibold">${Helpers.statusBadge(i.workflow_status)}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning">
                <span class="material-symbols-outlined">payments</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Amount")}</p>
                <p class="text-sm font-semibold text-foreground font-mono">${i.currency?.toUpperCase() || 'USD'} ${((i.price_cents || 0) / 100).toFixed(2)}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning">
                <span class="material-symbols-outlined">calendar_today</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Due Date")}</p>
                <p class="text-sm font-semibold text-foreground">${i.due_date ? new Date(i.due_date).toLocaleDateString() : translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Category")}</p>
                <p class="text-sm font-semibold text-foreground">${category?.name || translate("N/A")}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_invoice_path(companyId, i.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Edit Invoice")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
