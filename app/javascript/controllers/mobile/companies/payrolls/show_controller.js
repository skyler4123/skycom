import { Controller } from "@hotwired/stimulus"
import { escapeHtml, translate } from "controllers/helpers/ui_helpers"
import {
  mobileHeader,
  mobileMain,
  mobileAvatar,
  mobileStatTile,
  mobileEmptyState,
  mobileMonthLabel,
  mobileDate,
  mobileDuration,
  mobileMoney,
  mobilePayrollBadge,
  renderMobileError
} from "controllers/helpers/mobile_helpers"

// Mobile payroll — net earnings, cycle step, compensation breakdown and line
// items for the selected pay period, behind the password gate.
// Depends on BE: Mobile::Companies::PayrollsController#show
// Endpoints: GET /mobile/companies/:company_id/payroll.json?month=YYYY-MM
// Docs: docs/MOBILE.md §2-§4
export default class Mobile_Companies_Payrolls_ShowController extends Controller {
  async connect() {
    document.title = "Payroll"

    try {
      const data = await fetchJson(this.element.dataset.jsonUrl)
      this.element.innerHTML = this.contentHTML(data)
    } catch (error) {
      renderMobileError(this.element, error, () => this.connect())
    }
  }

  contentHTML(data) {
    const { company, employee } = data
    const profilePath = Helpers.mobile_company_employee_path(company.id)

    return `
      ${mobileHeader({
        title: "Payroll",
        backPath: profilePath,
        avatarName: employee.name,
        avatarPath: profilePath,
        replaceNavigation: true
      })}
      ${mobileMain(`
        <div class="flex flex-col gap-4">
          ${this.periodSelectHTML(data)}
          ${data.payroll ? this.payrollHTML(data) : mobileEmptyState({
            title: "No payroll data for this month.",
            hint: "Pick another pay period or ask an admin to generate payroll.",
            icon: "payments"
          })}
        </div>
      `)}
    `
  }

  periodSelectHTML({ company, month, month_options: monthOptions = [] }) {
    const selected = String(month || "").slice(0, 7)
    const options = monthOptions.map((option) => `
      <option value="${Helpers.mobile_company_payroll_path(company.id, { month: option.value })}" ${option.value === selected ? "selected" : ""}>
        ${escapeHtml(mobileMonthLabel(`${option.value}-01`))}
      </option>
    `).join("")

    return `
      <div class="flex items-center gap-2 rounded-xl border border-line bg-card p-3 shadow-sm">
        <span class="material-symbols-outlined text-xl text-primary">calendar_month</span>
        <select aria-label="${translate("Pay period")}" data-controller="mobile--select-nav"
          data-action="change->mobile--select-nav#navigate"
          class="w-full cursor-pointer appearance-none rounded-lg bg-card text-sm font-semibold text-foreground outline-none">
          ${options}
        </select>
        <span class="material-symbols-outlined pointer-events-none text-xl text-muted-foreground">expand_more</span>
      </div>
    `
  }

  payrollHTML(data) {
    const payroll = data.payroll
    const attendanceMonth = data.attendance_month
    const company = data.company
    const employee = data.employee
    const progressWidth = { 1: "w-1/3", 2: "w-2/3", 3: "w-full" }[data.status_step] || "w-1/3"
    const taxPercent = Number(data.payroll_tax_percent || 0).toFixed(1)

    return `
      <section class="relative overflow-hidden rounded-xl border border-line bg-card p-5 shadow-sm">
        <div class="pointer-events-none absolute -right-8 -top-8 h-36 w-36 rounded-full bg-primary/10"></div>
        <div class="relative flex items-start justify-between gap-2">
          <div class="flex min-w-0 items-center gap-3">
            ${mobileAvatar({ name: employee.name, size: "h-12 w-12 text-sm" })}
            <div class="min-w-0">
              <p class="truncate text-lg font-bold text-foreground">${escapeHtml(employee.name)}</p>
              <p class="truncate text-xs text-muted-foreground">${escapeHtml([ employee.branch_name, company.name ].filter(Boolean).join(" • "))}</p>
            </div>
          </div>
          ${mobilePayrollBadge(payroll.status)}
        </div>

        <div class="relative mt-4 rounded-lg border border-line bg-background p-3">
          <span class="text-xs font-medium uppercase tracking-wide text-muted-foreground">${translate("Estimated Net Earnings")}</span>
          <p class="mt-1 text-4xl font-extrabold tracking-tight text-primary">${mobileMoney(payroll.net_amount_cents, payroll.currency)}</p>
          <div class="mt-2 flex flex-wrap items-center justify-between gap-2 text-xs text-muted-foreground">
            <span class="flex items-center gap-1">
              <span class="material-symbols-outlined text-base">event_repeat</span>
              ${translate("Period")}: ${mobileDate(data.period_start)} – ${mobileDate(data.period_end)}
            </span>
            <span class="font-semibold text-foreground">${data.period_days} ${translate("Days")}</span>
          </div>
        </div>

        <div class="relative mt-3">
          <div class="flex items-center justify-between text-xs text-muted-foreground">
            <span>${translate("Cycle Completion")}</span>
            <span class="font-semibold text-foreground">${translate("Step")} ${data.status_step} ${translate("of")} 3</span>
          </div>
          <div class="mt-1 h-1.5 w-full overflow-hidden rounded-full bg-muted">
            <div class="h-full rounded-full bg-primary transition-all ${progressWidth}"></div>
          </div>
        </div>
      </section>

      <div class="grid grid-cols-2 gap-2 md:grid-cols-3 md:gap-4">
        <button type="button" disabled
          class="flex h-11 cursor-not-allowed items-center justify-center gap-1.5 rounded-lg bg-muted px-3 text-xs font-semibold text-muted-foreground">
          ${translate("Draft Payslip")}
        </button>
        <a href="${Helpers.mobile_company_attendance_month_path(company.id, { month: String(data.month).slice(0, 7) })}"
          class="flex h-11 cursor-pointer items-center justify-center gap-1.5 rounded-lg bg-primary px-3 text-xs font-semibold text-primary-foreground shadow-sm transition-colors hover:bg-primary/90">
          ${translate("View Timesheet")}
        </a>
      </div>

      <section class="flex flex-col gap-2">
        <div class="flex items-center justify-between px-1">
          <h2 class="text-sm font-bold text-foreground">${translate("Compensation Breakdown")}</h2>
        </div>
        <div class="grid grid-cols-2 gap-2 md:grid-cols-3 md:gap-4">
          ${mobileStatTile({
            label: "Gross Pay",
            value: mobileMoney(payroll.gross_amount_cents, payroll.currency),
            hint: translate("Base contract rate"),
            icon: "payments"
          })}
          ${mobileStatTile({
            label: "Shifts",
            value: mobileDuration(attendanceMonth?.total_work_minutes),
            hint: `${attendanceMonth?.total_present_days || 0} ${translate("present days")}`,
            icon: "clinical_notes"
          })}
          ${mobileStatTile({
            label: "Overtime",
            value: mobileMoney(payroll.overtime_amount_cents, payroll.currency),
            hint: `${mobileDuration(attendanceMonth?.total_overtime_minutes)} ${translate("recorded")}`,
            icon: "more_time"
          })}
          ${mobileStatTile({
            label: "Deductions",
            value: mobileMoney(payroll.total_deductions_cents, payroll.currency),
            hint: translate("Tax & social health"),
            icon: "receipt_long"
          })}
        </div>
      </section>

      <section class="rounded-xl border border-line bg-card p-4 shadow-sm">
        <div class="flex items-center justify-between gap-2">
          <h2 class="text-sm font-bold text-foreground">${translate("Line Items Summary")}</h2>
          <span class="rounded-full bg-muted px-2 py-0.5 text-xs font-medium text-muted-foreground">${escapeHtml(translate(this.statusLabel(payroll.status)))}</span>
        </div>

        <div class="mt-3 flex flex-col divide-y divide-line">
          ${this.lineItemHTML({ icon: "badge", label: "Monthly Base Salary", hint: "Base contract rate", value: mobileMoney(payroll.base_amount_cents, payroll.currency) })}
          ${this.lineItemHTML({ icon: "emergency", label: "Shift Allowance", hint: "Monthly allowance", value: mobileMoney(payroll.allowance_amount_cents, payroll.currency) })}
          ${this.lineItemHTML({ icon: "more_time", label: "Overtime", hint: `${mobileDuration(attendanceMonth?.total_overtime_minutes)} ${translate("recorded")}`, value: mobileMoney(payroll.overtime_amount_cents, payroll.currency) })}
          ${this.lineItemHTML({
            icon: "shield",
            label: "Withholding Tax & Social",
            hint: `${translate("Statutory")} (${taxPercent}%)`,
            value: mobileMoney(payroll.total_deductions_cents, payroll.currency),
            valueClass: "text-danger"
          })}
        </div>

        <div class="mt-3 flex items-center justify-between gap-2 rounded-xl bg-muted p-3">
          <div class="min-w-0">
            <p class="text-xs font-medium text-muted-foreground">${translate("Total Payout (Net)")}</p>
            <p class="text-xs text-muted-foreground">${translate("Disbursement on")} ${mobileDate(data.disbursement_date)}</p>
          </div>
          <span class="text-lg font-extrabold text-primary">${mobileMoney(payroll.net_amount_cents, payroll.currency)}</span>
        </div>
      </section>

      <section class="flex items-start gap-2 rounded-xl border border-line bg-card p-4 shadow-sm">
        <span class="material-symbols-outlined mt-0.5 text-xl text-primary">info</span>
        <div>
          <p class="text-sm font-semibold text-foreground">${translate("How this payroll is calculated")}</p>
          <p class="mt-1 text-xs leading-relaxed text-muted-foreground">
            ${translate("Hours and days come from your attendance records. Pay is prorated from your monthly salary and allowance, with overtime, tax, and social-insurance deductions applied.")}
          </p>
        </div>
      </section>
    `
  }

  lineItemHTML({ icon, label, hint, value, valueClass = "text-foreground" }) {
    return `
      <div class="flex items-center justify-between gap-2 py-2.5">
        <div class="flex min-w-0 items-center gap-2">
          <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-muted text-muted-foreground">
            <span class="material-symbols-outlined text-base">${icon}</span>
          </span>
          <div class="min-w-0">
            <p class="truncate text-sm font-semibold text-foreground">${translate(label)}</p>
            <p class="truncate text-xs text-muted-foreground">${escapeHtml(hint)}</p>
          </div>
        </div>
        <span class="shrink-0 text-sm font-bold ${valueClass}">${value}</span>
      </div>
    `
  }

  statusLabel(status) {
    return String(status || "").replace(/_/g, " ").replace(/^\w/, (character) => character.toUpperCase())
  }
}
