import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Orders_NewController extends Companies_LayoutController {
  /** @type {string | null} */
  categoryId = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  /** @type {{ id: string, name: string }[]} */
  employees = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${Helpers.new_company_order_path(currentCompany().id)}.json`)
      this.employees = response.employees || []
    } catch (error) {
      this.employees = []
    }

    this.categoryId = new URLSearchParams(window.location.search).get('category_id')
      || this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  ordersCategories() {
    return currentCategories().filter(c => c.resource_name === "orders")
  }

  defaultFilterCategory() {
    return this.ordersCategories()[0]
  }

  onCategoryChange(event) {
    this.categoryId = event.target.value
    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []
    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) {
      dynamicDiv.innerHTML = this.dynamicFieldsHTML()
    }
  }

  renderField({ key, label, type }) {
    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="order[${key}]" value="false">
            <input type="checkbox" name="order[${key}]" value="true"
              class="h-5 w-5 rounded border-line text-primary cursor-pointer">
            <span class="text-sm text-foreground">${label}</span>
          </div>
        `
      case 'integer':
        return `<input type="number" step="1" name="order[${key}]" placeholder="${label}"
          class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">`
      case 'decimal':
        return `<input type="number" step="0.01" name="order[${key}]" placeholder="${label}"
          class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">`
      case 'datetime':
        return `<input type="datetime-local" name="order[${key}]"
          class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">`
      default:
        return `<input type="text" name="order[${key}]" placeholder="${label}"
          class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">`
    }
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ''
    return `
      <div class="border-t border-line pt-6">
        <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-2 gap-4">
          ${this.propertyMetadata.map(f => this.renderField(f)).join('')}
        </div>
      </div>
    `
  }

  contentHTML() {
    const categoryFilter = this.ordersCategories()

    const typeOptions = (ENUMS?.order?.business_types || []).map(t =>
      `<option value="${t.value}">${t.name === 'in_store' ? translate("In Store") : (t.name ? t.name.charAt(0).toUpperCase() + t.name.slice(1) : t.value)}</option>`
    ).join('')

    const currencyOptions = (ENUMS?.order?.currencies || []).map(c =>
      `<option value="${c.value}">${c.name?.toUpperCase() || c.value?.toUpperCase()}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Order")}</h2>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Category")}</label>
          <select name="order[category_id]" data-action="change->${this.identifier}#onCategoryChange"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
            ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
          </select>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Name")}</label>
            <input type="text" name="order[name]" required placeholder="${translate("e.g. Order #12345")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Type")}</label>
            <select name="order[business_type]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${typeOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Currency")}</label>
            <select name="order[currency]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              ${currencyOptions}
            </select>
          </div>

          ${this.employees.length ? `
            <div class="space-y-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Salesperson")}</label>
              <select name="order[salesperson_id]"
                class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
                <option value="">${translate("Unattributed")}</option>
                ${this.employees.map(employee => `
                  <option value="${employee.id}" ${employee.id === currentEmployeeId() ? "selected" : ""}>${employee.name}</option>
                `).join("")}
              </select>
            </div>
          ` : ""}

          <div class="col-span-2 space-y-1">
            <input type="hidden" name="order[customer_id]" value="">

            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Code")}</label>
            <input type="text" name="order[code]" placeholder="${translate("e.g. ORD-001")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Description")}</label>
            <textarea name="order[description]" rows="3"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm"></textarea>
          </div>
        </div>

        <div id="dynamic-fields">${this.dynamicFieldsHTML()}</div>

        <div class="flex justify-end pt-6 border-t border-line">
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Order")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_orders_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
