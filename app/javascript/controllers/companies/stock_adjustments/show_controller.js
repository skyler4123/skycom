import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StockAdjustments_ShowController extends Companies_LayoutController {
  // Stock import detail — read-only document view with lines + ledger tables.
  // One-shot docs land received on create, so there are no workflow buttons.
  // Depends on BE: Companies::StockAdjustmentsController#show (lines + ledger)
  // Endpoints: GET company_stock_adjustment_path.json
  // Docs: docs/STOCK.md §4.2
  /** @type {any | null} */
  stockImport = null

  /** @type {Array<{key: string, name: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_stock_adjustment_path(companyId, recordId)}.json`)
      this.stockAdjustment = response.stock_adjustment

      if (this.stockAdjustment?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.stockAdjustment.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load stock adjustment.")}</div>`
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
    if (value === null || value === undefined) return '<span class="text-slate-300 dark:text-slate-700">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-slate-50 text-slate-700 dark:bg-slate-800 dark:text-slate-400'}">${value ? translate("True") : translate("False")}</span>`
      case 'integer':
        return `<span class="font-mono text-slate-900 dark:text-slate-100">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-blue-600 dark:text-blue-400">${Number(value).toFixed(2)}</span>`
      case 'datetime': {
        return `<span class="text-sm text-slate-900 dark:text-white">${new Date(value).toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-slate-900 dark:text-white">${value}</span>`
    }
  }

  showHTML() {
    const doc = this.stockAdjustment
    if (!doc) return `<div class="p-8 text-center">${translate("Stock adjustment not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === doc.category_id)

    const linesTable = `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Lines")}</h3>
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-xs text-slate-500 border-b border-slate-200 dark:border-slate-700">
              <th class="py-2 px-2 font-medium">${translate("Product")}</th>
              <th class="py-2 px-2 font-medium">${translate("Warehouse")}</th>
              <th class="py-2 px-2 text-right font-medium">${translate("Quantity")}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
            ${(doc.lines || []).map(l => `
              <tr>
                <td class="py-2 px-2 text-sm text-slate-900 dark:text-white">${l.product_name || "—"}</td>
                <td class="py-2 px-2 text-sm text-slate-600 dark:text-slate-300">${l.warehouse_name || "—"}</td>
                <td class="py-2 px-2 text-sm text-right font-mono">${l.quantity ?? "—"}</td>
              </tr>`).join('')}
          </tbody>
        </table>
      </div>`

    const ledgerTable = (doc.ledger || []).length ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Ledger")}</h3>
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-xs text-slate-500 border-b border-slate-200 dark:border-slate-700">
              <th class="py-2 px-2 font-medium">${translate("Direction")}</th>
              <th class="py-2 px-2 font-medium">${translate("Type")}</th>
              <th class="py-2 px-2 text-right font-medium">${translate("Quantity")}</th>
              <th class="py-2 px-2 text-right font-medium">${translate("At")}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
            ${doc.ledger.map(t => `
              <tr>
                <td class="py-2 px-2 text-sm capitalize">${t.direction || "—"}</td>
                <td class="py-2 px-2 text-sm capitalize">${t.transaction_type || "—"}</td>
                <td class="py-2 px-2 text-sm text-right font-mono">${t.quantity ?? "—"}</td>
                <td class="py-2 px-2 text-sm text-right text-slate-500">${t.created_at ? new Date(t.created_at).toLocaleString() : "—"}</td>
              </tr>`).join('')}
          </tbody>
        </table>
      </div>` : ""

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${field.name}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${this.formatDisplayValue(doc[field.key], field.type)}</p>
              </div>
            </div>`).join('')}
        </div>
      </div>` : ""

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_stock_adjustments_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Stock Adjustments")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-emerald-100 dark:bg-gray-800 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-emerald-600 dark:text-emerald-400">input</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${doc.name || translate("Unnamed Stock Adjustment")}</h2>
              <p class="font-semibold text-emerald-600 dark:text-emerald-400">${doc.description || ''}</p>
              <div class="mt-2 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-emerald-100 dark:bg-emerald-900/40 px-3 py-1 text-xs font-bold text-emerald-700 dark:text-emerald-300 uppercase">${doc.code || "N/A"}</span>
                ${Helpers.statusBadge(doc.workflow_status)}
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined">warehouse</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Warehouse")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${doc.warehouse_name || "N/A"}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Category")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${category?.name || doc.category_name || "N/A"}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined">inventory_2</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Quantity")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${doc.quantity ?? 0}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined">swap_vert</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Direction")}</p>
                <p class="text-sm font-semibold capitalize text-slate-900 dark:text-white">${doc.direction || "N/A"}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined">notes</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${translate("Reason")}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${doc.reason || "N/A"}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}
          ${linesTable}
          ${ledgerTable}
        </div>
      </div>`
  }
}
