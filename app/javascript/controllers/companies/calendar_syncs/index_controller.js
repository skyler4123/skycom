import Companies_LayoutController from "controllers/companies/layout_controller"

// Calendar Sync (Calendar/Schedule module — docs/CALENDAR.md §7).
//
// READ-ONLY. Lists every provider in CALENDAR_SYNC_PROVIDERS with its
// connection state, plus the recent calendar_sync_logs audit trail.
//
// Nothing here connects anything: Calendar::AdapterFactory::REGISTRY is empty in
// v1, so every row honestly reports adapter_available: false. The page exists so
// the seam is visible and auditable before the first adapter ships — not to
// pretend an integration is live.
//
// `credentials` is never sent to the client; the controller returns
// CalendarSyncConnection#public_attributes, which whitelists the safe keys, and
// the column itself is Active Record encrypted at rest.
//
// Depends on BE: GET /companies/:company_id/calendar_syncs.json
export default class Companies_CalendarSyncs_IndexController extends Companies_LayoutController {
  static targets = ["providers", "logs"]

  /** @type {{provider: string, adapter_available: boolean, connected: boolean, status: string, last_synced_at: string|null, last_sync_error: string|null}[]} */
  providers = []

  /** @type {Object[]} */
  recentLogs = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson(`${Helpers.company_calendar_syncs_path(currentCompany().id)}.json`)
      const payload = response.calendar_syncs || {}
      this.providers = payload.providers || []
      this.recentLogs = payload.recent_logs || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load calendar sync")}${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  providerLabel(provider) {
    const labels = { calcom: "Cal.com", google: "Google", outlook: "Outlook" }
    return labels[provider] || Helpers.capitalize(provider)
  }

  formatDateTime(value) {
    if (!value) return "—"
    return new Date(value).toLocaleString(undefined, {
      year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit"
    })
  }

  providerRow(provider) {
    const badge = provider.connected
      ? `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300">${translate("Connected")}</span>`
      : `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300">${translate("Not connected")}</span>`

    return `
      <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
        <td class="py-4 px-6 text-sm font-medium text-slate-900 dark:text-white">${this.providerLabel(provider.provider)}</td>
        <td class="py-4 px-6 text-sm">${badge}</td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
          ${provider.adapter_available ? translate("Available") : translate("Not available")}
        </td>
        <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">${this.formatDateTime(provider.last_synced_at)}</td>
        <td class="py-4 px-6 text-sm text-red-600">${provider.last_sync_error || "—"}</td>
      </tr>
    `
  }

  logRow(log) {
    const colors = {
      success: "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300",
      error: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300",
      partial: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300"
    }
    return `
      <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
        <td class="py-3 px-6 text-sm text-slate-600 dark:text-slate-300">${this.providerLabel(log.provider)}</td>
        <td class="py-3 px-6 text-sm text-slate-600 dark:text-slate-300">${Helpers.capitalize((log.direction || "").replace("_", " "))}</td>
        <td class="py-3 px-6 text-sm text-slate-600 dark:text-slate-300">${log.entity_type || "—"}</td>
        <td class="py-3 px-6 text-sm">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${colors[log.status] || colors.partial}">${Helpers.capitalize(log.status || "")}</span>
        </td>
        <td class="py-3 px-6 text-sm text-slate-600 dark:text-slate-300">${log.duration_label || "—"}</td>
        <td class="py-3 px-6 text-sm text-slate-600 dark:text-slate-300">${this.formatDateTime(log.created_at)}</td>
      </tr>
    `
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col gap-6">
          <div>
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Calendar Sync")}</h2>
            <p class="text-sm text-slate-500 mt-1">
              ${translate("Skycom runs its own scheduling. No external provider is connected yet.")}
            </p>
          </div>

          <div>
            <h3 class="text-sm font-semibold text-slate-700 dark:text-slate-200 mb-3">${translate("Providers")}</h3>
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                    <th class="py-3 px-6 font-medium">${translate("Provider")}</th>
                    <th class="py-3 px-6 font-medium">${translate("Status")}</th>
                    <th class="py-3 px-6 font-medium">${translate("Adapter")}</th>
                    <th class="py-3 px-6 font-medium">${translate("Last Synced")}</th>
                    <th class="py-3 px-6 font-medium">${translate("Last Error")}</th>
                  </tr>
                </thead>
                <tbody data-${this.identifier}-target="providers" class="divide-y divide-slate-200 dark:divide-slate-800">
                  ${this.providers.length === 0
                    ? `<tr><td colspan="5" class="py-8 text-center text-sm text-slate-500">${translate("No providers configured")}</td></tr>`
                    : this.providers.map((p) => this.providerRow(p)).join("")}
                </tbody>
              </table>
            </div>
          </div>

          <div>
            <h3 class="text-sm font-semibold text-slate-700 dark:text-slate-200 mb-3">${translate("Sync history")}</h3>
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                    <th class="py-3 px-6 font-medium">${translate("Provider")}</th>
                    <th class="py-3 px-6 font-medium">${translate("Direction")}</th>
                    <th class="py-3 px-6 font-medium">${translate("Entity")}</th>
                    <th class="py-3 px-6 font-medium">${translate("Status")}</th>
                    <th class="py-3 px-6 font-medium">${translate("Duration")}</th>
                    <th class="py-3 px-6 font-medium">${translate("When")}</th>
                  </tr>
                </thead>
                <tbody data-${this.identifier}-target="logs" class="divide-y divide-slate-200 dark:divide-slate-800">
                  ${this.recentLogs.length === 0
                    ? `<tr><td colspan="6" class="py-8 text-center text-sm text-slate-500">${translate("No sync activity yet")}</td></tr>`
                    : this.recentLogs.map((l) => this.logRow(l)).join("")}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    `
  }
}
