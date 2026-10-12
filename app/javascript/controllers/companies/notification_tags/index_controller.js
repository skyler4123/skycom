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
      ? `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300">${translate("System")}</span>`
      : `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">${translate("Custom")}</span>`
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Notification Tags")}</h2>
            <a href="${Helpers.new_company_notification_tag_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Name")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Description")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Type")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="tagsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.tags.map(t => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_notification_tag_path(currentCompany().id, t.id)}"
                        class="text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${t.name}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${t.description || '<span class="text-slate-300 dark:text-slate-700">—</span>'}</td>
                    <td class="py-4 px-6 text-sm">${this.typeBadge(t.business_type)}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      ${t.business_type === "system" ? '<span class="text-slate-300 dark:text-slate-700">—</span>' : `
                      <a href="${Helpers.edit_company_notification_tag_path(currentCompany().id, t.id)}"
                        class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
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
