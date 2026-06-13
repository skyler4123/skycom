import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Categories_ShowController extends Companies_LayoutController {
  /** @type {(Category & { property_mapping: any }) | null} */
  category = null

  async connect() {
    super.connect()

    const categoryId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_category_path(companyId, categoryId)}.json`)
      this.category = response.category

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
          this.contentTarget.innerHTML = '<div class="p-8 text-center text-red-600">Failed to load category.</div>'
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const c = this.category
    if (!c) return '<div class="p-8 text-center">Category not found.</div>'

    const companyId = window.location.pathname.split("/")[2]
    const propertyMappingCount = c.property_mapping?.property_metadata?.length || 0

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_categories_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            Back to Categories
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-purple-600 dark:text-purple-400">category</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${c.name}</h2>
              <p class="font-semibold text-slate-600 dark:text-slate-400">${c.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-slate-100 dark:bg-slate-800/40 px-3 py-1 text-xs font-bold text-slate-700 dark:text-slate-300 uppercase">${c.resource_name || 'N/A'}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                <span class="material-symbols-outlined">label</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Name</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${c.name || 'N/A'}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                <span class="material-symbols-outlined">dataset</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Resource Name</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${c.resource_name || 'N/A'}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                <span class="material-symbols-outlined">description</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Description</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${c.description || '—'}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-purple-600 dark:text-purple-400">
                <span class="material-symbols-outlined">view_column</span>
              </div>
              <div>
                <p class="text-xs font-medium text-slate-500 dark:text-gray-400">Property Fields</p>
                <p class="text-sm font-semibold text-slate-900 dark:text-white">${propertyMappingCount > 0 ? `${propertyMappingCount} properties defined` : 'No properties'}</p>
              </div>
            </div>
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
            <a href="${Helpers.edit_company_category_path(companyId, c.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer">
              Edit Category
            </a>
          </div>
        </div>
      </div>
    `
  }
}
