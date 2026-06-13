import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Facilities_ShowController extends Companies_LayoutController {
  /** @type {Facility | null} */
  facility = null

  /** @type {Array<{key: string, label: string, type: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_facility_path(companyId, recordId)}.json`)
      this.facility = response.facility

      if (this.facility?.category_id) {
        const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.facility.category_id)
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">Failed to load facility.</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  formatDisplayValue(value, type) {
    if (value === null || value === undefined) return '<span class="text-slate-300 dark:text-slate-700">—</span>'
    switch (type) {
      case 'boolean':
        return `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md ${value ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-slate-50 text-slate-700 dark:bg-slate-800 dark:text-slate-400'}">${value ? 'Yes' : 'No'}</span>`
      case 'integer':
        return `<span class="font-mono text-slate-900 dark:text-slate-100">${Number(value).toLocaleString()}</span>`
      case 'decimal':
        return `<span class="font-mono font-medium text-blue-600 dark:text-blue-400">${Number(value).toFixed(2)}</span>`
      case 'datetime': {
        const d = new Date(value)
        return `<span class="text-sm text-slate-900 dark:text-white">${d.toLocaleString()}</span>`
      }
      default:
        return `<span class="text-sm text-slate-900 dark:text-white">${value}</span>`
    }
  }

  showHTML() {
    const f = this.facility
    if (!f) return '<div class="p-8 text-center">Facility not found.</div>'

    const companyId = window.location.pathname.split("/")[2]
    const category = currentCategories().find(c => c.id === f.category_id)
    const branch = f.branch

    const dynamicFields = this.propertyMetadata.length > 0 ? `
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
        <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Properties</h3>
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
          ${this.propertyMetadata.map(field => `
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-emerald-600 dark:text-emerald-400">
                <span class="material-symbols-outlined text-[20px]">${field.type === 'boolean' ? 'check_circle' : field.type === 'datetime' ? 'calendar_month' : 'text_fields'}</span>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${field.label}</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${this.formatDisplayValue(f[field.key], field.type)}</p>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    ` : ''

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_facilities_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            Back to Facilities
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-amber-100 dark:border-amber-900/30 bg-amber-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-amber-600 dark:text-amber-400">warehouse</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${f.name}</h2>
              <p class="font-semibold text-amber-600 dark:text-amber-400">${f.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-amber-100 dark:bg-amber-900/40 px-3 py-1 text-xs font-bold text-amber-700 dark:text-amber-300 uppercase">${f.code || 'N/A'}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                <span class="material-symbols-outlined">category</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Type</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${Helpers.capitalize(f.business_type?.replace('_', ' ') || '')}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                <span class="material-symbols-outlined">toggle_on</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Status</p>
                <p class="text-sm font-semibold">${Helpers.statusBadge(f.workflow_status)}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                <span class="material-symbols-outlined">folder</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Category</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${category?.name || 'N/A'}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                <span class="material-symbols-outlined">business</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Branch</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${branch?.name || 'N/A'}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                <span class="material-symbols-outlined">phone</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Phone</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${f.phone_number || 'N/A'}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-amber-600 dark:text-amber-400">
                <span class="material-symbols-outlined">mail</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Email</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${f.email || 'N/A'}</p>
              </div>
            </div>
          </div>

          ${dynamicFields}

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
            <a href="${Helpers.edit_company_facility_path(companyId, f.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer">
              Edit Facility
            </a>
          </div>
        </div>
      </div>
    `
  }
}
