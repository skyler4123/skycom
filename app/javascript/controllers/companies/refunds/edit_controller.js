import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Refunds_EditController extends Companies_LayoutController {
  refund = null
  propertyMetadata = []
  customers = []

  async connect() {
    super.connect()

    const id = window.location.pathname.split('/').pop()
    try {
      const response = await fetchJson(`${Helpers.company_refund_path(currentCompany().id, id)}.json`)
      this.refund = response.refund || null
      this.customers = (await fetchJson(`${Helpers.new_company_refund_path(currentCompany().id)}.json`)).customers || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load refund") })
    }

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.refund?.category_id)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

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

  contentHTML() {
    const r = this.refund || {}
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
        <h2 class="text-xl font-bold text-foreground">${translate("Edit Refund")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Category")}</label>
            <select name="refund[category_id]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), r.category_id)}
            </select>
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="refund[name]" required value="${r.name || ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Type")}</label>
            <select name="refund[refund_type]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              ${refundTypes.map(t => `<option value="${t.value}" ${r.refund_type === t.value ? 'selected' : ''}>${t.name}</option>`).join('')}
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Currency")}</label>
            <select name="refund[currency]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              ${currencies.map(c => `<option value="${c.value}" ${r.currency === c.value ? 'selected' : ''}>${c.name}</option>`).join('')}
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Amount (cents)")}</label>
            <input type="number" name="refund[money_amount_cents]" value="${r.money_amount_cents || ''}" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Customer")}</label>
            <select name="refund[customer_id]" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
              <option value="">—</option>
              ${this.customers.map(c => `<option value="${c.id}" ${r.customer_id === c.id ? 'selected' : ''}>${c.name}</option>`).join('')}
            </select>
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Reason")}</label>
            <textarea name="refund[reason]" rows="3" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">${r.reason || ''}</textarea>
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="refund[description]" rows="3" class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">${r.description || ''}</textarea>
          </div>
        </div>
        <div class="flex justify-end pt-6 border-t border-line">
          <button type="submit" class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Update Refund")}
          </button>
        </div>
      </div>`

    const id = window.location.pathname.split('/').pop()
    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.company_refund_path(currentCompany().id, id),
            method: "PATCH",
            attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>`
  }
}