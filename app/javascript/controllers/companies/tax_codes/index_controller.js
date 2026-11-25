import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_TaxCodes_NewModalController from "controllers/companies/tax_codes/new_modal_controller"
import Companies_TaxCodes_EditModalController from "controllers/companies/tax_codes/edit_modal_controller"

// Tax codes — owner-only company catalog used by products, services, and POS.
// Depends on BE: Companies::TaxCodesController#index/create/update/destroy
// Endpoints: GET /companies/:company_id/tax_codes.json,
//            POST/PATCH/DELETE /companies/:company_id/tax_codes
// Docs: docs/superpowers/specs/2026-11-25-per-resource-tax-design.md
export default class Companies_TaxCodes_IndexController extends Companies_LayoutController {
  /** @type {any[]} */
  taxCodes = []

  loaded = false

  connect() {
    super.connect()

    poll(() => {
      if (currentCompany()) {
        this.loadData()
        return true
      }
      return false
    })
  }

  async loadData() {
    try {
      const response = await fetchJson(`${Helpers.company_tax_codes_path(currentCompany().id)}.json`)
      this.taxCodes = response.tax_codes || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load tax codes") })
    }

    this.loaded = true
    if (this.hasContentTarget) this.renderContent()
  }

  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_TaxCodes_NewModalController)}"></div>` })
  }

  openEditModal(event) {
    const taxCode = this.taxCodes.find((candidate) => candidate.id === event.currentTarget.dataset.taxCodeId)
    if (!taxCode) return

    window.currentTaxCode = taxCode
    openModal({ html: `<div data-controller="${identifier(Companies_TaxCodes_EditModalController)}"></div>` })
  }

  discardTaxCode(event) {
    const taxCode = this.taxCodes.find((candidate) => candidate.id === event.currentTarget.dataset.taxCodeId)
    if (!taxCode) return

    Helpers.confirmAction({
      title: translate("Discard tax code?"),
      text: translate("Products and services using this code will fall back to the company default. Past sales keep their snapshot."),
      confirmButtonText: translate("Discard"),
      cancelButtonText: translate("Cancel")
    }).then(async (result) => {
      if (!result.isConfirmed) return

      try {
        const response = await fetchJson(Helpers.company_tax_code_path(currentCompany().id, taxCode.id), {
          method: "DELETE"
        })
        reloadThenToast({ type: "success", message: response.message })
      } catch (error) {
        toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to discard tax code") })
      }
    })
  }

  contentHTML() {
    if (!this.loaded) {
      return `<div class="p-8 text-center text-muted-foreground">${translate("Loading tax codes…")}</div>`
    }

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between mb-6">
            <div>
              <h2 class="text-xl font-bold text-foreground">${translate("Tax Codes")}</h2>
              <p class="text-sm text-muted-foreground mt-1">${translate("Rates used by products and services at checkout. Tax Config owns the default.")}</p>
            </div>
            ${this.taxCodes.length ? `
              <button type="button" data-action="click->${this.identifier}#openNewModal"
                class="inline-flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("Add tax code")}
              </button>
            ` : ""}
          </div>

          ${this.taxCodes.length ? this.tableHTML() : this.emptyHTML()}
        </div>
      </div>
    `
  }

  tableHTML() {
    return `
      <div class="overflow-x-auto border border-line rounded-xl">
        <table class="w-full text-sm">
          <thead class="bg-muted/50 text-muted-foreground">
            <tr>
              <th class="text-left font-semibold px-4 py-3">${translate("Name")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Code")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Rate")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Price treatment")}</th>
              <th class="text-left font-semibold px-4 py-3">${translate("Used by")}</th>
              <th class="text-right font-semibold px-4 py-3">${translate("Actions")}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-line">
            ${this.taxCodes.map((taxCode) => this.rowHTML(taxCode)).join("")}
          </tbody>
        </table>
      </div>
    `
  }

  rowHTML(taxCode) {
    return `
      <tr>
        <td class="px-4 py-3">
          <p class="font-medium text-foreground">${escapeHtml(taxCode.name)}</p>
          ${taxCode.description ? `<p class="text-xs text-muted-foreground mt-0.5">${escapeHtml(taxCode.description)}</p>` : ""}
        </td>
        <td class="px-4 py-3 font-mono text-xs text-muted-foreground">${escapeHtml(taxCode.code)}</td>
        <td class="px-4 py-3 font-mono text-foreground">${this.rateLabel(taxCode)}%</td>
        <td class="px-4 py-3">
          <span class="inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${taxCode.inclusive ? "bg-info/10 text-info" : "bg-muted text-foreground"}">
            ${translate(taxCode.inclusive ? "Included in price" : "Added on top")}
          </span>
        </td>
        <td class="px-4 py-3 text-muted-foreground">${this.usageLabel(taxCode)}</td>
        <td class="px-4 py-3 text-right whitespace-nowrap">
          <button type="button" data-action="click->${this.identifier}#openEditModal"
            data-tax-code-id="${taxCode.id}" ${tooltip("Edit tax code")}
            class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg">
            <span class="material-symbols-outlined text-[20px]">edit</span>
          </button>
          <button type="button" data-action="click->${this.identifier}#discardTaxCode"
            data-tax-code-id="${taxCode.id}" ${tooltip("Discard tax code")}
            class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-danger hover:bg-danger/10 rounded-lg">
            <span class="material-symbols-outlined text-[20px]">delete</span>
          </button>
        </td>
      </tr>
    `
  }

  emptyHTML() {
    return `
      <div class="text-center py-12 border border-line rounded-xl">
        <span class="material-symbols-outlined text-[40px] text-muted-foreground/60">percent</span>
        <p class="text-sm font-medium text-foreground mt-3">${translate("No tax codes yet")}</p>
        <p class="text-sm text-muted-foreground mt-1">${translate("Add the rates you charge, then assign them to products and services or set a default.")}</p>
        <button type="button" data-action="click->${this.identifier}#openNewModal"
          class="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm">
          <span class="material-symbols-outlined text-[20px]">add</span>
          ${translate("Add tax code")}
        </button>
      </div>
    `
  }

  rateLabel(taxCode) {
    const rate = Number(taxCode.rate_percent || 0)
    return Number.isInteger(rate) ? String(rate) : rate.toFixed(2).replace(/0+$/, "").replace(/\.$/, "")
  }

  usageLabel(taxCode) {
    const products = Number(taxCode.products_count || 0)
    const services = Number(taxCode.services_count || 0)
    return `${products} ${translate("Products")} · ${services} ${translate("Services")}`
  }
}
