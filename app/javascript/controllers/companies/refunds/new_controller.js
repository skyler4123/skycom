import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Refunds_NewController extends Companies_LayoutController {
  categoryId = null
  propertyMetadata = []

  customers = []
  categories = []

  async connect() {
    super.connect()

    this.categoryId = new URLSearchParams(window.location.search).get('category_id') || this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    try {
      const response = await fetchJson(`${Helpers.new_company_refund_path(currentCompany().id)}.json`)
      this.customers = response.customers || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load refund form data") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  refundsCategories() {
    return currentCategories().filter(c => c.resource_name === "refunds")
  }

  defaultFilterCategory() {
    return this.refundsCategories()[0]
  }

  renderField({ key, name, type }) {
    const baseClass = 'w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground'
    switch (type) {
      case 'boolean':
        return `<div class="flex items-center gap-3 py-2"><input type="hidden" name="refund[${key}]" value="false"><input type="checkbox" name="refund[${key}]" value="true" class="h-5 w-5 rounded border-line text-primary cursor-pointer"><span class="text-sm text-foreground">${name}</span></div>`
      case 'integer':
      case 'decimal':
        return `<div class="space-y-1"><label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${name}</label><input type="number" name="refund[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" placeholder="${name}" class="${baseClass}"></div>`
      case 'datetime':
        return `<div class="space-y-1"><label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${name}</label><input type="datetime-local" name="refund[${key}]" class="${baseClass}"></div>`
      default:
        return `<div class="space-y-1"><label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${name}</label><input type="text" name="refund[${key}]" placeholder="${name}" class="${baseClass}"></div>`
    }
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ''
    return `<div class="border-t border-line pt-6"><h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3><div class="grid grid-cols-2 gap-4">${this.propertyMetadata.map(f => this.renderField(f)).join('')}</div></div>`
  }

  onCategoryChange(event) {
    this.categoryId = event.target.value
    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []
    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) dynamicDiv.innerHTML = this.dynamicFieldsHTML()
  }

  contentHTML() {
    const categoryFilter = this.refundsCategories()
    const refundTypes = [
      { name: "Cash", value: "cash" },
      { name: "Product", value: "product" },
      { name: "Service", value: "service" },
      { name: "Credit", value: "credit" }
    ]
    const currencies = ENUMS?.refund?.currencies || [{ name: "USD", value: "usd" }]

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Refund")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <div class="flex items-center justify-between">
              <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Category")}</label>
              ${newCategoryLink(currentCompany().id, "refunds")}
            </div>
            <select name="refund[category_id]" data-action="change->${this.identifier}#onCategoryChange"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="refund[name]" required placeholder="${translate("e.g. Customer refund")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Type")}</label>
            <select name="refund[refund_type]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              ${refundTypes.map(t => `<option value="${t.value}">${t.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Currency")}</label>
            <select name="refund[currency]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              ${currencies.map(c => `<option value="${c.value}">${c.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Amount (cents)")}</label>
            <input type="number" name="refund[money_amount_cents]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Customer")}</label>
            <select name="refund[customer_id]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              <option value="">—</option>
              ${this.customers.map(c => `<option value="${c.id}">${c.name}</option>`).join('')}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Reason")}</label>
            <textarea name="refund[reason]" rows="3" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"></textarea>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="refund[description]" rows="3" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"></textarea>
          </div>
        </div>

        <div id="dynamic-fields">${this.dynamicFieldsHTML()}</div>

        <div class="flex justify-end pt-6 border-t border-line">
          <button type="submit" class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Refund")}
          </button>
        </div>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_refunds_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>`
  }

  handleSubmit(event) {
    // default form submission handled by global? keep minimal
  }
}