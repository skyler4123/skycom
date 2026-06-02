import { Controller } from "@hotwired/stimulus"

export default class Companies_Categories_ShowModalController extends Controller {
  /** @type {Category | null} */
  category = null

  connect() {
    this.category = /** @type {any} */ (window.currentCategory)

    if (this.category) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const c = this.category

    const resourceOptions = (Enums()?.category?.resource_names || []).map(r => ({
      name: r,
      value: r
    }))

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[640px] overflow-hidden rounded-xl bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Category Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6 space-y-6">

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Name</label>
                ${editable({
                  dispatch: "updateCategory",
                  resource: "category",
                  name: "name",
                  id: c.id,
                  value: c.name || '',
                  url: Helpers.edit_company_category_path(currentCompany().id, c.id),
                  html: `<p class="text-lg font-semibold text-slate-900 dark:text-white">${c.name || 'N/A'}</p>`,
                  successMessage: "Category name updated!",
                  errorMessage: "Failed to update name!"
                })}
              </div>

              <div>
                <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Resource Name</label>
                ${editable({
                  dispatch: "updateCategory",
                  resource: "category",
                  name: "resource_name",
                  id: c.id,
                  value: c.resource_name || '',
                  url: Helpers.edit_company_category_path(currentCompany().id, c.id),
                  type: "select",
                  options: resourceOptions,
                  html: `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-300">${c.resource_name || 'N/A'}</span>`,
                  successMessage: "Resource name updated!",
                  errorMessage: "Failed to update resource name!"
                })}
              </div>
            </div>

            <div>
              <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Description</label>
              ${editable({
                dispatch: "updateCategory",
                resource: "category",
                name: "description",
                id: c.id,
                value: c.description || '',
                url: Helpers.edit_company_category_path(currentCompany().id, c.id),
                html: `<p class="text-sm text-slate-600 dark:text-slate-300">${c.description || 'No description'}</p>`,
                successMessage: "Description updated!",
                errorMessage: "Failed to update description!"
              })}
            </div>

          </div>

        </div>
      </div>
    `
  }

  close(event) {
    event.preventDefault()
    closeModal()
  }
}