import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Products_EditController extends Companies_LayoutController {
  /** @type {Product | null} */
  product = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  /** @type {Array<{id: string, name: string, rate_percent: number, inclusive: boolean}>} */
  taxCodes = []

  /** @type {any | null} */
  defaultTaxCode = null

  taxCodeError = false

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const productId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.edit_company_product_path(companyId, productId)}.json`)
      this.product = response.product
      this.taxCodes = response.tax_codes || []
      this.defaultTaxCode = response.default_tax_code || null

      if (this.product?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.product.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load product.")}</div>`
          return true
        }
        return false
      })
    }
  }

  taxCodeFieldHTML() {
    const p = this.product || {}
    if (this.taxCodeError) {
      return `
        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Tax")}</label>
          <p class="text-[11px] text-warning">${translate("Tax codes could not be loaded. The company default will apply.")}</p>
        </div>
      `
    }

    const defaultLabel = this.defaultTaxCode
      ? this.taxCodeLabel(this.defaultTaxCode)
      : translate("none configured")

    return `
      <div class="space-y-1">
        <label class="text-xs font-medium text-muted-foreground" for="product_tax_code_id">${translate("Tax")}</label>
        <select id="product_tax_code_id" name="product[tax_code_id]"
          class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
          <option value="">${translate("Use company default")} — ${escapeHtml(defaultLabel)}</option>
          ${this.taxCodes.map((code) => `
            <option value="${code.id}" ${code.id === p.tax_code_id ? "selected" : ""}>${escapeHtml(this.taxCodeLabel(code))}</option>
          `).join("")}
        </select>
        <p class="text-[11px] text-muted-foreground">${translate("Leave blank to use the company default. Tax is applied at checkout.")}</p>
      </div>
    `
  }

  taxCodeLabel(taxCode) {
    const rate = Number(taxCode.rate_percent || 0)
    const rateLabel = Number.isInteger(rate) ? String(rate) : rate.toFixed(2).replace(/0+$/, "").replace(/\.$/, "")
    return `${taxCode.name} (${rateLabel}%${taxCode.inclusive ? `, ${translate("included")}` : ""})`
  }

  contentHTML() {
    const p = this.product
    if (!p) return `<div class="p-8 text-center">${translate("Product not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = ENUMS?.product?.business_types || []
    const workflowStatuses = ENUMS?.product?.workflow_statuses || []

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-line pt-6 mt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = p[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="product[${field.key}]" value="false">
                  <input type="checkbox" name="product[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-line text-primary cursor-pointer">
                `
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="product[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="product[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="product[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
                break
              default:
                inputHTML = `<input type="text" name="product[${field.key}]" value="${value ?? ''}"
                  class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">`
            }
            return `
              <div>
                <label class="text-xs font-medium text-muted-foreground">${field.name}</label>
                ${inputHTML}
              </div>
            `
          }).join('')}
        </div>
      </div>
    ` : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("Edit Product")}</h2>
        <p class="text-sm text-muted-foreground">${p.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Name")}</label>
            <input type="text" name="product[name]" value="${p.name || ''}" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Description")}</label>
            <textarea name="product[description]" rows="2"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">${p.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Type")}</label>
            <select name="product[business_type]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${selectOptionsHTML(businessTypes, p.business_type || 'physical')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Status")}</label>
            <select name="product[workflow_status]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${selectOptionsHTML(workflowStatuses, p.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-muted-foreground">${translate("Category")}</label>
            <input type="text" value="${currentCategories().find(c => c.id === p.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-line rounded-lg bg-background text-sm text-muted-foreground">
            <input type="hidden" name="product[category_id]" value="${p.category_id}">
          </div>
        </div>

        ${this.taxCodeFieldHTML()}

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_product_path(companyId, p.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_product_path(companyId, p.id),
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
