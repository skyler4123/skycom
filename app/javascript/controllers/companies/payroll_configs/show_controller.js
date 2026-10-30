// Depends on BE: Companies::PayrollConfigsController#show + #update
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_PayrollConfigs_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  payrollConfig = null

  async connect() {
    super.connect()

    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_payroll_config_path(companyId)}.json`)
      this.payrollConfig = response.payroll_config
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to load payroll config" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  async saveConfig(event) {
    event.preventDefault()
    const companyId = window.location.pathname.split("/")[2]
    const form = event.target
    const data = new FormData(form)
    const payload = {
      payroll_config: {
        date_basis: data.get("date_basis"),
        include_attendance_months: data.get("include_attendance_months") === "on",
        include_attendance_days: data.get("include_attendance_days") === "on",
        excluded_lifecycle_statuses: (data.get("excluded_lifecycle_statuses") || "").split(",").map(s => s.trim()).filter(Boolean),
        excluded_workflow_statuses: (data.get("excluded_workflow_statuses") || "").split(",").map(s => s.trim()).filter(Boolean),
        business_types: (data.get("business_types") || "").split(",").map(s => s.trim()).filter(Boolean),
        branch_ids: (data.get("branch_ids") || "").split(",").map(s => s.trim()).filter(Boolean),
        employee_ids: (data.get("employee_ids") || "").split(",").map(s => s.trim()).filter(Boolean)
      }
    }
    try {
      await fetchJson(`${Helpers.company_payroll_config_path(companyId)}`, {
        method: "PATCH",
        body: payload
      })
      reloadThenToast({ type: "success", message: "Payroll config updated" })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to update payroll config" })
    }
  }

  contentHTML() {
    const cfg = this.payrollConfig || {}
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line max-w-2xl">
          <h2 class="text-xl font-bold text-foreground mb-4">Payroll Config</h2>
          <form data-action="submit->${this.identifier}#saveConfig" class="space-y-4">
            <div>
              <label class="text-xs text-muted-foreground uppercase">Date Basis</label>
              <select name="date_basis" class="w-full px-3 py-2 border rounded-lg text-sm">
                <option value="month" ${cfg.date_basis === "month" ? "selected" : ""}>Month</option>
              </select>
            </div>
            <label class="flex items-center gap-2 text-sm"><input type="checkbox" name="include_attendance_months" ${cfg.include_attendance_months ? "checked" : ""} /> Include attendance months</label>
            <label class="flex items-center gap-2 text-sm"><input type="checkbox" name="include_attendance_days" ${cfg.include_attendance_days ? "checked" : ""} /> Include attendance days</label>
            <div>
              <label class="text-xs text-muted-foreground uppercase">Excluded lifecycle statuses (comma-separated)</label>
              <input type="text" name="excluded_lifecycle_statuses" value="${(cfg.excluded_lifecycle_statuses || []).join(", ")}" class="w-full px-3 py-2 border rounded-lg text-sm" />
            </div>
            <div>
              <label class="text-xs text-muted-foreground uppercase">Excluded workflow statuses (comma-separated)</label>
              <input type="text" name="excluded_workflow_statuses" value="${(cfg.excluded_workflow_statuses || []).join(", ")}" class="w-full px-3 py-2 border rounded-lg text-sm" />
            </div>
            <div>
              <label class="text-xs text-muted-foreground uppercase">Business types (comma-separated, blank = all)</label>
              <input type="text" name="business_types" value="${(cfg.business_types || []).join(", ")}" class="w-full px-3 py-2 border rounded-lg text-sm" />
            </div>
            <div>
              <label class="text-xs text-muted-foreground uppercase">Branch IDs (comma-separated, blank = all)</label>
              <input type="text" name="branch_ids" value="${(cfg.branch_ids || []).join(", ")}" class="w-full px-3 py-2 border rounded-lg text-sm" />
            </div>
            <div>
              <label class="text-xs text-muted-foreground uppercase">Employee IDs (comma-separated, blank = all)</label>
              <input type="text" name="employee_ids" value="${(cfg.employee_ids || []).join(", ")}" class="w-full px-3 py-2 border rounded-lg text-sm" />
            </div>
            <button type="submit" class="px-4 py-2 bg-primary text-primary-foreground rounded-lg text-sm">Save Config</button>
          </form>
        </div>
      </div>
    `
  }
}
