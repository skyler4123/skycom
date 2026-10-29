import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Categories_EditController extends Companies_LayoutController {
  /** @type {Category | null} */
  category = null

  async connect() {
    super.connect()

    const categoryId = window.location.pathname.split("/")[4]
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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load category.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const c = this.category
    if (!c) return `<div class="p-8 text-center">${translate("Category not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]

    const resourceOptions = (ENUMS?.category?.resource_names || []).map(r => ({
      name: r.charAt(0).toUpperCase() + r.slice(1),
      value: r
    })).map(opt => `<option value="${opt.value}" ${opt.value === c.resource_name ? 'selected' : ''}>${opt.name}</option>`).join('')

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("Edit Category")}</h2>
        <p class="text-sm text-muted-foreground">${c.name}</p>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="category[name]" value="${c.name || ''}" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Resource Name")}</label>
            <select name="category[resource_name]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              ${resourceOptions}
            </select>
          </div>
        </div>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Description")}</label>
          <textarea name="category[description]" rows="2"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">${c.description || ''}</textarea>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_category_path(companyId, c.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg transition-colors cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-colors cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_category_path(companyId, c.id),
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
