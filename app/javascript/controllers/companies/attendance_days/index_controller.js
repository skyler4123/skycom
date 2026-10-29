import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceDays_IndexController extends Companies_LayoutController {
  // Attendance days dashboard with employee-name search, status + date-range filters.
  // Depends on BE: Companies::AttendanceDaysController#index (JSON)
  // Endpoints: GET <pathname>.json?employee_name&attendance_status&from&to — traditional GET form, full-page submit
  // Docs: docs/HR.md
  static targets = ["attendanceDaysList"]

  /** @type {Array<{id: string, employee: {name: string}, attendance_date: string, check_in: string, check_out: string, total_seconds_worked: number, attendance_status: string}>} */
  attendanceDays = []

  async connect() {
    super.connect()
    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.attendanceDays = response.attendance_days || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance records") }${__errDetail ? ": " + __errDetail : ""}` })
    }
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  formatDate(dateStr) {
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

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const employeeNameValue = urlParams.get('employee_name') || ''
    const statusValue = urlParams.get('attendance_status') || ''
    const fromValue = urlParams.get('from') || ''
    const toValue = urlParams.get('to') || ''
    const statusOptions = [ 'present', 'half_day', 'late', 'absent', 'missing_checkout' ]
      .map(s => `<option value="${s}" ${s === statusValue ? 'selected' : ''}>${Helpers.capitalize(s.replace('_', ' '))}</option>`).join('')

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">
          <h2 class="text-xl font-bold text-foreground mb-6">${translate("Attendance Days")}</h2>
          <form method="get" action="${pathname()}" class="flex flex-col lg:flex-row items-end gap-4 mb-6 w-full">
            <div class="flex flex-wrap items-end gap-3 w-full lg:w-auto">
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Employee Name")}</label>
                <input type="text" name="employee_name" value="${employeeNameValue.replace(/"/g, '&quot;')}" placeholder="${translate("e.g. John Doe")}" class="px-3 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Attendance Status")}</label>
                <select name="attendance_status" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                  <option value="">${translate("All")}</option>
                  ${statusOptions}
                </select>
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("From")}</label>
                <input type="date" name="from" value="${fromValue}" class="px-3 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground" />
              </div>
              <div class="flex flex-col gap-1">
                <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("To")}</label>
                <input type="date" name="to" value="${toValue}" class="px-3 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground" />
              </div>
              <div class="flex gap-2 mt-auto">
                <button type="submit" class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg transition-colors font-medium text-sm flex items-center gap-2 cursor-pointer">
                  <span class="material-symbols-outlined text-[18px]!">search</span>
                  ${translate("Search")}
                </button>
              </div>
            </div>
          </form>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-muted-foreground border-b border-line">
                  <th class="py-4 px-6 font-medium">${translate("Employee")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Date")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Check In")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Check Out")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Worked")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Status")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="attendanceDaysList" class="divide-y divide-line">
                ${this.attendanceDays.map(d => `
                  <tr class="hover:bg-muted/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_attendance_day_path(currentCompany().id, d.id)}"
                        class="text-foreground hover:text-primary cursor-pointer">
                        ${d.employee?.name || '—'}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatDate(d.attendance_date)}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatTime(d.check_in)}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatTime(d.check_out)}</td>
                    <td class="py-4 px-6 text-sm text-foreground font-medium">${Math.round((d.total_seconds_worked || 0) / 60)}min</td>
                    <td class="py-4 px-6 text-sm">${this.statusBadge(d.attendance_status)}</td>
                    <td class="py-4 px-6 text-sm text-right">
                      <a href="${Helpers.company_attendance_day_path(currentCompany().id, d.id)}"
                        class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </a>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
          <div class="flex justify-center pt-6">
            ${pagination(this.pagination)}
          </div>
        </div>
      </div>
    `
  }
}
