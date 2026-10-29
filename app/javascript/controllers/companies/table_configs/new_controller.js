import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_TableConfigs_NewController extends Companies_LayoutController {
  connect() {
    super.connect()

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const categories = currentCategories() || []
    const categoryOptions = categories.map(c =>
      `<option value="${c.id}">${c.name}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Table Config")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="table_config[name]" required
              placeholder="e.g. Cosmetics Table Config"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Category")}</label>
            <select name="table_config[category_id]" data-action="change->${this.identifier}#onCategoryChange"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${categoryOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Property Mapping")}</label>
            <select name="table_config[property_mapping_id]" id="property-mapping-select"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${currentPropertyMappings().map(pm => `<option value="${pm.id}">${pm.name}</option>`).join('')}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="table_config[description]" rows="3"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"></textarea>
          </div>
        </div>

        <div class="flex justify-end pt-6 border-t border-line">
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Table Config")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_table_configs_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }

  onCategoryChange(event) {
    const categoryId = event.target.value
    const pmSelect = document.getElementById('property-mapping-select')
    if (!pmSelect) return

    const filtered = currentPropertyMappings().filter(pm => pm.category_id === categoryId)
    pmSelect.innerHTML = filtered.map(pm =>
      `<option value="${pm.id}">${pm.name}</option>`
    ).join('')
  }
}
