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
      { key: "name", name: translate("Name") },
      { key: "severity", name: translate("Severity") },
      { key: "tags", name: translate("Tags") },
      { key: "created_at", name: translate("Received") },
      { key: "read", name: translate("Status") }
    ]

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">

          <div class="flex items-center justify-between gap-4 mb-6">
            <h2 class="text-lg font-bold text-foreground">${translate("Notifications")}</h2>
            <div class="flex items-center gap-2">
              <a href="${Helpers.company_notification_config_path(currentCompany().id)}"
                class="flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg transition-colors cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">settings</span>
                ${translate("Preferences")}
              </a>
              <button
                type="button"
                data-action="click->${this.identifier}#markAllAsRead"
                class="flex items-center justify-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm whitespace-nowrap cursor-pointer"
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
                name: (value, record) => `
                  <a href="${Helpers.company_notification_path(currentCompany().id, record.id)}"
                    class="font-medium ${record.read ? "text-muted-foreground" : "text-foreground"} hover:text-primary transition-colors cursor-pointer">
                    ${value || translate("Untitled notification")}
                  </a>`,
                severity: (value) => `${Helpers.statusBadge(value || "info")}`,
                tags: (value) => `${(value || []).map((t) => `<span class="inline-block font-mono text-xs bg-muted/60 px-2 py-0.5 rounded text-muted-foreground font-medium mr-1">${t.name}</span>`).join("") || '<span class="text-muted-foreground/60">—</span>'}`,
                created_at: (value) => `<span class="text-xs text-muted-foreground">${value ? new Date(value).toLocaleString() : "—"}</span>`,
                read: (value, record) => value
                  ? `<span class="text-xs text-muted-foreground">${translate("Read")}</span>`
                  : `<button type="button" data-action="click->${this.identifier}#markAsRead" data-${this.identifier}-notification-id-param="${record.id}" class="px-3 py-1 text-xs font-medium text-primary hover:bg-primary/10 rounded-lg cursor-pointer">${translate("Mark as read")}</button>`
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
