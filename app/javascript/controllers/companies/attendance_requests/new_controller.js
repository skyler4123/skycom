import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_AttendanceRequests_NewController extends Companies_LayoutController {
  // New Attendance Request form — filed for self (employee forced server-side).
  // Depends on BE: Companies::AttendanceRequestsController#create
  // Endpoints: POST /companies/:company_id/attendance_requests
  // Docs: docs/superpowers/specs/2026-10-08-attendance-request-design.md
  connect() {
    super.connect()
    poll(() => {
      if (this.hasContentTarget) { this.renderContent(); return true }
      return false
    })
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Attendance Request")}</h2>
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Date")}</label>
            <input type="date" name="attendance_request[attendance_date]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Type")}</label>
            <select name="attendance_request[business_type]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
              <option value="onsite_miss">${translate("Onsite Miss")}</option>
              <option value="remote_work">${translate("Remote Work")}</option>
              <option value="field_work">${translate("Field Work")}</option>
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Check In")}</label>
            <input type="datetime-local" name="attendance_request[check_in]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Check Out")}</label>
            <input type="datetime-local" name="attendance_request[check_out]"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm">
          </div>
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Reason")}</label>
            <textarea name="attendance_request[reason]" rows="3" required placeholder="${translate("Why could you not check in onsite?")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm"></textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_attendance_requests_path(currentCompany().id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.create_company_attendance_requests_path(currentCompany().id),
          method: "POST",
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
