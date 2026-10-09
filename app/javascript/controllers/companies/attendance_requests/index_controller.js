import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceRequests_IndexController extends Companies_LayoutController {
  // Attendance request queue — pending requests get Approve/Reject controls.
  // Depends on BE: Companies::AttendanceRequestsController#index (JSON), #approve, #reject
  // Endpoints: GET <pathname>.json, POST .../attendance_requests/:id/approve, POST .../:id/reject
  // Docs: docs/superpowers/specs/2026-10-08-attendance-request-design.md, docs/HR.md
  static targets = ["requestsList"]

  /** @type {Array} */
  attendanceRequests = []

  async connect() {
    super.connect()
    try {
      const response = await fetchJson()
      this.attendanceRequests = response.attendance_requests || []
      this.pagination = response.pagination || {}
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load attendance requests") }${__errDetail ? ": " + __errDetail : ""}` })
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
      pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300',
      approved: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
      rejected: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300'
    }
    const color = colors[status] || 'bg-gray-100 text-gray-800'
    return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${color}">${Helpers.capitalize(status?.replace('_', ' ') || '')}</span>`
  }

  async approve(event) {
    event.preventDefault()
    const { requestId } = event.params
    const companyId = currentCompany().id
    try {
      const response = await fetchJson(Helpers.approve_company_attendance_request_path(companyId, requestId), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message || translate("Attendance request approved") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to approve request") })
    }
  }

  async reject(event) {
    event.preventDefault()
    const { requestId } = event.params
    const companyId = currentCompany().id
    try {
      const response = await fetchJson(Helpers.reject_company_attendance_request_path(companyId, requestId), {
        method: "POST"
      })
      reloadThenToast({ type: "success", message: response.message || translate("Attendance request rejected") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to reject request") })
    }
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)
    const statusValue = urlParams.get('status') || ''
    const statusOptions = [ 'pending', 'approved', 'rejected' ]
      .map(s => `<option value="${s}" ${s === statusValue ? 'selected' : ''}>${Helpers.capitalize(s)}</option>`).join('')

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Attendance Requests")}</h2>
            <a href="${Helpers.new_company_attendance_request_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>
          <form
            method="get"
            action="${pathname()}"
            class="flex flex-wrap items-end gap-3 mb-6"
          >
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-slate-400 uppercase ml-1">${translate("Status")}</label>
              <select
                name="status"
                class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300"
              >
                <option value="">${translate("All")}</option>
                ${statusOptions}
              </select>
            </div>
            <button
              type="submit"
              class="h-[38px] px-6 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm flex items-center gap-2 cursor-pointer"
            >
              <span class="material-symbols-outlined text-[18px]!">search</span>
              ${translate("Search")}
            </button>
          </form>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium">${translate("Employee")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Date")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Check In")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Check Out")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Reason")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Status")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="requestsList" class="divide-y divide-slate-200 dark:divide-slate-800">
                ${this.attendanceRequests.map(r => `
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_attendance_request_path(currentCompany().id, r.id)}"
                        class="text-slate-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 cursor-pointer">
                        ${r.employee?.name || '—'}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatDate(r.attendance_date)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatTime(r.check_in)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${this.formatTime(r.check_out)}</td>
                    <td class="py-4 px-6 text-sm text-slate-600">${r.reason || '—'}</td>
                    <td class="py-4 px-6 text-sm">${this.statusBadge(r.status)}</td>
                    <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                      ${r.status === 'pending' ? `
                        <button
                          type="button"
                          data-action="click->${this.identifier}#approve"
                          data-${this.identifier}-request-id-param="${r.id}"
                          class="px-3 py-1 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium text-xs cursor-pointer"
                        >
                          ${translate("Approve")}
                        </button>
                        <button
                          type="button"
                          data-action="click->${this.identifier}#reject"
                          data-${this.identifier}-request-id-param="${r.id}"
                          class="px-3 py-1 bg-red-50 hover:bg-red-100 text-red-600 rounded-lg font-medium text-xs cursor-pointer"
                        >
                          ${translate("Reject")}
                        </button>
                      ` : `
                        <a href="${Helpers.company_attendance_request_path(currentCompany().id, r.id)}"
                          class="inline-flex items-center justify-center p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg cursor-pointer">
                          <span class="material-symbols-outlined text-[20px]">visibility</span>
                        </a>
                      `}
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
