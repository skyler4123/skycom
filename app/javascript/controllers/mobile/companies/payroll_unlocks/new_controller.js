import { Controller } from "@hotwired/stimulus"
import { escapeHtml, translate, form } from "controllers/helpers/ui_helpers"
import { mobileHeader, mobileMain, renderMobileError } from "controllers/helpers/mobile_helpers"

// Mobile payroll password gate — native POST so the five-minute server-side
// unlock and its redirect stay unchanged. A wrong password re-renders this page
// with data-errors.
// Depends on BE: Mobile::Companies::PayrollUnlocksController#new|create
// Endpoints: GET /mobile/companies/:company_id/payroll/unlock(.json), POST same path
// Docs: docs/MOBILE.md §2-§4
export default class Mobile_Companies_PayrollUnlocks_NewController extends Controller {
  async connect() {
    document.title = "Payroll Access"

    try {
      const data = await fetchJson(this.element.dataset.jsonUrl)
      this.element.innerHTML = this.contentHTML(data)
    } catch (error) {
      renderMobileError(this.element, error, () => this.connect())
    }
  }

  parseList(value) {
    try {
      const parsed = value ? JSON.parse(value) : []
      return Array.isArray(parsed) ? parsed : []
    } catch (e) {
      return []
    }
  }

  contentHTML({ company, employee, month }) {
    const errors = this.parseList(this.element.dataset.errors)
    const profilePath = Helpers.mobile_company_employee_path(company.id)

    return `
      ${mobileHeader({
        title: "Payroll Access",
        backPath: profilePath,
        avatarName: employee.name,
        avatarPath: profilePath,
        replaceNavigation: true
      })}
      ${mobileMain(`
        <div class="flex flex-col gap-4">
          <section class="rounded-xl border border-line bg-card p-6 text-center shadow-sm">
            <div class="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/10 text-primary">
              <span class="material-symbols-outlined text-3xl">lock</span>
            </div>
            <h2 class="mt-4 text-lg font-bold text-foreground">${translate("Payroll is private")}</h2>
            <p class="mx-auto mt-1 max-w-sm text-sm text-muted-foreground">
              ${translate("Enter your password to view your salary information.")}
            </p>

            ${errors.length ? `
              <div class="mt-4 flex items-start gap-2 rounded-lg border border-danger/20 bg-danger/10 p-3 text-left">
                <span class="material-symbols-outlined text-lg text-danger">error</span>
                <p class="text-sm font-medium text-danger">${escapeHtml(errors.join(", "))}</p>
              </div>
            ` : ""}

            ${form({
              action: Helpers.mobile_company_payroll_unlock_path(company.id),
              method: "POST",
              attributes: `data-turbo="false" class="mt-5 flex flex-col gap-3 text-left"`,
              html: `
                ${month ? `<input type="hidden" name="month" value="${escapeHtml(month)}">` : ""}
                <div class="flex flex-col gap-1.5">
                  <label for="password" class="text-xs font-semibold text-foreground">${translate("Password")}</label>
                  <div class="relative flex items-center" data-controller="mobile--password-visibility">
                    <span class="material-symbols-outlined pointer-events-none absolute left-3 text-xl text-muted-foreground">lock</span>
                    <input id="password" name="password" type="password" required autofocus autocomplete="current-password"
                      placeholder="${translate("Enter your password")}"
                      data-mobile--password-visibility-target="input"
                      class="h-12 w-full rounded-xl border border-line bg-background pl-11 pr-11 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-primary/40 focus:bg-card" />
                    <button type="button" aria-label="${translate("Show password")}"
                      data-mobile--password-visibility-target="button" data-action="click->mobile--password-visibility#toggle"
                      class="absolute right-2 flex h-9 w-9 cursor-pointer items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground">
                      <span data-mobile--password-visibility-target="showIcon">
                        <span class="material-symbols-outlined text-xl">visibility</span>
                      </span>
                      <span data-mobile--password-visibility-target="hideIcon" class="hidden">
                        <span class="material-symbols-outlined text-xl">visibility_off</span>
                      </span>
                    </button>
                  </div>
                </div>

                <button type="submit"
                  class="mt-1 flex h-12 w-full cursor-pointer items-center justify-center gap-2 rounded-xl bg-primary text-sm font-bold text-primary-foreground shadow-sm transition-colors hover:bg-primary/90 active:scale-95">
                  ${translate("Open Payroll")}
                </button>
              `
            })}
          </section>

          <div class="flex flex-col gap-2">
            <a href="${profilePath}"
              class="flex h-11 w-full cursor-pointer items-center justify-center gap-2 rounded-lg bg-card text-sm font-semibold text-foreground shadow-sm ring-1 ring-line transition-colors hover:bg-background">
              ${translate("Back to Profile")}
            </a>
          </div>
        </div>
      `)}
    `
  }
}
