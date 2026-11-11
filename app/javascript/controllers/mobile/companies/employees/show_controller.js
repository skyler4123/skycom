import { Controller } from "@hotwired/stimulus"
import { escapeHtml, translate, form } from "controllers/helpers/ui_helpers"
import {
  mobileHeader,
  mobileMain,
  mobileAvatar,
  mobileDate,
  mobileShortDate,
  mobileTime,
  mobileDuration,
  mobileEmployeeTypeLabel,
  renderMobileError
} from "controllers/helpers/mobile_helpers"

// Mobile profile — the signed-in employee's identity, contact, assignment,
// attendance summary and payroll entry point.
// Depends on BE: Mobile::Companies::EmployeesController#show
// Endpoints: GET /mobile/companies/:company_id/employee.json
// Docs: docs/MOBILE.md §2-§3
export default class Mobile_Companies_Employees_ShowController extends Controller {
  async connect() {
    document.title = "Profile"

    try {
      const data = await fetchJson(this.element.dataset.jsonUrl)
      this.element.innerHTML = this.contentHTML(data)
    } catch (error) {
      renderMobileError(this.element, error, () => this.connect())
    }
  }

  contentHTML(data) {
    const { company, employee } = data

    return `
      ${mobileHeader({
        title: "Profile",
        avatarName: employee.name,
        avatarPath: Helpers.mobile_company_employee_path(company.id)
      })}
      ${mobileMain(`
        <div class="flex flex-col gap-4">
          ${this.identityHTML(data)}
          ${this.accountHTML(data)}
          ${this.signedInAccountHTML(data)}
          ${this.organizationHTML(data)}
          ${this.workHTML(data)}
          ${this.actionsHTML(data)}
        </div>
      `)}
    `
  }

  identityHTML({ company, employee }) {
    return `
      <section class="relative overflow-hidden rounded-xl border border-line bg-card p-6 text-center shadow-sm">
        <div class="pointer-events-none absolute -right-12 -top-12 h-36 w-36 rounded-full bg-primary/10"></div>
        <div class="relative flex flex-col items-center">
          <div class="relative">
            ${mobileAvatar({ name: employee.name, size: "h-20 w-20 text-2xl" })}
            <span class="absolute -bottom-1 -right-1 flex h-6 w-6 items-center justify-center rounded-full bg-success text-success-foreground shadow-sm">
              <span class="material-symbols-outlined text-base">check</span>
            </span>
          </div>
          <div class="mt-3 flex flex-wrap items-center justify-center gap-2">
            <h2 class="text-xl font-bold text-foreground">${escapeHtml(employee.name)}</h2>
            ${employee.code ? `<span class="rounded-full bg-muted px-2 py-0.5 text-xs font-medium text-muted-foreground">${escapeHtml(employee.code)}</span>` : ""}
          </div>
          <p class="mt-1 text-sm text-muted-foreground">${escapeHtml(employee.category_name || company.name)}</p>

          <div class="mt-3 flex flex-wrap items-center justify-center gap-1.5">
            <span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
              <span class="material-symbols-outlined text-base">verified_user</span>
              ${escapeHtml(mobileEmployeeTypeLabel(employee.business_type))}
            </span>
            ${(employee.roles || []).map((role) => `
              <span class="inline-flex items-center gap-1 rounded-full bg-muted px-3 py-1 text-xs font-medium text-muted-foreground">
                <span class="material-symbols-outlined text-base">workspace_premium</span>
                ${escapeHtml(role)}
              </span>
            `).join("")}
            ${employee.category_name ? `
              <span class="inline-flex items-center gap-1 rounded-full bg-muted px-3 py-1 text-xs font-medium text-muted-foreground">
                <span class="material-symbols-outlined text-base">category</span>
                ${escapeHtml(employee.category_name)}
              </span>
            ` : ""}
          </div>
        </div>
      </section>
    `
  }

  accountHTML({ employee }) {
    return `
      <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="flex items-center gap-2">
          <span class="material-symbols-outlined text-xl text-primary">badge</span>
          <h2 class="text-base font-semibold text-foreground">${translate("Account & Contact")}</h2>
        </div>

        <div class="mt-3 flex flex-col gap-2">
          <div data-controller="mobile--copy" class="flex items-center justify-between gap-2 rounded-lg border border-line bg-background p-3">
            <div class="flex min-w-0 items-center gap-2">
              <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-card text-muted-foreground">
                <span class="material-symbols-outlined text-lg">alternate_email</span>
              </span>
              <div class="min-w-0">
                <p class="text-xs text-muted-foreground">${translate("Work Email")}</p>
                <p data-mobile--copy-target="source" class="truncate text-sm text-foreground">${escapeHtml(employee.email || "—")}</p>
              </div>
            </div>
            <button type="button" data-action="click->mobile--copy#copy" aria-label="${translate("Copy email")}"
              class="flex h-9 w-9 shrink-0 cursor-pointer items-center justify-center rounded-lg bg-card text-primary transition-colors hover:bg-primary/90 hover:text-primary-foreground">
              <span class="material-symbols-outlined text-lg">content_copy</span>
            </button>
          </div>

          ${this.fieldHTML({ icon: "call", label: "Phone Number", value: employee.phone_number })}
          ${this.fieldHTML({ icon: "fingerprint", label: "System Staff ID", value: employee.code })}
        </div>
      </section>
    `
  }

  signedInAccountHTML({ user }) {
    return `
      <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="flex items-center gap-2">
          <span class="material-symbols-outlined text-xl text-primary">account_circle</span>
          <h2 class="text-base font-semibold text-foreground">${translate("Signed-in Account")}</h2>
        </div>

        <div class="mt-3 flex flex-col gap-2">
          ${this.fieldHTML({ icon: "alternate_email", label: "Account Email", value: user.email })}
          ${this.fieldHTML({ icon: "person", label: "Account Name", value: user.name })}
          ${this.fieldHTML({ icon: "admin_panel_settings", label: "System Role", value: user.system_role_label })}
          ${this.fieldHTML({ icon: "call", label: "Account Phone", value: user.phone_number })}
          ${user.username ? this.fieldHTML({ icon: "badge", label: "Username", value: user.username }) : ""}
        </div>
      </section>
    `
  }

  organizationHTML({ company, employee, managers = [] }) {
    return `
      <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="flex items-center gap-2">
          <span class="material-symbols-outlined text-xl text-primary">corporate_fare</span>
          <h2 class="text-base font-semibold text-foreground">${translate("Organization & Assignment")}</h2>
        </div>

        <div class="mt-3 grid grid-cols-2 gap-2 md:grid-cols-3 md:gap-4">
          <div class="rounded-lg border border-line bg-background p-3">
            <div class="flex items-center gap-1 text-muted-foreground">
              <span class="material-symbols-outlined text-base">domain</span>
              <span class="text-xs">${translate("Company")}</span>
            </div>
            <p class="mt-1 text-sm font-semibold leading-tight text-foreground">${escapeHtml(company.name)}</p>
          </div>
          <div class="rounded-lg border border-line bg-background p-3">
            <div class="flex items-center gap-1 text-muted-foreground">
              <span class="material-symbols-outlined text-base">storefront</span>
              <span class="text-xs">${translate("Branch")}</span>
            </div>
            <p class="mt-1 text-sm font-semibold leading-tight text-foreground">${escapeHtml(employee.branch_name || "—")}</p>
          </div>
        </div>

        <div class="mt-2 flex flex-col gap-2 rounded-lg border border-line bg-background p-3">
          <div class="flex items-center justify-between gap-2">
            <span class="text-xs text-muted-foreground">${translate("Department")}</span>
            <span class="truncate text-sm font-medium text-foreground">${escapeHtml((employee.departments || []).join(", ") || "—")}</span>
          </div>
          <div class="h-px w-full bg-muted"></div>
          <div class="flex items-start justify-between gap-2">
            <span class="shrink-0 text-xs text-muted-foreground">${translate("Reports To")}</span>
            <div class="flex min-w-0 flex-col items-end gap-1">
              ${managers.length
                ? managers.map((manager) => `<span class="truncate text-sm font-medium text-foreground">${escapeHtml(manager.name)}</span>`).join("")
                : `<span class="text-sm font-medium text-foreground">—</span>`}
            </div>
          </div>
        </div>
      </section>
    `
  }

  workHTML({ employee, attendance_month: attendanceMonth, next_shift: nextShift }) {
    const nextShiftText = nextShift
      ? `${mobileShortDate(nextShift.work_date)} · ${mobileTime(nextShift.expected_start_at)} – ${mobileTime(nextShift.expected_end_at)}`
      : translate("No scheduled shift")

    return `
      <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="flex items-center gap-2">
          <span class="material-symbols-outlined text-xl text-primary">calendar_month</span>
          <h2 class="text-base font-semibold text-foreground">${translate("Work & Attendance")}</h2>
        </div>

        <div class="mt-3 flex flex-col gap-2 rounded-lg border border-line bg-background p-3">
          <div class="flex items-center justify-between gap-2">
            <span class="text-xs text-muted-foreground">${translate("Next Shift")}</span>
            <span class="truncate text-sm font-medium text-foreground">${escapeHtml(nextShiftText)}</span>
          </div>
          <div class="h-px w-full bg-muted"></div>
          ${this.rowHTML("This Month", mobileDuration(attendanceMonth?.total_work_minutes))}
          ${this.rowHTML("Present", `${attendanceMonth?.total_present_days || 0} ${translate("Days")}`)}
          ${this.rowHTML("Overtime", mobileDuration(attendanceMonth?.total_overtime_minutes))}
          <div class="h-px w-full bg-muted"></div>
          ${this.rowHTML("Contract Renewal", mobileDate(employee.expiration_date))}
        </div>
      </section>
    `
  }

  actionsHTML({ company }) {
    const signOutForm = form({
      action: Helpers.mobile_sign_out_path(),
      method: "DELETE",
      attributes: `data-turbo="false"`,
      html: `<button type="submit" class="flex h-11 w-full cursor-pointer items-center justify-center gap-2 rounded-lg bg-danger/10 text-sm font-semibold text-danger transition-colors hover:bg-danger/10">
        ${translate("Sign Out")}
      </button>`
    })

    return `
      <div class="flex flex-col gap-2 pt-1">
        <a href="${Helpers.mobile_company_payroll_unlock_path(company.id)}"
          class="group flex cursor-pointer items-center justify-between gap-3 rounded-xl border border-line bg-card p-4 text-left shadow-sm transition-colors hover:border-primary/30">
          <div class="flex min-w-0 items-center gap-3">
            <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <span class="material-symbols-outlined text-xl">payments</span>
            </span>
            <div class="min-w-0">
              <p class="text-sm font-bold text-foreground">${translate("Payroll")}</p>
              <p class="mt-0.5 text-xs text-muted-foreground">${translate("Password required · Salary and deductions")}</p>
            </div>
          </div>
          <span class="material-symbols-outlined shrink-0 text-xl text-muted-foreground">lock</span>
        </a>

        <button type="button" disabled
          class="flex h-11 w-full cursor-not-allowed items-center justify-center gap-2 rounded-lg bg-muted text-sm font-semibold text-muted-foreground">
          ${translate("Edit Profile Details")}
        </button>
        <p class="text-center text-xs text-muted-foreground">${translate("Available on desktop")}</p>

        <a href="${Helpers.mobile_company_home_path(company.id)}"
          class="flex h-11 w-full cursor-pointer items-center justify-center gap-2 rounded-lg bg-card text-sm font-semibold text-foreground shadow-sm ring-1 ring-line transition-colors hover:bg-background">
          ${translate("Back to Home")}
        </a>

        ${signOutForm}
      </div>
    `
  }

  fieldHTML({ icon, label, value }) {
    return `
      <div class="flex items-center gap-2 rounded-lg border border-line bg-background p-3">
        <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-card text-muted-foreground">
          <span class="material-symbols-outlined text-lg">${icon}</span>
        </span>
        <div class="min-w-0">
          <p class="text-xs text-muted-foreground">${translate(label)}</p>
          <p class="truncate text-sm font-medium text-foreground">${escapeHtml(value || "—")}</p>
        </div>
      </div>
    `
  }

  rowHTML(label, value) {
    return `
      <div class="flex items-center justify-between gap-2">
        <span class="text-xs text-muted-foreground">${translate(label)}</span>
        <span class="text-sm font-medium text-foreground">${escapeHtml(value)}</span>
      </div>
    `
  }
}
