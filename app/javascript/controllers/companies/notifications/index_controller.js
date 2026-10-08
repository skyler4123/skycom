import Companies_LayoutController from "controllers/companies/layout_controller"

// Notifications dashboard — subscribed-tag broadcasts (static columns, no PropertyMapping).
// Depends on BE: Companies::NotificationsController#index|mark_read|mark_all_read
// Endpoints: GET <pathname>.json — subscribed list; POST mark_read / mark_all_read
// Docs: docs/superpowers/plans/2026-10-07-notification.md
export default class Companies_Notifications_IndexController extends Companies_LayoutController {
  static targets = ["notificationsList"]

  /** @type {any[]} */
  notifications = []

  async connect() {
    super.connect()

    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.notifications = response.notifications || []
      this.pagination = response.pagination || {}
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load notifications") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  async markAllAsRead(event) {
    event.preventDefault()
    try {
      await fetchJson(Helpers.mark_all_read_company_notifications_path(currentCompany().id), { method: "POST" })
      const response = await fetchJson(`${pathname()}.json?${new URLSearchParams(window.location.search).toString()}`)
      this.notifications = response.notifications || []
      this.pagination = response.pagination || {}
      this.renderContent()
      if (typeof this.refreshBell === "function") this.refreshBell()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to mark all as read") })
    }
  }

  async markAsRead(event) {
    event.preventDefault()
    const { notificationId } = event.params
    try {
      await fetchJson(Helpers.mark_read_company_notification_path(currentCompany().id, notificationId), { method: "POST" })
      const record = this.notifications.find((n) => n.id === notificationId)
      if (record) record.read = true
      this.renderContent()
      if (typeof this.refreshBell === "function") this.refreshBell()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to mark as read") })
    }
  }

  contentHTML() {
    const columns = [
      { key: "title", name: translate("Title") },
      { key: "severity", name: translate("Severity") },
      { key: "tags", name: translate("Tags") },
      { key: "created_at", name: translate("Received") },
      { key: "read", name: translate("Status") }
    ]

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">

          <div class="flex items-center justify-between gap-4 mb-6">
            <h2 class="text-lg font-bold text-slate-900 dark:text-white">${translate("Notifications")}</h2>
            <div class="flex items-center gap-2">
              <a href="${Helpers.company_notification_config_path(currentCompany().id)}"
                class="flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">settings</span>
                ${translate("Preferences")}
              </a>
              <button
                type="button"
                data-action="click->${this.identifier}#markAllAsRead"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer"
              >
                <span class="material-symbols-outlined text-[20px]">done_all</span>
                ${translate("Mark all as read")}
              </button>
            </div>
          </div>

          <div class="overflow-x-auto">
            ${table({
              rows: this.notifications,
              columns,
              identifier: this.identifier,
              target: "notificationsList",
              renderers: {
                title: (value, record) => `
                  <a href="${Helpers.company_notification_path(currentCompany().id, record.id)}"
                    class="font-medium ${record.read ? "text-slate-500 dark:text-slate-400" : "text-slate-900 dark:text-white"} hover:text-blue-600 dark:hover:text-blue-400 transition-colors cursor-pointer">
                    ${value || translate("Untitled notification")}
                  </a>`,
                severity: (value) => `${Helpers.statusBadge(value || "info")}`,
                tags: (value) => `${(value || []).map((t) => `<span class="inline-block font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium mr-1">${t.name}</span>`).join("") || '<span class="text-slate-300 dark:text-slate-700">—</span>'}`,
                created_at: (value) => `<span class="text-xs text-slate-500 dark:text-slate-400">${value ? new Date(value).toLocaleString() : "—"}</span>`,
                read: (value, record) => value
                  ? `<span class="text-xs text-slate-400 dark:text-slate-500">${translate("Read")}</span>`
                  : `<button type="button" data-action="click->${this.identifier}#markAsRead" data-${this.identifier}-notification-id-param="${record.id}" class="px-3 py-1 text-xs font-medium text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg cursor-pointer">${translate("Mark as read")}</button>`
              }
            })}
          </div>

          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>`
  }
}
