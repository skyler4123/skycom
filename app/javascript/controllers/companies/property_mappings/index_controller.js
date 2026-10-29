import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_PropertyMappings_IndexController extends Companies_LayoutController {
  static targets = ["mappingsList"]

  /** @type {any[]} */
  propertyMappings = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.propertyMappings = response.property_mappings || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load property mappings") }${__errDetail ? ": " + __errDetail : ""}` })
    }
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const resourceNameFilter = (ENUMS?.category?.resource_names || []).map(r => ({
      name: r.charAt(0).toUpperCase() + r.slice(1),
      value: r
    }))

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">

          <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
            <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end justify-between gap-4 mb-6 w-full">
              <div class="flex flex-wrap items-center gap-3 w-full lg:w-auto">
                <div class="flex flex-col gap-1">
                  <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Resource")}</label>
                  <select name="resource_name" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                    ${selectOptionsHTML(resourceNameFilter, urlParams.get('resource_name'), translate("All Resources"))}
                  </select>
                </div>
                <div class="flex gap-2 mt-auto">
                  <button type="submit" class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                    <span class="material-symbols-outlined text-[18px]!">search</span>
                    ${translate("Search")}
                  </button>
                </div>
              </div>

              <a href="${Helpers.new_company_property_mapping_path(currentCompany().id)}"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("Add")}
              </a>
            </form>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-muted-foreground bg-muted border-b border-line">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Name")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Category")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Resource")}</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">${translate("Description")}</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="mappingsList">
                ${this.propertyMappings.map(m => `
                  <tr class="hover:bg-muted/50 transition-colors">
                    <td class="py-4 px-6 text-sm">
                      <div class="flex items-center gap-4">
                        <div class="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
                          <span class="material-symbols-outlined text-primary ">settings_applications</span>
                        </div>
                        <div>
                          <a href="${Helpers.company_property_mapping_path(currentCompany().id, m.id)}"
                            class="font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
                            ${m.name || translate('N/A')}
                          </a>
                        </div>
                      </div>
                    </td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">
                      ${m.category?.name || '-'}
                    </td>
                    <td class="py-4 px-6 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-muted text-foreground ">
                        ${m.resource_name || '-'}
                      </span>
                    </td>
                    <td class="py-4 px-6 text-sm text-muted-foreground max-w-xs truncate">
                      ${m.description || '-'}
                    </td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.edit_company_property_mapping_path(currentCompany().id, m.id)}"
                        class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>

          ${this.propertyMappings.length === 0 ? `
            <div class="flex flex-col items-center justify-center py-12 text-muted-foreground">
              <span class="material-symbols-outlined text-4xl mb-2">settings_applications</span>
              <p>${translate("No property mappings found")}</p>
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
