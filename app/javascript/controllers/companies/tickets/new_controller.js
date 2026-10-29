import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Tickets_NewController extends Companies_LayoutController {
  // Ticket creation form — dynamic property fields + line-item rows
  // (TicketTicketItemAppointment nested attributes).
  // Depends on BE: Companies::TicketsController#new (reference lists) + #create
  // Endpoints: GET new_company_ticket_path.json, POST create_company_tickets_path
  // Docs: docs/PURCHASE_WORKFLOW.md
  static targets = ["itemRows"]

  /** @type {string | null} */
  categoryId = null

  /** @type {Array<{id: string, name: string, unit: string, estimated_unit_price: number}>} */
  ticketItems = []

  /** @type {Array<{id: string, name: string}>} */
  suppliers = []

  /** @type {Array<{ticket_item_id: string, quantity: number, unit_price: string}>} */
  itemRows = []

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    this.categoryId = new URLSearchParams(window.location.search).get('category_id') || this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    try {
      const response = await fetchJson(`${Helpers.new_company_ticket_path(currentCompany().id)}.json`)
      this.ticketItems = response.ticket_items || []
      this.suppliers = response.suppliers || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load ticket form data") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  ticketsCategories() {
    return currentCategories().filter(c => c.resource_name === "tickets")
  }

  defaultFilterCategory() {
    return this.ticketsCategories()[0]
  }

  renderField({ key, name, type }) {
    const baseClass = 'w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground'

    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="ticket[${key}]" value="false">
            <input type="checkbox" name="ticket[${key}]" value="true"
              class="h-5 w-5 rounded border-line text-primary cursor-pointer">
            <span class="text-sm text-foreground">${name}</span>
          </div>`
      case 'integer':
      case 'decimal':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${name}</label>
            <input type="number" name="ticket[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" placeholder="${name}" class="${baseClass}">
          </div>`
      case 'datetime':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${name}</label>
            <input type="datetime-local" name="ticket[${key}]" class="${baseClass}">
          </div>`
      default:
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${name}</label>
            <input type="text" name="ticket[${key}]" placeholder="${name}" class="${baseClass}">
          </div>`
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
      </div>`
  }

  onCategoryChange(event) {
    this.categoryId = event.target.value

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) dynamicDiv.innerHTML = this.dynamicFieldsHTML()
  }

  addItemRow() {
    this.itemRows.push({ ticket_item_id: "", quantity: 1, unit_price: "" })
    this.rerenderItemRows()
  }

  removeItemRow(event) {
    this.itemRows.splice(Number(event.params.index), 1)
    this.rerenderItemRows()
  }

  onItemChange(event) {
    const index = Number(event.params.index)
    const item = this.ticketItems.find(i => i.id === event.target.value)
    if (item && this.itemRows[index]) {
      this.itemRows[index].ticket_item_id = event.target.value
      this.itemRows[index].unit_price = item.estimated_unit_price ?? ""
      this.rerenderItemRows()
    }
  }

  itemOptions(selectedId) {
    return this.ticketItems.map(item =>
      `<option value="${item.id}" ${item.id === selectedId ? "selected" : ""}>${item.name}</option>`
    ).join('')
  }

  supplierOptions() {
    return [ { id: "", name: `— ${translate("None")} —` }, ...this.suppliers ]
      .map(s => `<option value="${s.id}">${s.name}</option>`).join('')
  }

  itemRowHTML(row, index) {
    const inputClass = 'w-full px-2 py-1.5 border border-line rounded-lg bg-card text-sm'
    return `
      <tr>
        <td class="py-2 px-2">
          <select name="ticket[ticket_ticket_item_appointments_attributes][${index}][ticket_item_id]" required
            data-action="change->${this.identifier}#onItemChange" data-${this.identifier}-index-param="${index}"
            class="${inputClass} cursor-pointer">
            <option value="">—</option>
            ${this.itemOptions(row.ticket_item_id)}
          </select>
        </td>
        <td class="py-2 px-2"><input type="number" min="1" step="1" name="ticket[ticket_ticket_item_appointments_attributes][${index}][quantity]" value="${row.quantity}" class="${inputClass}"></td>
        <td class="py-2 px-2"><input type="number" step="0.01" name="ticket[ticket_ticket_item_appointments_attributes][${index}][unit_price]" value="${row.unit_price}" class="${inputClass}"></td>
        <td class="py-2 px-2 text-right">
          <button type="button" data-action="click->${this.identifier}#removeItemRow" data-${this.identifier}-index-param="${index}"
            class="p-1.5 text-danger hover:bg-danger/10 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">delete</span>
          </button>
        </td>
      </tr>`
  }

  rerenderItemRows() {
    if (this.hasItemRowsTarget) this.itemRowsTarget.innerHTML = this.itemRows.map((row, i) => this.itemRowHTML(row, i)).join('')
  }

  itemsSectionHTML() {
    return `
      <div class="border-t border-line pt-6 mt-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-sm font-bold text-muted-foreground uppercase tracking-wider">${translate("Items")}</h3>
          <button type="button" data-action="click->${this.identifier}#addItemRow"
            class="inline-flex items-center gap-2 px-3 py-1.5 bg-muted text-foreground rounded-lg text-sm font-medium cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">add</span>${translate("Add Item")}
          </button>
        </div>
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-xs text-muted-foreground border-b border-line">
              <th class="py-2 px-2 font-medium">${translate("Item")}</th>
              <th class="py-2 px-2 font-medium">${translate("Quantity")}</th>
              <th class="py-2 px-2 font-medium">${translate("Unit Price")}</th>
              <th class="py-2 px-2"></th>
            </tr>
          </thead>
          <tbody data-${this.identifier}-target="itemRows"></tbody>
        </table>
      </div>`
  }

  contentHTML() {
    const categoryFilter = this.ticketsCategories()
    const businessTypes = ENUMS?.ticket?.business_types || [
      { name: "Office Supply", value: "office_supply" },
      { name: "Equipment", value: "equipment" },
      { name: "Service", value: "service" }
    ]
    const currencies = ENUMS?.ticket?.currencies || [ { name: "USD", value: "usd" } ]

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Ticket")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Category")}</label>
            <select name="ticket[category_id]" data-action="change->${this.identifier}#onCategoryChange"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="ticket[name]" required placeholder="${translate("e.g. Office supplies restock")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Type")}</label>
            <select name="ticket[business_type]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              ${businessTypes.map(t => `<option value="${t.value}">${t.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Currency")}</label>
            <select name="ticket[currency]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              ${currencies.map(c => `<option value="${c.value}">${c.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Needed By")}</label>
            <input type="datetime-local" name="ticket[needed_by]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Supplier")}</label>
            <select name="ticket[supplier_id]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              ${this.supplierOptions()}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="ticket[description]" rows="3"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"></textarea>
          </div>
        </div>

        ${this.itemsSectionHTML()}

        <div id="dynamic-fields">
          ${this.dynamicFieldsHTML()}
        </div>

        <div class="flex justify-end pt-6 border-t border-line">
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Ticket")}
          </button>
        </div>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_tickets_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>`
  }
}
