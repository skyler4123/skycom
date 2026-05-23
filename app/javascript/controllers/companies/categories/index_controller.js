import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Categories_NewModalController from "controllers/companies/categories/new_modal_controller";
import Companies_Categories_ShowModalController from "controllers/companies/categories/show_modal_controller";

export default class Companies_Categories_IndexController extends Companies_LayoutController {
  static targets = ["categoriesList"]

  /** @type {(Category & { name: string })[]} */
  categories = []

  async connect() {
    super.connect()
    try {
      /** @type {{ categories: Category[], pagination: any }} */
      const response = await fetchJson()

      this.categories = response.categories || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })

    } catch (error) {
      toast({ type: "error", message: "Failed to load categories" })
    }
  }

  openNewModal() {
    openModal({ html: `<div data-controller="${identifier(Companies_Categories_NewModalController)}"></div>` })
  }

  openShowModal(event) {
    event.preventDefault()
    const { categoryId } = event.params
    window.currentCategory = findById(this.categories, categoryId)
    openModal({ html: `<div data-controller="${identifier(Companies_Categories_ShowModalController)}"></div>` })
  }

  handleUpdate(event) {
    const { resource, data } = event.detail
    const newObject = data[resource] || data

    if (!newObject) return

    this.categories = mergeObjectArrays(this.categories, [newObject], "id")
    this.renderContent()
    toast({ type: "success", message: "Category updated successfully!" })
  }

  contentHTML() {
    const resourceNameFilter = (Enums()?.category?.resource_names || []).map(r => ({
      name: r.charAt(0).toUpperCase() + r.slice(1),
      value: r
    }))
    const urlParams = new URLSearchParams(window.location.search)

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 mb-6 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">

                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">Resource</label>
                  <select name="resource_name" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                    ${selectOptionsHTML(resourceNameFilter, urlParams.get('resource_name'), "All Resources")}
                  </select>
                </div>

                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]">search</span>
                    Search
                  </button>
                </div>
              </div>

              <button
                type="button"
                data-action="click->${this.identifier}#openNewModal"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                Add
              </button>
            </form>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Resource</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Description</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="categoriesList">
                ${this.categories.map(category => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <div class="flex items-center gap-4">
                        <div class="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
                          <span class="material-symbols-outlined text-purple-600 dark:text-purple-400">category</span>
                        </div>
                        <div>
                          <p class="font-medium text-slate-900 dark:text-white">${category.name || 'N/A'}</p>
                        </div>
                      </div>
                    </td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-300">
                        ${category.resource_name || 'N/A'}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300 max-w-xs truncate">
                      ${category.description || '-'}
                    </td>
                    <td class="py-4 px-6 text-sm text-right">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer dark:hover:bg-blue-900/30"
                        data-action="click->${this.identifier}#openShowModal"
                        data-${this.identifier}-category-id-param="${category.id}"
                      >
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>

          ${this.categories.length === 0 ? `
            <div class="flex flex-col items-center justify-center py-12 text-slate-500 dark:text-slate-400">
              <span class="material-symbols-outlined text-4xl mb-2">category</span>
              <p>No categories found</p>
            </div>
          ` : ''}

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}