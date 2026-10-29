import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Categories_ShowController extends Companies_LayoutController {
  /** @type {(Category & { property_mappings: any[] }) | null} */
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
    const propertyMappingCount = c.property_mappings?.[0]?.metadata?.properties?.length || 0

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_categories_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Categories")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-primary/10 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-primary ">category</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${c.name}</h2>
              <p class="font-semibold text-muted-foreground">${c.description || ''}</p>
              <div class="mt-4 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-muted px-3 py-1 text-xs font-bold text-foreground uppercase">${c.resource_name || translate("N/A")}</span>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary ">
                <span class="material-symbols-outlined">label</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Name")}</p>
                <p class="text-sm font-semibold text-foreground">${c.name || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary ">
                <span class="material-symbols-outlined">dataset</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Resource Name")}</p>
                <p class="text-sm font-semibold text-foreground">${c.resource_name || translate("N/A")}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary ">
                <span class="material-symbols-outlined">description</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Description")}</p>
                <p class="text-sm font-semibold text-foreground">${c.description || '—'}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary ">
                <span class="material-symbols-outlined">view_column</span>
              </div>
              <div>
                <p class="text-xs font-medium text-muted-foreground">${translate("Property Fields")}</p>
                <p class="text-sm font-semibold text-foreground">${propertyMappingCount > 0 ? `${propertyMappingCount} ${translate('properties defined')}` : translate('No properties')}</p>
              </div>
            </div>
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_category_path(companyId, c.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Category")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
