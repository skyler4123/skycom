import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Roles_IndexController extends Companies_LayoutController {
  // Roles dashboard — company roles with their paired "All <Role>" system tag.
  // Depends on BE: Companies::RolesController#index (list)
  // Endpoints: GET <pathname>.json
  static targets = ["rolesList"]

  /** @type {Array<{id: string, name: string, description: string, business_type: string, paired_tag_name: string}>} */
  roles = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.roles = response.roles || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load roles") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-foreground">${translate("Roles")}</h2>
            <a href="${Helpers.new_company_role_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-muted-foreground border-b border-line">
                  <th class="py-4 px-6 font-medium">${translate("Name")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Description")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Business Type")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Notification Tag")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="rolesList" class="divide-y divide-line">
                ${this.roles.map(r => `
                  <tr class="hover:bg-muted/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_role_path(currentCompany().id, r.id)}"
                        class="text-foreground hover:text-primary cursor-pointer">
                        ${r.name}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${r.description || '<span class="text-muted-foreground/60">—</span>'}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${r.business_type || '<span class="text-muted-foreground/60">—</span>'}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${r.paired_tag_name || '<span class="text-muted-foreground/60">—</span>'}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      ${r.name === "owner" ? '<span class="text-muted-foreground/60">—</span>' : `
                      <a href="${Helpers.edit_company_role_path(currentCompany().id, r.id)}"
                        class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>`}
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
