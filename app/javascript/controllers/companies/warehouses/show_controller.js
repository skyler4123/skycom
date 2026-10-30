import Companies_LayoutController from "controllers/companies/layout_controller"

// Depends on BE: Companies::WarehousesController#show (JSON with warehouse + stocks)
// Docs: docs/STOCK.md
export default class Companies_Warehouses_ShowController extends Companies_LayoutController {
  /** @type {Warehouse | null} */
  warehouse = null

  /** @type {Array} */
  stocks = []

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_warehouse_path(companyId, recordId)}.json`)
      this.warehouse = response.warehouse
      this.stocks = response.stocks || []

      if (this.warehouse?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.warehouse.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load warehouse.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-muted-foreground/60">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-success/10 text-success ' : 'bg-background text-foreground '}">${value ? translate("True") : translate("False")}</span>`
      case 'integer':
        return `<span class="font-mono text-foreground">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-primary">${Number(value).toFixed(2)}</span>`
      case 'datetime': {
        const d = new Date(value)
        return `<span class="text-sm text-foreground">${d.toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-foreground">${value}</span>`
    }
  }

  showHTML() {
    const f = this.warehouse
    if (!f) return `<div class="p-8 text-center">${translate("Warehouse not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === f.category_id)
    const branch = f.branch

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-success ">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-muted-foreground">${field.name}</p>
                <p class="text-sm font-semibold text-foreground">${this.formatDisplayValue(f[field.key], field.type)}</p>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_warehouses_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Warehouses")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-warning/20 bg-warning/10 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-warning ">warehouse</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${f.name}</h2>
              <p class="font-semibold text-warning ">${f.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-warning/10 px-3 py-1 text-xs font-bold text-warning uppercase">${f.code || translate("N/A")}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning ">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Type")}</p>
                <p class="text-sm font-semibold text-foreground">${Helpers.capitalize(f.business_type?.replace('_', ' ') || '')}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning ">
                <span class="material-symbols-outlined">toggle_on</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Status")}</p>
                <p class="text-sm font-semibold">${Helpers.statusBadge(f.workflow_status)}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning ">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Category")}</p>
                <p class="text-sm font-semibold text-foreground">${category?.name || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning ">
                <span class="material-symbols-outlined">business</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Branch")}</p>
                <p class="text-sm font-semibold text-foreground">${branch?.name || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning ">
                <span class="material-symbols-outlined">phone</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Phone")}</p>
                <p class="text-sm font-semibold text-foreground">${f.phone_number || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-warning ">
                <span class="material-symbols-outlined">mail</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Email")}</p>
                <p class="text-sm font-semibold text-foreground">${f.email || translate("N/A")}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}

          <div class="mt-8 border-t border-line pt-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-bold text-foreground">${translate("Stocks in this warehouse")}</h3>
              <a href="${Helpers.company_stocks_path(companyId)}" class="text-sm font-medium text-primary hover:text-primary cursor-pointer">${translate("View all stocks")}</a>
            </div>
            ${this.stocks.length === 0 ? `<p class="text-sm text-muted-foreground">${translate("No stock yet.")}</p>` : `
              <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                  <thead>
                    <tr class="text-sm text-muted-foreground border-b border-line">
                      <th class="py-4 px-6 font-medium">${translate("Product")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Quantity")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Pending")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Available")}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-line">
                    ${this.stocks.map(s => `
                      <tr class="hover:bg-muted/50">
                        <td class="py-4 px-6 text-sm font-medium text-foreground">${s.product?.name || '—'}</td>
                        <td class="py-4 px-6 text-sm text-foreground font-medium">${s.quantity ?? 0}</td>
                        <td class="py-4 px-6 text-sm text-muted-foreground">${s.pending ?? 0}</td>
                        <td class="py-4 px-6 text-sm text-foreground font-medium">${s.available ?? 0}</td>
                      </tr>
                    `).join('')}
                  </tbody>
                </table>
              </div>
            `}
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_warehouse_path(companyId, f.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Warehouse")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
