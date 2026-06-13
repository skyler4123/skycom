import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Employees_NewController extends Companies_LayoutController {
  /** @type {string | null} */
  categoryId = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  connect() {
    super.connect()

    this.categoryId = new URLSearchParams(window.location.search).get('category_id') || this.defaultFilterCategory()?.id || null

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.property_metadata || []

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  employeesCategories() {
    return currentCategories().filter(c => c.resource_name === "employees")
  }

  defaultFilterCategory() {
    return this.employeesCategories()[0]
  }

  renderField({ key, label, type }) {
    const baseClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500'

    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="employee[${key}]" value="false">
            <input type="checkbox" name="employee[${key}]" value="true"
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${label}</span>
          </div>
        `
      case 'integer':
      case 'decimal':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="number" name="employee[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" placeholder="${label}"
              class="${baseClass}">
          </div>
        `
      case 'datetime':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="datetime-local" name="employee[${key}]"
              class="${baseClass}">
          </div>
        `
      case 'text':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <textarea name="employee[${key}]" rows="3" placeholder="${label}"
              class="${baseClass}"></textarea>
          </div>
        `
      default:
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="text" name="employee[${key}]" placeholder="${label}"
              class="${baseClass}">
          </div>
        `
    }
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ''

    return `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Properties</h3>
        <div class="grid grid-cols-2 gap-4">
          ${this.propertyMetadata.map(f => this.renderField(f)).join('')}
        </div>
      </div>
    `
  }

  onCategoryChange(event) {
    this.categoryId = event.target.value

    const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryId)
    this.propertyMetadata = propertyMapping?.property_metadata || []

    const dynamicDiv = this.element.querySelector('#dynamic-fields')
    if (dynamicDiv) {
      dynamicDiv.innerHTML = this.dynamicFieldsHTML()
    }
  }

  contentHTML() {
    const categoryFilter = this.employeesCategories()
    const branchFilter = currentBranches()
    const typeOptions = (Enums()?.employee?.business_types || [
      { name: "Full Time", value: "full_time" },
      { name: "Part Time", value: "part_time" },
      { name: "Contractor", value: "contractor" },
      { name: "Intern", value: "intern" }
    ]).filter(t => t.value !== 'owner').map(t =>
      `<option value="${t.value}">${t.name}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Employee</h2>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Category</label>
          <select
            name="employee[category_id]"
            data-action="change->${this.identifier}#onCategoryChange"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none"
          >
            ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), this.categoryId)}
          </select>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Full Name</label>
            <input type="text" name="employee[name]" required placeholder="e.g. John Doe"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Employment Type</label>
            <select name="employee[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${typeOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Branch</label>
            <select name="employee[branch_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              <option value="">Select Branch</option>
              ${branchFilter.map(b => `<option value="${b.id}">${b.name}</option>`).join('')}
            </select>
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">Description</label>
            <textarea name="employee[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"></textarea>
          </div>
        </div>

        <div id="dynamic-fields">
          ${this.dynamicFieldsHTML()}
        </div>

        <div class="flex justify-end pt-6 border-t border-slate-200 dark:border-slate-700">
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            Save Employee
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        <div class="">
          ${form({
            action: Helpers.create_company_employees_path(currentCompany().id),
            method: "POST",
            attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
            html: fields
          })}
        </div>
      </div>
    `
  }
}
