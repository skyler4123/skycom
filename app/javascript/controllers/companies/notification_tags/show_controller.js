import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_NotificationTags_ShowController extends Companies_LayoutController {
  // Notification tag detail — read-only fields + edit/delete for custom tags.
  // System tags render with no action buttons (fully read-only).
  // Depends on BE: Companies::NotificationTagsController#show
  // Endpoints: GET company_notification_tag_path.json
  /** @type {any | null} */
  tag = null

  async connect() {
    super.connect()

    const recordId = window.location.pathname.split("/").pop()
    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_notification_tag_path(companyId, recordId)}.json`)
      this.tag = response.notification_tag

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load notification tag.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    return this.showHTML()
  }

  showHTML() {
    const t = this.tag
    if (!t) return `<div class="p-8 text-center">${translate("Notification tag not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const isSystem = t.business_type === "system"
    const typeLabel = isSystem ? translate("System") : translate("Custom")

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_notification_tags_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Notification Tags")}
          </a>

          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl bg-amber-100 dark:bg-gray-800 flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-amber-600 dark:text-amber-400">sell</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${t.name}</h2>
              <p class="font-semibold text-amber-600 dark:text-amber-400">${t.description || ''}</p>
              <div class="mt-2 flex flex-wrap justify-center gap-2 sm:justify-start">
                <span class="inline-flex items-center rounded-lg bg-slate-100 dark:bg-slate-800 px-3 py-1 text-xs font-bold text-slate-600 dark:text-slate-300 uppercase">${typeLabel}</span>
              </div>
            </div>
          </div>

          ${isSystem ? '' : `
          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
            ${form({
              action: Helpers.company_notification_tag_path(companyId, t.id),
              method: "DELETE",
              attributes: `data-turbo="false" class="inline"`,
              html: `<button type="submit" class="inline-flex items-center px-6 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer">${translate("Delete")}</button>`
            })}
            <a href="${Helpers.edit_company_notification_tag_path(companyId, t.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Tag")}
            </a>
          </div>`}
        </div>
      </div>`
  }
}
