import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceMonths_ShowController extends Companies_LayoutController {
  /** @type {Object|null} */
  attendanceMonth = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_attendance_month_path(currentCompany().id, id)}.json`)
      this.attendanceMonth = response.attendance_month
    } catch (error) {
      toast({ type: "error", message: translate("Failed to load attendance month") })
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

  contentHTML() {
    const m = this.attendanceMonth
    if (!m) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_attendance_months_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Attendance Month")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Month")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatDate(m.month)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Total Worked")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_work_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Late")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_late_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Early Leave")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_early_leave_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Overtime")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_overtime_minutes || 0} min</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Days Present")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_present_days || 0}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Days Absent")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_absent_days || 0}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Deficit")}</p>
              <p class="text-sm font-semibold text-slate-900">${m.total_deficit_minutes || 0} min</p>
            </div>
          </div>
        </div>
      </div>
    `
  }
}
