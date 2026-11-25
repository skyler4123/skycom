// Depends on BE: Companies::TaxConfigsController#show + #update + Companies::TaxCodesController#index
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TaxConfigs_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  taxConfig = null

  /** @type {any[]} */
  taxCodes = []

  async connect() {
    super.connect()

    const companyId = window.location.pathname.split("/")[2]

    try {
      const [ configResponse, codesResponse ] = await Promise.all([
        fetchJson(`${Helpers.company_tax_config_path(companyId)}.json`),
        fetchJson(`${Helpers.company_tax_codes_path(companyId)}.json`)
      ])
      this.taxConfig = configResponse.tax_config
      this.taxCodes = codesResponse.tax_codes || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load tax config") })
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
    const data = new FormData(event.target)
    const payload = {
      tax_config: {
        date_basis: data.get("date_basis"),
        include_invoices: data.get("include_invoices") === "on",
        include_purchases: data.get("include_purchases") === "on",
        include_stock_exports: data.get("include_stock_exports") === "on",
        excluded_invoice_statuses: (data.get("excluded_invoice_statuses") || "").split(",").map(s => s.trim()).filter(Boolean),
        excluded_purchase_statuses: (data.get("excluded_purchase_statuses") || "").split(",").map(s => s.trim()).filter(Boolean),
        stock_export_business_types: (data.get("stock_export_business_types") || "").split(",").map(s => s.trim()).filter(Boolean),
        branch_ids: (data.get("branch_ids") || "").split(",").map(s => s.trim()).filter(Boolean),
        default_tax_code_id: data.get("default_tax_code_id") || null
      }
    }

    try {
      await fetchJson(`${Helpers.company_tax_config_path(companyId)}`, {
        method: "PATCH",
        body: payload
      })
      reloadThenToast({ type: "success", message: "Tax config updated" })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update tax config") })
    }
  }

  contentHTML() {
    const companyId = window.location.pathname.split("/")[2]
    const cfg = this.taxConfig || {}
    const hasCodes = this.taxCodes.length > 0
    const defaultCode = cfg.default_tax_code

    const defaultOptions = this.taxCodes.map((code) => `
      <option value="${code.id}" ${code.id === cfg.default_tax_code_id ? "selected" : ""}>
        ${escapeHtml(code.name)} (${this.rateLabel(code)}%${code.inclusive ? `, ${translate("included")}` : ""})
      </option>
    `).join("")

    const fields = `
      <div class="space-y-5">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Tax Config")}</h2>
          <p class="text-sm text-muted-foreground mt-1">${translate("The default tax rate and the sources used by Tax Data.")}</p>
        </div>

        <div class="p-4 bg-muted border border-line rounded-xl space-y-3">
          <div>
            <h3 class="text-sm font-bold text-foreground">${translate("Default tax code")}</h3>
            <p class="text-[11px] text-muted-foreground mt-1">${translate("Used when a product or service has no tax code of its own. Each item can override it.")}</p>
          </div>

          ${hasCodes ? `
            <div>
              <label class="text-xs text-muted-foreground uppercase" for="default_tax_code_id">${translate("Default tax code")}</label>
              <select id="default_tax_code_id" name="default_tax_code_id"
                class="w-full px-3 py-2 border border-line rounded-lg text-sm bg-card text-foreground">
                <option value="">${translate("No default — unassigned items are sold untaxed")}</option>
                ${defaultOptions}
              </select>
              ${defaultCode ? `
                <p class="text-[11px] text-muted-foreground mt-1">
                  ${translate("Unassigned items use")}: ${escapeHtml(defaultCode.name)} (${this.rateLabel(defaultCode)}%${defaultCode.inclusive ? `, ${translate("included")}` : ""}).
                </p>
              ` : `
                <p class="text-[11px] text-warning mt-1">${translate("No default is set. Products and services without their own code will be sold untaxed.")}</p>
              `}
            </div>
          ` : `
            <div class="text-sm text-muted-foreground">
              <p>${translate("No tax codes yet. Add your first rate, then choose it here as the default.")}</p>
              <a href="${Helpers.company_tax_codes_path(companyId)}"
                class="inline-flex items-center gap-1 mt-2 text-primary font-semibold hover:underline">
                <span class="material-symbols-outlined text-[16px]">add</span>
                ${translate("Add tax code")}
              </a>
            </div>
          `}

          <a href="${Helpers.company_tax_codes_path(companyId)}"
            class="inline-flex items-center gap-1 text-sm text-primary font-semibold hover:underline">
            <span class="material-symbols-outlined text-[16px]">percent</span>
            ${translate("Manage tax codes")}
          </a>
        </div>

        <div>
          <label class="text-xs text-muted-foreground uppercase">${translate("Date Basis")}</label>
          <select name="date_basis" class="w-full px-3 py-2 border border-line rounded-lg text-sm bg-card text-foreground">
            <option value="created_at" ${cfg.date_basis === "created_at" ? "selected" : ""}>${translate("Created At")}</option>
            <option value="updated_at" ${cfg.date_basis === "updated_at" ? "selected" : ""}>${translate("Updated At")}</option>
          </select>
        </div>

        <label class="flex items-center gap-2 text-sm text-foreground"><input type="checkbox" name="include_invoices" ${cfg.include_invoices ? "checked" : ""} /> ${translate("Include invoices")}</label>
        <label class="flex items-center gap-2 text-sm text-foreground"><input type="checkbox" name="include_purchases" ${cfg.include_purchases ? "checked" : ""} /> ${translate("Include purchases")}</label>
        <label class="flex items-center gap-2 text-sm text-foreground"><input type="checkbox" name="include_stock_exports" ${cfg.include_stock_exports ? "checked" : ""} /> ${translate("Include stock exports")}</label>

        <div>
          <label class="text-xs text-muted-foreground uppercase">${translate("Excluded invoice statuses (comma-separated)")}</label>
          <input type="text" name="excluded_invoice_statuses" value="${(cfg.excluded_invoice_statuses || []).join(", ")}" class="w-full px-3 py-2 border border-line rounded-lg text-sm bg-card text-foreground" />
        </div>
        <div>
          <label class="text-xs text-muted-foreground uppercase">${translate("Excluded purchase statuses (comma-separated)")}</label>
          <input type="text" name="excluded_purchase_statuses" value="${(cfg.excluded_purchase_statuses || []).join(", ")}" class="w-full px-3 py-2 border border-line rounded-lg text-sm bg-card text-foreground" />
        </div>
        <div>
          <label class="text-xs text-muted-foreground uppercase">${translate("Stock export business types (comma-separated)")}</label>
          <input type="text" name="stock_export_business_types" value="${(cfg.stock_export_business_types || []).join(", ")}" class="w-full px-3 py-2 border border-line rounded-lg text-sm bg-card text-foreground" />
        </div>
        <div>
          <label class="text-xs text-muted-foreground uppercase">${translate("Branch IDs (comma-separated, blank = all)")}</label>
          <input type="text" name="branch_ids" value="${(cfg.branch_ids || []).join(", ")}" class="w-full px-3 py-2 border border-line rounded-lg text-sm bg-card text-foreground" />
        </div>

        <button type="submit" class="px-4 py-2 bg-primary text-primary-foreground rounded-lg text-sm font-semibold">${translate("Save Config")}</button>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          ${form({
            method: "PATCH",
            attributes: `data-action="submit->${this.identifier}#saveConfig" class="space-y-4"`,
            html: fields
          })}
        </div>
      </div>
    `
  }

  rateLabel(taxCode) {
    const rate = Number(taxCode.rate_percent || 0)
    return Number.isInteger(rate) ? String(rate) : rate.toFixed(2).replace(/0+$/, "").replace(/\.$/, "")
  }
}
