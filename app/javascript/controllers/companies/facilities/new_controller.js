import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Facilities_NewController extends Companies_LayoutController {
  /** @type {string | null} */
  categoryId = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  connect() {
    super.connect()

    this.categoryId = new URLSearchParams(window.location.search).get('category_id') || this.defaultFilterCategory()?.id || null

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

  facilitiesCategories() {
    return currentCategories().filter(c => c.resource_name === "facilities")
  }

  defaultFilterCategory() {
    return this.facilitiesCategories()[0]
  }

  renderField({ key, label, type }) {
    const baseClass = 'w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground'

    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="facility[${key}]" value="false">
            <input type="checkbox" name="facility[${key}]" value="true"
              class="h-5 w-5 rounded border-line text-primary cursor-pointer">
            <span class="text-sm text-foreground">${label}</span>
          </div>
        `
      case 'integer':
      case 'decimal':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${label}</label>
            <input type="number" name="facility[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" placeholder="${label}"
              class="${baseClass}">
          </div>
        `
      case 'datetime':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${label}</label>
            <input type="datetime-local" name="facility[${key}]"
              class="${baseClass}">
          </div>
        `
      default:
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${label}</label>
            <input type="text" name="facility[${key}]" placeholder="${label}"
              class="${baseClass}">
          </div>
        `
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

  onCategoryChange(event) {
    this.categoryId = event.target.value

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.metadata?.properties || []

    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) {
      dynamicDiv.innerHTML = this.dynamicFieldsHTML()
    }
  }

  contentHTML() {
    const categoryFilter = this.facilitiesCategories()
    const branchFilter = currentBranches()
    const typeOptions = (ENUMS?.facility?.business_types || []).map(t =>
      `<option value="${t.value}">${t.name}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Facility")}</h2>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Category")}</label>
          <select
            name="facility[category_id]"
            data-action="change->${this.identifier}#onCategoryChange"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none"
          >
            ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
          </select>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Facility Name")}</label>
            <input type="text" name="facility[name]" required placeholder="${translate("e.g. Retail Floor")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Branch")}</label>
            <select name="facility[branch_id]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              <option value="">${translate("Select Branch")}</option>
              ${branchFilter.map(b => `<option value="${b.id}">${b.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Type")}</label>
            <select name="facility[business_type]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${typeOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Phone Number")}</label>
            <input type="text" name="facility[phone_number]" placeholder="${translate("e.g. +84 123 456 789")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Email")}</label>
            <input type="email" name="facility[email]" placeholder="${translate("facility@example.com")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="facility[description]" rows="3"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"></textarea>
          </div>
        </div>

        <div id="dynamic-fields">
          ${this.dynamicFieldsHTML()}
        </div>

        <div class="flex justify-end pt-6 border-t border-line">
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Facility")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_facilities_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>
    `
  }
}
