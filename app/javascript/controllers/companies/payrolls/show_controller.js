// Depends on BE: Companies::PayrollsController#show + #update
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Payrolls_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  payroll = null

  /** @type {any[]} */
  attendanceDays = []

  async connect() {
    super.connect()

    const parts = window.location.pathname.split("/")
    const id = parts[parts.length - 1]
    const companyId = parts[2]

    try {
      const response = await fetchJson(`${Helpers.company_payroll_payroll_path(companyId, id)}.json`)
      this.payroll = response.payroll
      this.attendanceDays = response.attendance_days || []
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to load payroll" })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  async handleSubmit(event) {
    event.preventDefault()
    const companyId = window.location.pathname.split("/")[2]
    const parts = window.location.pathname.split("/")
    const id = parts[parts.length - 1]
    const form = event.target
    const data = new FormData(form)
    const payload = {
      payroll: {
        status: data.get("status"),
        notes: data.get("notes")
      }
    }
    try {
      await fetchJson(`${Helpers.company_payroll_payroll_path(companyId, id)}`, {
        method: "PATCH",
        body: payload
      })
      toast({ type: "success", message: "Payroll updated" })
      window.location.reload()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to update payroll" })
    }
  }

  contentHTML() {
    const p = this.payroll || {}
    const emp = p.employee || {}
    const meta = p.metadata || {}
    const daysHtml = this.attendanceDays.map(d => `
      <tr class="border-b border-line">
        <td class="py-2 px-4 text-sm">${d.attendance_date || "—"}</td>
        <td class="py-2 px-4 text-sm">${d.check_in ? new Date(d.check_in).toLocaleString() : "—"}</td>
        <td class="py-2 px-4 text-sm">${d.check_out ? new Date(d.check_out).toLocaleString() : "—"}</td>
        <td class="py-2 px-4 text-sm">${d.total_seconds_worked ?? "—"}</td>
        <td class="py-2 px-4 text-sm">${d.attendance_status || "—"}</td>
      </tr>
    `).join("")

    return `
      <div class="p-4 overflow-y-auto space-y-6">
        <div class="p-4 bg-card rounded-xl border border-line">
          <h2 class="text-xl font-bold text-foreground mb-2">Payroll Detail</h2>
          <p class="text-sm text-muted-foreground">Employee: ${emp.name || "—"}</p>
          <p class="text-sm text-muted-foreground">Month: ${p.month || "—"}</p>
          <p class="text-sm text-muted-foreground">Status: ${p.status || "—"}</p>
          <p class="text-sm text-muted-foreground">Work minutes: ${meta.total_work_minutes ?? "—"}</p>
        </div>

        <form data-action="submit->${this.identifier}#handleSubmit" class="p-4 bg-card rounded-xl border border-line space-y-4 max-w-xl">
          <div>
            <label class="text-xs text-muted-foreground uppercase">Status</label>
            <select name="status" class="w-full px-3 py-2 border rounded-lg text-sm">
              <option value="draft" ${p.status === "draft" ? "selected" : ""}>Draft</option>
              <option value="approved" ${p.status === "approved" ? "selected" : ""}>Approved</option>
              <option value="paid" ${p.status === "paid" ? "selected" : ""}>Paid</option>
            </select>
          </div>
          <div>
            <label class="text-xs text-muted-foreground uppercase">Notes</label>
            <textarea name="notes" class="w-full px-3 py-2 border rounded-lg text-sm">${p.notes || ""}</textarea>
          </div>
          <button type="submit" class="px-4 py-2 bg-primary text-primary-foreground rounded-lg text-sm">Save</button>
        </form>

        <div class="bg-card rounded-xl border border-line overflow-x-auto">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-line">
                <th class="py-2 px-4 text-xs text-muted-foreground uppercase">Date</th>
                <th class="py-2 px-4 text-xs text-muted-foreground uppercase">Check In</th>
                <th class="py-2 px-4 text-xs text-muted-foreground uppercase">Check Out</th>
                <th class="py-2 px-4 text-xs text-muted-foreground uppercase">Worked (s)</th>
                <th class="py-2 px-4 text-xs text-muted-foreground uppercase">Status</th>
              </tr>
            </thead>
            <tbody>
              ${daysHtml || `<tr><td class="py-8 text-center text-muted-foreground" colspan="5">No attendance days</td></tr>`}
            </tbody>
          </table>
        </div>
      </div>
    `
  }
}
