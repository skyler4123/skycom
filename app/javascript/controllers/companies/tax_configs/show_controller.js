// Depends on BE: Companies::TaxConfigsController#show + #update
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TaxConfigs_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  taxConfig = null

  async connect() {
    super.connect()

    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_tax_config_path(companyId)}.json`)
      this.taxConfig = response.tax_config
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to load tax config" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  async saveConfig(event) {
    event.preventDefault()
    const companyId = window.location.pathname.split("/")[2]
    const form = event.target
    const data = new FormData(form)
    const payload = {
      tax_config: {
        date_basis: data.get("date_basis"),
        include_invoices: data.get("include_invoices") === "on",
        include_purchases: data.get("include_purchases") === "on",
        include_stock_exports: data.get("include_stock_exports") === "on",
        excluded_invoice_statuses: (data.get("excluded_invoice_statuses") || "").split(",").map(s => s.trim()).filter(Boolean),
        excluded_purchase_statuses: (data.get("excluded_purchase_statuses") || "").split(",").map(s => s.trim()).filter(Boolean),
        stock_export_business_types: (data.get("stock_export_business_types") || "").split(",").map(s => s.trim()).filter(Boolean),
        branch_ids: (data.get("branch_ids") || "").split(",").map(s => s.trim()).filter(Boolean)
      }
    }
    try {
      await fetchJson(`${Helpers.company_tax_config_path(companyId)}`, {
        method: "PATCH",
        body: payload
      })
      reloadThenToast({ type: "success", message: "Tax config updated" })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to update tax config" })
    }
  }

  contentHTML() {
    const cfg = this.taxConfig || {}
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line max-w-2xl">
          <h2 class="text-xl font-bold text-foreground mb-4">Tax Config</h2>
          <form data-action="submit->${this.identifier}#saveConfig" class="space-y-4">
            <div>
              <label class="text-xs text-muted-foreground uppercase">Date Basis</label>
              <select name="date_basis" class="w-full px-3 py-2 border rounded-lg text-sm">
                <option value="created_at" ${cfg.date_basis === "created_at" ? "selected" : ""}>Created At</option>
                <option value="updated_at" ${cfg.date_basis === "updated_at" ? "selected" : ""}>Updated At</option>
              </select>
            </div>
            <label class="flex items-center gap-2 text-sm"><input type="checkbox" name="include_invoices" ${cfg.include_invoices ? "checked" : ""} /> Include invoices</label>
            <label class="flex items-center gap-2 text-sm"><input type="checkbox" name="include_purchases" ${cfg.include_purchases ? "checked" : ""} /> Include purchases</label>
            <label class="flex items-center gap-2 text-sm"><input type="checkbox" name="include_stock_exports" ${cfg.include_stock_exports ? "checked" : ""} /> Include stock exports</label>
            <div>
              <label class="text-xs text-muted-foreground uppercase">Excluded invoice statuses (comma-separated)</label>
              <input type="text" name="excluded_invoice_statuses" value="${(cfg.excluded_invoice_statuses || []).join(", ")}" class="w-full px-3 py-2 border rounded-lg text-sm" />
            </div>
            <div>
              <label class="text-xs text-muted-foreground uppercase">Excluded purchase statuses (comma-separated)</label>
              <input type="text" name="excluded_purchase_statuses" value="${(cfg.excluded_purchase_statuses || []).join(", ")}" class="w-full px-3 py-2 border rounded-lg text-sm" />
            </div>
            <div>
              <label class="text-xs text-muted-foreground uppercase">Stock export business types (comma-separated)</label>
              <input type="text" name="stock_export_business_types" value="${(cfg.stock_export_business_types || []).join(", ")}" class="w-full px-3 py-2 border rounded-lg text-sm" />
            </div>
            <div>
              <label class="text-xs text-muted-foreground uppercase">Branch IDs (comma-separated, blank = all)</label>
              <input type="text" name="branch_ids" value="${(cfg.branch_ids || []).join(", ")}" class="w-full px-3 py-2 border rounded-lg text-sm" />
            </div>
            <button type="submit" class="px-4 py-2 bg-primary text-primary-foreground rounded-lg text-sm">Save Config</button>
          </form>
        </div>
      </div>
    `
  }
}
