import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceRequests_ShowController extends Companies_LayoutController {
  // Attendance request detail + approve/reject controls + linked day card.
  // Depends on BE: Companies::AttendanceRequestsController#show, #approve, #reject
  // Endpoints: GET company_attendance_request_path.json, POST .../approve, POST .../reject
  // Docs: docs/superpowers/specs/2026-10-08-attendance-request-design.md
  /** @type {Object|null} */
  attendanceRequest = null

  /** @type {Object|null} */
  attendanceDay = null

  async connect() {
    super.connect()
    const id = window.location.pathname.split("/").pop()
    try {
      const response = await fetchJson(`${Helpers.company_attendance_request_path(currentCompany().id, id)}.json`)
      this.attendanceRequest = response.attendance_request
      this.attendanceDay = response.attendance_day
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance request") }${__errDetail ? ": " + __errDetail : ""}` })
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

  async approve(event) {
    event.preventDefault()
    const companyId = currentCompany().id
    try {
      const response = await fetchJson(Helpers.approve_company_attendance_request_path(companyId, this.attendanceRequest.id), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message || translate("Attendance request approved") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to approve request") })
    }
  }

  async reject(event) {
    event.preventDefault()
    const companyId = currentCompany().id
    try {
      const response = await fetchJson(Helpers.reject_company_attendance_request_path(companyId, this.attendanceRequest.id), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message || translate("Attendance request rejected") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to reject request") })
    }
  }

  contentHTML() {
    const r = this.attendanceRequest
    if (!r) return '<div class="p-8 text-center">Not found.</div>'

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_attendance_requests_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back")}
          </a>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white mb-6">${translate("Attendance Request")}</h2>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Employee")}</p>
              <p class="text-sm font-semibold text-slate-900">${r.employee?.name || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Date")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatDate(r.attendance_date)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Check In")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatTime(r.check_in)}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Check Out")}</p>
              <p class="text-sm font-semibold text-slate-900">${this.formatTime(r.check_out)}</p>
            </div>
            <div class="col-span-2">
              <p class="text-xs font-medium text-slate-500">${translate("Reason")}</p>
              <p class="text-sm font-semibold text-slate-900">${r.reason || '—'}</p>
            </div>
            <div>
              <p class="text-xs font-medium text-slate-500">${translate("Status")}</p>
              <p class="text-sm font-semibold text-slate-900">${Helpers.capitalize(r.status || '')}</p>
            </div>
            ${this.attendanceDay ? `
              <div>
                <p class="text-xs font-medium text-slate-500">${translate("Attendance Day")}</p>
                <p class="text-sm font-semibold text-slate-900">${this.formatDate(this.attendanceDay.attendance_date)} — ${Helpers.capitalize(this.attendanceDay.attendance_status || '')}</p>
              </div>
            ` : ''}
          </div>
          ${r.status === 'pending' ? `
            <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
              <button
                type="button"
                data-action="click->${this.identifier}#reject"
                class="px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-50 rounded-lg cursor-pointer"
              >
                ${translate("Reject")}
              </button>
              <button
                type="button"
                data-action="click->${this.identifier}#approve"
                class="px-6 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg font-bold text-sm cursor-pointer"
              >
                ${translate("Approve")}
              </button>
            </div>
          ` : ''}
        </div>
      </div>
    `
  }
}
