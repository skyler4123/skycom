import Companies_LayoutController from "controllers/companies/layout_controller"

// Per-employee notification preferences — placeholder in v1 (no delivery effect).
// Depends on BE: Companies::NotificationConfigsController#show|update
// Endpoints: GET/PATCH <pathname>.json — single record
// Docs: docs/superpowers/plans/2026-10-07-notification.md
export default class Companies_NotificationConfigs_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  config = null

  async connect() {
    super.connect()

    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.config = response.notification_config
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to load notification preferences") })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const prefs = this.config?.preferences || {}
    const fields = `
      <div class="rounded-lg bg-warning/10 border border-warning/20 p-4 text-sm text-warning ">
        ${translate("Notification preferences are under development and don't affect delivery yet.")}
      </div>
      <div class="space-y-4 pt-2">
        <label class="flex items-center gap-3 cursor-pointer">
          <input type="hidden" name="notification_config[preferences][mobile]" value="false">
          <input type="checkbox" name="notification_config[preferences][mobile]" value="true" ${prefs.mobile ? "checked" : ""} class="h-5 w-5 rounded border-line text-primary cursor-pointer">
          <span class="text-sm text-foreground">${translate("Enable mobile notifications")}</span>
        </label>
        <label class="flex items-center gap-3 cursor-pointer">
          <input type="hidden" name="notification_config[preferences][email]" value="false">
          <input type="checkbox" name="notification_config[preferences][email]" value="true" ${prefs.email ? "checked" : ""} class="h-5 w-5 rounded border-line text-primary cursor-pointer">
          <span class="text-sm text-foreground">${translate("Enable email notifications")}</span>
        </label>
      </div>
      <div class="flex justify-end pt-6 border-t border-line">
        <button type="submit" class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
          ${translate("Save Preferences")}
        </button>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_notification_config_path(currentCompany().id),
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line space-y-6" data-turbo="false"`,
          html: `<h2 class="text-xl font-bold text-foreground">${translate("Notification Preferences")}</h2>` + fields
        })}
      </div>`
  }
}
