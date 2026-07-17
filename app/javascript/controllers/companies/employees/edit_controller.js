import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Employees_EditController extends Companies_LayoutController {
  /** @type {Employee | null} */
  employee = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/")[4]
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_employee_path(companyId, recordId)}.json`)
      this.employee = response.employee

      if (this.employee?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.employee.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load employee.")}</div>`
          return true
        }
        return false
      })
    }
  }

  renderField({ key, label, type, value }) {
    const baseClass = 'w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500'

    switch (type) {
      case 'boolean':
        return `
          <div class="flex items-center gap-3 py-2">
            <input type="hidden" name="employee[${key}]" value="false">
            <input type="checkbox" name="employee[${key}]" value="true" ${value ? 'checked' : ''}
              class="h-5 w-5 rounded border-slate-300 text-blue-600 cursor-pointer">
            <span class="text-sm text-slate-900 dark:text-white">${label}</span>
          </div>
        `
      case 'integer':
      case 'decimal':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="number" name="employee[${key}]" step="${type === 'decimal' ? '0.01' : '1'}" value="${value ?? ''}"
              class="${baseClass}">
          </div>
        `
      case 'datetime':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="datetime-local" name="employee[${key}]" value="${value ?? ''}"
              class="${baseClass}">
          </div>
        `
      case 'text':
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <textarea name="employee[${key}]" rows="3"
              class="${baseClass}">${value ?? ''}</textarea>
          </div>
        `
      default:
        return `
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${label}</label>
            <input type="text" name="employee[${key}]" value="${value ?? ''}"
              class="${baseClass}">
          </div>
        `
    }
  }

  dynamicFieldsHTML() {
    if (this.propertyMetadata.length === 0) return ''

    return `
      <div class="border-t border-slate-200 dark:border-slate-700 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Properties")}</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(f => this.renderField({ ...f, value: this.employee?.[f.key] })).join('')}
        </div>
      </div>
    `
  }

  contentHTML() {
    const e = this.employee
    if (!e) return `<div class="p-8 text-center">${translate("Employee not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const branchFilter = currentBranches()
    const typeOptions = (Enums()?.employee?.business_types || [
      { name: translate("Full Time"), value: "full_time" },
      { name: translate("Part Time"), value: "part_time" },
      { name: translate("Contractor"), value: "contractor" },
      { name: translate("Intern"), value: "intern" }
    ]).filter(t => t.value !== 'owner').map(t =>
      `<option value="${t.value}" ${t.value === e.business_type ? 'selected' : ''}>${t.name}</option>`
    ).join('')
    const workflowOptions = (Enums()?.employee?.workflow_statuses || [
      { name: translate("Draft"), value: "draft" },
      { name: translate("Pending"), value: "pending" },
      { name: translate("Active"), value: "active" },
      { name: translate("Inactive"), value: "inactive" }
    ]).map(t =>
      `<option value="${t.value}" ${t.value === e.workflow_status ? 'selected' : ''}>${t.name}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Employee")}</h2>
        <p class="text-sm text-slate-500 dark:text-slate-400">${e.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Full Name")}</label>
            <input type="text" name="employee[name]" value="${e.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="employee[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">${e.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Employment Type")}</label>
            <select name="employee[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${typeOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Status")}</label>
            <select name="employee[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              ${workflowOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Branch")}</label>
            <select name="employee[branch_id]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              <option value="">${translate("Select Branch")}</option>
              ${branchFilter.map(b => `<option value="${b.id}" ${b.id === e.branch_id ? 'selected' : ''}>${b.name}</option>`).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Category")}</label>
            <input type="text" value="${(currentCategories().find(c => c.id === e.category_id) || {}).name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-800/40 text-sm text-slate-500 dark:text-slate-400">
            <input type="hidden" name="employee[category_id]" value="${e.category_id}">
          </div>
        </div>

        ${this.dynamicFieldsHTML()}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_employee_path(companyId, e.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_employee_path(companyId, e.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
