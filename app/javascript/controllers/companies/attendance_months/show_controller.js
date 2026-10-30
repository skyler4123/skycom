import Companies_LayoutController from "controllers/companies/layout_controller"

// Depends on BE: Companies::AttendanceMonthsController#show (JSON with attendance_month + attendance_days), #collect
// Docs: docs/HR.md
export default class Companies_AttendanceMonths_ShowController extends Companies_LayoutController {
  /** @type {Object|null} */
  attendanceMonth = null

  /** @type {Array} */
  attendanceDays = []

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_attendance_month_path(currentCompany().id, id)}.json`)
      this.attendanceMonth = response.attendance_month
      this.attendanceDays = response.attendance_days || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance month") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  formatDate(dateStr) {
    if (!dateStr) return '—'
    const d = new Date(dateStr + 'T00:00:00')
    return d.toLocaleDateString('en-GB', { month: 'long', year: 'numeric' })
  }

  formatDayDate(dateStr) {
    if (!dateStr) return '—'
    return new Date(dateStr + 'T00:00:00').toLocaleDateString()
  }

  formatTime(dt) {
    if (!dt) return '—'
    return new Date(dt).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
  }

  statusBadge(status) {
    const colors = {
      present: 'bg-success/10 text-success ',
      half_day: 'bg-warning/10 text-warning ',
      late: 'bg-danger/10 text-danger ',
      absent: 'bg-muted text-foreground ',
      missing_checkout: 'bg-warning/10 text-warning '
    }
    const color = colors[status] || 'bg-muted text-foreground'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(status?.replace('_', ' ') || '')}</span>`
  }

  async collect() {
    const companyId = currentCompany().id
    try {
      const response = await fetchJson(`${Helpers.company_attendance_months_collect_path(companyId)}`, {
        method: "POST"
      })
      toast({ type: "success", message: response.message || "Attendance data collected" })
      window.location.reload()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to collect attendance data" })
    }
  }

  contentHTML() {
    const m = this.attendanceMonth
    if (!m) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <div class="flex items-center justify-between mb-6">
            <a href="${Helpers.company_attendance_months_path(currentCompany().id)}"
              class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
              ${translate("Back")}
            </a>
            <button type="button" data-action="click->${this.identifier}#collect" class="px-4 py-2 bg-success hover:bg-success/90 text-success-foreground rounded-lg transition-colors font-medium text-sm flex items-center gap-2 cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">sync</span>
              ${translate("Collect Data")}
            </button>
          </div>
          <h2 class="text-2xl font-black text-foreground mb-6">${translate("Attendance Month")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-foreground">${m.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Month")}</p>
              <p class="text-sm font-semibold text-foreground">${this.formatDate(m.month)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Total Worked")}</p>
              <p class="text-sm font-semibold text-foreground">${m.total_work_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Late")}</p>
              <p class="text-sm font-semibold text-foreground">${m.total_late_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Early Leave")}</p>
              <p class="text-sm font-semibold text-foreground">${m.total_early_leave_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Overtime")}</p>
              <p class="text-sm font-semibold text-foreground">${m.total_overtime_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Days Present")}</p>
              <p class="text-sm font-semibold text-foreground">${m.total_present_days || 0}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Days Absent")}</p>
              <p class="text-sm font-semibold text-foreground">${m.total_absent_days || 0}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-muted-foreground">${translate("Deficit")}</p>
              <p class="text-sm font-semibold text-foreground">${m.total_deficit_minutes || 0} min</p>
            </div>
          </div>
          <div class="mt-8 border-t border-line pt-6">
            <h3 class="text-lg font-bold text-foreground mb-4">${translate("Daily Breakdown")}</h3>
            ${this.attendanceDays.length === 0 ? `<p class="text-sm text-muted-foreground">${translate("No daily records for this month yet.")}</p>` : `
              <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                  <thead>
                    <tr class="text-sm text-muted-foreground border-b border-line">
                      <th class="py-4 px-6 font-medium">${translate("Date")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Check In")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Check Out")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Worked")}</th>
                      <th class="py-4 px-6 font-medium">${translate("Status")}</th>
                      <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-line">
                    ${this.attendanceDays.map(d => `
                      <tr class="hover:bg-muted/50">
                        <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatDayDate(d.attendance_date)}</td>
                        <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatTime(d.check_in)}</td>
                        <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatTime(d.check_out)}</td>
                        <td class="py-4 px-6 text-sm text-foreground font-medium">${Math.round((d.total_seconds_worked || 0) / 60)}min</td>
                        <td class="py-4 px-6 text-sm">${this.statusBadge(d.attendance_status)}</td>
                        <td class="py-4 px-6 text-sm text-right">
                          <a href="${Helpers.company_attendance_day_path(currentCompany().id, d.id)}" class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                            <span class="material-symbols-outlined text-[20px]">visibility</span>
                          </a>
                        </td>
                      </tr>
                    `).join('')}
                  </tbody>
                </table>
              </div>
            `}
          </div>
        </div>
      </div>
    `
  }
}
