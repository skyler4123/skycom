import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_PermissionLogs_ShowController extends Companies_LayoutController {
  // Single audit row — actor + role/policy snapshot + before/after diff.
  // Depends on BE: Companies::PermissionLogsController#show
  // Endpoints: GET /companies/:company_id/permission_logs/:id.json
  // Docs: docs/ABAC.md
  /** @type {Object|null} */
  log = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_permission_log_path(currentCompany().id, id)}.json`)
      this.log = response.permission_log
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load permission log")}${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  actionBadge(action) {
    const colors = {
      granted: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
      revoked: 'bg-rose-100 text-rose-800 dark:bg-rose-900/30 dark:text-rose-300',
      conditions_changed: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
      resource_added: 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300'
    }
    const color = colors[action] || 'bg-gray-100 text-gray-800'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize((action || '').replace(/_/g, ' '))}</span>`
  }

  field(label, value) {
    return `
      <div>
        <p class="text-xs font-medium text-slate-500">${translate(label)}</p>
        <p class="text-sm font-semibold text-slate-900 dark:text-white">${value ?? '—'}</p>
      </div>`
  }

  statusName(code) {
    if (code === null || code === undefined) return null
    return code === 1 ? 'active' : code === 0 ? 'inactive' : String(code)
  }

  contentHTML() {
    const l = this.log
    if (!l) return '<div class="p-8 text-center">Not found.</div>'
    const before = l.metadata?.tag_conditions_before
    const after = l.metadata?.tag_conditions_after

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_permission_logs_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Permission Log")}</h2>
          <div class="grid grid-cols-2 gap-6 mb-8">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Action")}</p>
              <p class="text-sm font-semibold">${this.actionBadge(l.action)}</p>
            </div>
            ${this.field("Changed By", l.employee?.name)}
            ${this.field("Changed At", l.created_at ? new Date(l.created_at).toLocaleString() : null)}
            ${this.field("Role", l.role?.name || l.role_name)}
            ${this.field("Policy", l.policy?.name || l.policy_name)}
            ${this.field("Resource", l.resource_name)}
            ${this.field("Policy Action", l.policy_action)}
            ${this.field("From", this.statusName(l.from_workflow_status))}
            ${this.field("To", this.statusName(l.to_workflow_status))}
          </div>
          <h3 class="text-lg font-bold text-slate-900 dark:text-white mb-4">${translate("Tag Conditions")}</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700">
              <p class="text-xs font-bold text-slate-400 uppercase mb-2">${translate("Before")}</p>
              <pre class="text-xs font-mono text-slate-700 dark:text-slate-200 whitespace-pre-wrap">${before ? JSON.stringify(before, null, 2) : '—'}</pre>
            </div>
            <div class="p-4 rounded-lg bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700">
              <p class="text-xs font-bold text-slate-400 uppercase mb-2">${translate("After")}</p>
              <pre class="text-xs font-mono text-slate-700 dark:text-slate-200 whitespace-pre-wrap">${after ? JSON.stringify(after, null, 2) : '—'}</pre>
            </div>
          </div>
        </div>
      </div>`
  }
}
