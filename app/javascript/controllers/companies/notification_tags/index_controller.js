import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_NotificationTags_IndexController extends Companies_LayoutController {
  // Notification tags dashboard — user-managed broadcast tags.
  // Depends on BE: Companies::NotificationTagsController#index (list)
  // Endpoints: GET <pathname>.json
  static targets = ["tagsList"]

  /** @type {Array<{id: string, name: string, description: string, business_type: string}>} */
  tags = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.tags = response.notification_tags || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load notification tags") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  typeBadge(value) {
    const isSystem = value === "system"
    return isSystem
      ? `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-muted text-muted-foreground ">${translate("System")}</span>`
      : `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-success/10 text-success ">${translate("Custom")}</span>`
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-foreground">${translate("Notification Tags")}</h2>
            <a href="${Helpers.new_company_notification_tag_path(currentCompany().id)}"
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
                  <th class="py-4 px-6 font-medium">${translate("Type")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="tagsList" class="divide-y divide-line">
                ${this.tags.map(t => `
                  <tr class="hover:bg-muted/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_notification_tag_path(currentCompany().id, t.id)}"
                        class="text-foreground hover:text-primary cursor-pointer">
                        ${t.name}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${t.description || '<span class="text-muted-foreground/60">—</span>'}</td>
                    <td class="py-4 px-6 text-sm">${this.typeBadge(t.business_type)}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      ${t.business_type === "system" ? '<span class="text-muted-foreground/60">—</span>' : `
                      <a href="${Helpers.edit_company_notification_tag_path(currentCompany().id, t.id)}"
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
