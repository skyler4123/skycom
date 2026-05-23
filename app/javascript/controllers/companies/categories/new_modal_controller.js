import { Controller } from "@hotwired/stimulus"

export default class Companies_Categories_NewModalController extends Controller {
  async handleSubmit(event) {
    event.preventDefault()

    try {
      const response = await fetchJson(Helpers.company_categories_path(currentCompany().id), {
        method: "POST",
        body: new FormData(event.target)
      })
      /** @type {Category} */
      const category = response.category
      reloadThenToast({
        type: "success",
        message: `${category.name || 'Category'} created successfully!`
      })
    } catch (error) {
      toast({
        type: "error",
        message: error.errors || "Failed to create category"
      })
    }
  }

  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    const resourceOptions = (Enums()?.category?.resource_names || []).map(r => ({
      name: r.charAt(0).toUpperCase() + r.slice(1),
      value: r
    }))

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Category</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Name</label>
            <input type="text" name="category[name]" required placeholder="e.g. Cosmetics"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Resource Name</label>
            <select name="category[resource_name]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
              <option value="">Select Resource</option>
              ${resourceOptions.map(opt => `<option value="${opt.value}">${opt.name}</option>`).join('')}
            </select>
          </div>
        </div>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Description</label>
          <textarea name="category[description]" rows="2" placeholder="Optional description..."
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white"></textarea>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg dark:text-slate-300 dark:hover:bg-slate-800 cursor-pointer">
            Cancel
          </button>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            Save Category
          </button>
        </div>
      </div>
    `

    return form({
      action: Helpers.company_categories_path(currentCompany().id),
      method: "POST",
      attributes: `
        class="p-8 bg-white dark:bg-slate-800 rounded-2xl w-[500px] shadow-2xl"
        data-action="submit->${this.identifier}#handleSubmit"
      `,
      html: fields
    })
  }
}
