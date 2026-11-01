import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Orders_ShowController extends Companies_LayoutController {
  /** @type {(Order & { category?: { id: string, name: string } }) | null} */
  order = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const orderId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_order_path(companyId, orderId)}.json`)
      this.order = response.order

      if (this.order?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.order.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load order.")}</div>`
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
    const o = this.order
    if (!o) return `<div class="p-8 text-center">${translate("Order not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === o.category_id)

    const businessTypeLabel = o.business_type === 'in_store' ? translate("In Store")
      : o.business_type?.charAt(0).toUpperCase() + o.business_type?.slice(1) || translate("Online")

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
                <p class="text-sm font-semibold text-foreground">${this.formatDisplayValue(o[field.key], field.type)}</p>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_orders_path(companyId)}"
            class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Orders")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-warning/10 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-warning">receipt_long</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${o.name || translate('Unnamed Order')}</h2>
              <p class="font-semibold text-warning">${o.description || ''}</p>
                <span class="inline-flex items-center rounded-lg bg-warning/10 px-3 py-1 text-xs font-bold text-warning uppercase mt-2">${o.code || translate("N/A")}</span>
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
                <p class="text-sm font-semibold">${Helpers.statusBadge(o.workflow_status)}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning">
                <span class="material-symbols-outlined">payments</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Currency")}</p>
                <p class="text-sm font-semibold text-foreground font-mono">${o.currency?.toUpperCase() || 'USD'}</p>
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

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning">
                <span class="material-symbols-outlined">person</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Salesperson")}</p>
                <p class="text-sm font-semibold text-foreground">${o.salesperson?.name || translate("Unattributed")}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_order_path(companyId, o.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm cursor-pointer">
              ${translate("Edit Order")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
