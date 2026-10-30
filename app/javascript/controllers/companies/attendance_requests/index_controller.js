import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceRequests_IndexController extends Companies_LayoutController {
  // Attendance request queue — pending requests get Approve/Reject controls.
  // Depends on BE: Companies::AttendanceRequestsController#index (JSON), #approve, #reject
  // Endpoints: GET <pathname>.json?employee_name&status&business_type&from&to, POST .../attendance_requests/:id/approve, POST .../:id/reject
  // Docs: docs/superpowers/specs/2026-10-08-attendance-request-design.md, docs/HR.md
  static targets = ["requestsList"]

  /** @type {Array} */
  attendanceRequests = []

  async connect() {
    super.connect()
    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
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
      pending: 'bg-warning/10 text-warning ',
      approved: 'bg-success/10 text-success ',
      rejected: 'bg-danger/10 text-danger '
    }
    const color = colors[status] || 'bg-muted text-foreground'
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
    const employeeNameValue = urlParams.get('employee_name') || ''
    const statusValue = urlParams.get('status') || ''
    const businessTypeValue = urlParams.get('business_type') || ''
    const fromValue = urlParams.get('from') || ''
    const toValue = urlParams.get('to') || ''
    const statusOptions = [ 'pending', 'approved', 'rejected' ]
      .map(s => `<option value="${s}" ${s === statusValue ? 'selected' : ''}>${Helpers.capitalize(s)}</option>`).join('')
    const businessTypeOptions = [ 'onsite_miss', 'remote_work', 'field_work' ]
      .map(t => `<option value="${t}" ${t === businessTypeValue ? 'selected' : ''}>${Helpers.capitalize(t.replace('_', ' '))}</option>`).join('')

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-xl font-bold text-foreground">${translate("Attendance Requests")}</h2>
            <a href="${Helpers.new_company_attendance_request_path(currentCompany().id)}"
              class="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("Add")}
            </a>
          </div>
          <form
            method="get"
            action="${pathname()}"
            class="flex flex-col lg:flex-row items-end gap-4 mb-6 w-full"
          >
            <div class="flex flex-wrap items-end gap-3 w-full lg:w-auto">
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Employee Name")}</label>
              <input type="text" name="employee_name" value="${employeeNameValue.replace(/"/g, '&quot;')}" placeholder="${translate("e.g. John Doe")}" class="px-3 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground" />
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Status")}</label>
              <select
                name="status"
                class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground"
              >
                <option value="">${translate("All")}</option>
                ${statusOptions}
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Business Type")}</label>
              <select
                name="business_type"
                class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground"
              >
                <option value="">${translate("All")}</option>
                ${businessTypeOptions}
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
            <button
              type="submit"
              class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm flex items-center gap-2 cursor-pointer"
            >
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
                  <th class="py-4 px-6 font-medium">${translate("Reason")}</th>
                  <th class="py-4 px-6 font-medium">${translate("Status")}</th>
                  <th class="py-4 px-6 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody data-${this.identifier}-target="requestsList" class="divide-y divide-line">
                ${this.attendanceRequests.map(r => `
                  <tr class="hover:bg-muted/50">
                    <td class="py-4 px-6 text-sm font-medium">
                      <a href="${Helpers.company_attendance_request_path(currentCompany().id, r.id)}"
                        class="text-foreground hover:text-primary cursor-pointer">
                        ${r.employee?.name || '—'}
                      </a>
                    </td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatDate(r.attendance_date)}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatTime(r.check_in)}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${this.formatTime(r.check_out)}</td>
                    <td class="py-4 px-6 text-sm text-muted-foreground">${r.reason || '—'}</td>
                    <td class="py-4 px-6 text-sm">${this.statusBadge(r.status)}</td>
                    <td class="py-4 px-6 text-sm text-right whitespace-nowrap">
                      ${r.status === 'pending' ? `
                        <button
                          type="button"
                          data-action="click->${this.identifier}#approve"
                          data-${this.identifier}-request-id-param="${r.id}"
                          class="px-3 py-1 bg-success hover:bg-success/90 text-success-foreground rounded-lg font-medium text-xs cursor-pointer"
                        >
                          ${translate("Approve")}
                        </button>
                        <button
                          type="button"
                          data-action="click->${this.identifier}#reject"
                          data-${this.identifier}-request-id-param="${r.id}"
                          class="px-3 py-1 bg-danger/10 hover:bg-danger/10 text-danger rounded-lg font-medium text-xs cursor-pointer"
                        >
                          ${translate("Reject")}
                        </button>
                      ` : `
                        <a href="${Helpers.company_attendance_request_path(currentCompany().id, r.id)}"
                          class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer">
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
