import Companies_LayoutController from "controllers/companies/layout_controller"

// Notification detail — read-only view (show auto-marks read server-side).
// Depends on BE: Companies::NotificationsController#show
// Endpoints: GET <pathname>.json — single subscribed notification
// Docs: docs/superpowers/plans/2026-10-07-notification.md
export default class Companies_Notifications_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  notification = null

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.notification = response.notification

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load notification.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const n = this.notification
    if (!n) return `<div class="p-8 text-center">${translate("Notification not found.")}</div>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_notifications_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Notifications")}
          </a>

          <div class="flex items-center gap-2 mb-2">
            ${Helpers.statusBadge(n.severity || "info")}
            ${(n.tags || []).map((t) => `<span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${t.name}</span>`).join("")}
          </div>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white">${n.title || translate("Untitled notification")}</h2>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">${n.created_at ? new Date(n.created_at).toLocaleString() : ""}</p>
          <p class="text-sm text-slate-700 dark:text-slate-300 mt-4 whitespace-pre-line">${n.body || ""}</p>
          ${n.url ? `<a href="${n.url}" class="inline-flex items-center gap-1 mt-4 text-sm text-blue-600 hover:text-blue-700 cursor-pointer">${translate("Open linked record")}<span class="material-symbols-outlined text-[18px]!">open_in_new</span></a>` : ""}
        </div>
      </div>`
  }
}
