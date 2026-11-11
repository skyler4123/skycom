import { Controller } from "@hotwired/stimulus"
import { escapeHtml, translate, form } from "controllers/helpers/ui_helpers"
import {
  mobileHeader,
  mobileMain,
  mobileInitials,
  mobileBusinessTypeLabel,
  renderMobileError
} from "controllers/helpers/mobile_helpers"

// Mobile attendance request form — native POST so the success redirect and
// flash stay unchanged; invalid submissions come back as the same shell with
// data-errors/data-values.
// Depends on BE: Mobile::Companies::AttendanceRequestsController#new|create
// Endpoints: GET ../attendance_requests/new.json, POST ../attendance_requests
// Docs: docs/MOBILE.md §2-§4
export default class Mobile_Companies_AttendanceRequests_NewController extends Controller {
  async connect() {
    document.title = "New Request"

    try {
      const data = await fetchJson(this.element.dataset.jsonUrl)
      this.element.innerHTML = this.contentHTML(data)
    } catch (error) {
      renderMobileError(this.element, error, () => this.connect())
    }
  }

  parseErrors() {
    try {
      const parsed = this.element.dataset.errors ? JSON.parse(this.element.dataset.errors) : []
      return Array.isArray(parsed) ? parsed : []
    } catch (e) {
      return []
    }
  }

  parseValues() {
    try {
      return this.element.dataset.values ? JSON.parse(this.element.dataset.values) : {}
    } catch (e) {
      return {}
    }
  }

  contentHTML({ company, employee, managers = [], business_types: businessTypes = [], defaults = {} }) {
    const errors = this.parseErrors()
    const values = this.parseValues()
    const attendanceMonthPath = Helpers.mobile_company_attendance_month_path(company.id)

    const attendanceDate = values.attendance_date || defaults.attendance_date || ""
    const businessType = values.business_type || defaults.business_type || businessTypes[0] || ""
    const checkIn = values.check_in_time || defaults.check_in_time || ""
    const checkOut = values.check_out_time || defaults.check_out_time || ""
    const reason = values.reason || ""

    const fieldClass = "h-11 w-full rounded-lg border border-line bg-background px-3 pr-10 text-sm text-foreground outline-none transition-colors focus:border-primary/40 focus:bg-card"

    return `
      ${mobileHeader({
        title: "New Request",
        backPath: attendanceMonthPath,
        avatarName: employee.name,
        avatarPath: Helpers.mobile_company_employee_path(company.id)
      })}
      ${mobileMain(`
        <div class="flex flex-col gap-4">
          <section class="flex items-center justify-between gap-2 rounded-xl border border-line bg-muted p-4">
            <div class="flex min-w-0 items-center gap-3">
              <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary">
                <span class="material-symbols-outlined text-xl">event_repeat</span>
              </span>
              <div class="min-w-0">
                <p class="text-xs font-medium uppercase tracking-wider text-muted-foreground">${translate("Attendance Request")}</p>
                <p class="truncate text-sm font-semibold text-foreground">${escapeHtml(employee.name)}</p>
                <p class="truncate text-xs text-muted-foreground">${escapeHtml([ employee.branch_name, employee.company_name ].filter(Boolean).join(" • "))}</p>
              </div>
            </div>
            <span class="shrink-0 rounded-full bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">${translate("New")}</span>
          </section>

          ${errors.length ? `
            <section class="rounded-xl border border-danger/20 bg-danger/10 p-3">
              <p class="text-sm font-semibold text-danger">${translate("Please fix the following:")}</p>
              <ul class="mt-1 list-inside list-disc text-xs text-danger">
                ${errors.map((message) => `<li>${escapeHtml(message)}</li>`).join("")}
              </ul>
            </section>
          ` : ""}

          ${form({
            action: Helpers.mobile_company_attendance_requests_path(company.id),
            method: "POST",
            attributes: `data-turbo="false" class="flex flex-col gap-4"`,
            html: `
              <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
                <div class="flex items-center gap-2">
                  <span class="material-symbols-outlined text-xl text-primary">edit_calendar</span>
                  <h2 class="text-base font-semibold text-foreground">${translate("Request Details")}</h2>
                </div>

                <div class="mt-3 flex flex-col gap-3">
                  <div class="flex flex-col gap-1.5">
                    <label for="attendance_request_attendance_date" class="text-xs font-semibold text-foreground">${translate("Date")}</label>
                    <div class="relative flex items-center">
                      <input id="attendance_request_attendance_date" type="date" name="attendance_request[attendance_date]" value="${escapeHtml(attendanceDate)}" required
                        class="${fieldClass}" />
                      <span class="material-symbols-outlined pointer-events-none absolute right-3 text-xl text-muted-foreground">calendar_month</span>
                    </div>
                  </div>

                  <div class="flex flex-col gap-1.5">
                    <label for="attendance_request_business_type" class="text-xs font-semibold text-foreground">${translate("Type")}</label>
                    <div class="relative flex items-center">
                      <select id="attendance_request_business_type" name="attendance_request[business_type]"
                        class="h-11 w-full cursor-pointer appearance-none rounded-lg border border-line bg-background px-3 pr-10 text-sm text-foreground outline-none transition-colors focus:border-primary/40 focus:bg-card">
                        ${businessTypes.map((type) => `
                          <option value="${escapeHtml(type)}" ${type === businessType ? "selected" : ""}>${escapeHtml(mobileBusinessTypeLabel(type))}</option>
                        `).join("")}
                      </select>
                      <span class="material-symbols-outlined pointer-events-none absolute right-3 text-xl text-muted-foreground">keyboard_arrow_down</span>
                    </div>
                  </div>

                  <div class="grid grid-cols-2 gap-3 md:grid-cols-3 md:gap-4">
                    <div class="flex min-w-0 flex-col gap-1.5">
                      <label for="attendance_request_check_in_time" class="truncate text-xs font-semibold text-foreground">${translate("Check In")}</label>
                      <div class="relative flex items-center">
                        <input id="attendance_request_check_in_time" type="time" name="attendance_request[check_in_time]" value="${escapeHtml(checkIn)}" required
                          class="h-11 w-full rounded-lg border border-line bg-background px-3 pr-9 text-sm text-foreground outline-none transition-colors focus:border-primary/40 focus:bg-card" />
                        <span class="material-symbols-outlined pointer-events-none absolute right-2 text-lg text-muted-foreground">schedule</span>
                      </div>
                    </div>
                    <div class="flex min-w-0 flex-col gap-1.5">
                      <label for="attendance_request_check_out_time" class="truncate text-xs font-semibold text-foreground">${translate("Check Out")}</label>
                      <div class="relative flex items-center">
                        <input id="attendance_request_check_out_time" type="time" name="attendance_request[check_out_time]" value="${escapeHtml(checkOut)}"
                          class="h-11 w-full rounded-lg border border-line bg-background px-3 pr-9 text-sm text-foreground outline-none transition-colors focus:border-primary/40 focus:bg-card" />
                        <span class="material-symbols-outlined pointer-events-none absolute right-2 text-lg text-muted-foreground">history_toggle_off</span>
                      </div>
                    </div>
                  </div>
                </div>
              </section>

              <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
                <div class="flex items-center gap-2">
                  <span class="material-symbols-outlined text-xl text-primary">description</span>
                  <h2 class="text-base font-semibold text-foreground">${translate("Reason & Justification")}</h2>
                </div>

                <div class="mt-3 flex flex-col gap-1.5" data-controller="mobile--character-counter">
                  <div class="flex items-center justify-between gap-2">
                    <label for="attendance_request_reason" class="text-xs font-semibold text-foreground">${translate("Reason")}</label>
                    <span data-mobile--character-counter-target="output" class="text-xs text-muted-foreground">${reason.length}/240</span>
                  </div>
                  <textarea id="attendance_request_reason" name="attendance_request[reason]" rows="3" maxlength="240"
                    placeholder="${translate("Why could you not check in onsite?")}"
                    data-mobile--character-counter-target="input" data-action="input->mobile--character-counter#update"
                    class="w-full resize-none rounded-lg border border-line bg-background p-3 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-primary/40 focus:bg-card">${escapeHtml(reason)}</textarea>
                </div>

                <div class="mt-3 flex items-center justify-between gap-2 rounded-lg border border-dashed border-line bg-background p-3">
                  <div class="flex min-w-0 items-center gap-2">
                    <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-muted text-muted-foreground">
                      <span class="material-symbols-outlined text-xl">cloud_upload</span>
                    </span>
                    <div class="min-w-0">
                      <p class="text-sm font-medium text-muted-foreground">${translate("Attach photo or proof")}</p>
                      <p class="text-xs text-muted-foreground">${translate("Not available in the mobile app yet")}</p>
                    </div>
                  </div>
                  <span class="material-symbols-outlined shrink-0 text-xl text-muted-foreground/60">block</span>
                </div>
              </section>

              <section class="rounded-xl border border-line bg-background p-4">
                <div class="flex items-center gap-2">
                  <span class="material-symbols-outlined text-xl text-primary">supervisor_account</span>
                  <h2 class="text-base font-semibold text-foreground">${translate("Your Managers")}</h2>
                </div>
                <div class="mt-3 flex flex-col gap-2">
                  ${managers.length
                    ? managers.map((manager) => `
                        <div class="flex min-w-0 items-center gap-2 rounded-lg border border-line bg-card p-3">
                          <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary/10 text-sm font-bold text-primary">${escapeHtml(mobileInitials(manager.name))}</span>
                          <p class="truncate text-sm font-semibold text-foreground">${escapeHtml(manager.name)}</p>
                        </div>
                      `).join("")
                    : `<p class="text-sm text-muted-foreground">—</p>`}
                </div>
              </section>

              <div class="flex flex-col gap-2 pt-1">
                <button type="submit"
                  class="flex h-12 w-full cursor-pointer items-center justify-center gap-2 rounded-lg bg-primary text-sm font-bold text-primary-foreground shadow-sm transition-colors hover:bg-primary/90 active:scale-95">
                  ${translate("Submit Request")}
                </button>
                <a href="${attendanceMonthPath}"
                  class="flex h-11 w-full cursor-pointer items-center justify-center rounded-lg text-sm font-semibold text-muted-foreground transition-colors hover:bg-muted hover:text-foreground">
                  ${translate("Cancel")}
                </a>
              </div>
            `
          })}
        </div>
      `)}
    `
  }
}
