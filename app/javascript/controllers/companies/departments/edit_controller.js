import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Departments_EditController extends Companies_LayoutController {
  /** @type {Department | null} */
  department = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const recordId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_department_path(companyId, recordId)}.json`)
      this.department = response.department

      if (this.department?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.department.category_id)
        this.propertyMetadata = propertyMapping?.property_metadata || []
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">Failed to load department.</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const d = this.department
    if (!d) return '<div class="p-8 text-center">Department not found.</div>'

    const companyId = window.location.pathname.split("/")[2]
    const businessTypes = Enums()?.department?.business_types || []
    const workflowStatuses = Enums()?.department?.workflow_statuses || []

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Properties</h3>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => {
            const value = d[field.key]
            let inputHTML = ''
            switch (field.type) {
              case 'boolean':
                inputHTML = `
                  <input type="hidden" name="department[${field.key}]" value="false">
                  <input type="checkbox" name="department[${field.key}]" value="true" ${value ? 'checked' : ''}
                    class="rounded border-slate-300 dark:border-slate-600 text-blue-600 cursor-pointer">`
                break
              case 'integer':
                inputHTML = `<input type="number" step="1" name="department[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'decimal':
                inputHTML = `<input type="number" step="0.01" name="department[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'datetime':
                inputHTML = `<input type="datetime-local" name="department[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
                break
              case 'text':
                inputHTML = `<textarea name="department[${field.key}]" rows="3" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${value ?? ''}</textarea>`
                break
              default:
                inputHTML = `<input type="text" name="department[${field.key}]" value="${value ?? ''}" class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">`
            }
            return `
              <div>
                <label class="text-xs font-medium text-slate-500 dark:text-gray-400">${field.label}</label>
                ${inputHTML}
              </div>`
          }).join('')}
        </div>
      </div>
    ` : ''

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">Edit Department</h2>
        <p class="text-sm text-slate-500">${d.name}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Name</label>
            <input type="text" name="department[name]" value="${d.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Description</label>
            <textarea name="department[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${d.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</label>
            <select name="department[business_type]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(businessTypes, d.business_type || '')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</label>
            <select name="department[workflow_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${selectOptionsHTML(workflowStatuses, d.workflow_status)}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Category</label>
            <input type="text" value="${currentCategories().find(c => c.id === d.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
            <input type="hidden" name="department[category_id]" value="${d.category_id}">
          </div>

          <div class="space-y-1">
            <label class="text-xs font-medium text-slate-500 dark:text-gray-400">Email</label>
            <input type="email" name="department[email]" value="${d.email || ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>
        </div>

        ${dynamicFields}

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_department_path(companyId, d.id)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            Cancel
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            Save Changes
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_department_path(companyId, d.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
