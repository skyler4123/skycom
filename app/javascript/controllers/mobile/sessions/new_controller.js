import { Controller } from "@hotwired/stimulus"
import { escapeHtml, translate, form } from "controllers/helpers/ui_helpers"
import { renderMobileError } from "controllers/helpers/mobile_helpers"

// Mobile sign-in — Shell-First page with a native POST so the redirect URL
// (company-scoped home) stays visible to the Hotwire Native shell.
// Depends on BE: Mobile::SessionsController#new|create
// Endpoints: GET /mobile/sign_in(.json), POST /mobile/sign_in
// Docs: docs/MOBILE.md §2-§4
export default class Mobile_Sessions_NewController extends Controller {
  async connect() {
    document.title = "Sign in · Skycom"

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

  parseValues() {
    try {
      return this.element.dataset.values ? JSON.parse(this.element.dataset.values) : {}
    } catch (e) {
      return {}
    }
  }

  contentHTML({ email }) {
    const errors = this.parseList(this.element.dataset.errors)
    const values = this.parseValues()
    const emailValue = values.email || email || ""

    return `
      <main class="relative flex min-h-dvh flex-col overflow-hidden bg-background px-4 pb-[calc(2rem+env(safe-area-inset-bottom))] pt-[calc(2rem+env(safe-area-inset-top))]">
        <div class="pointer-events-none absolute -right-20 -top-24 h-72 w-72 rounded-full bg-primary/10 blur-3xl"></div>
        <div class="pointer-events-none absolute -left-28 top-1/3 h-80 w-80 rounded-full bg-muted/60 blur-3xl"></div>

        <div class="relative z-10 flex w-full flex-1 flex-col justify-center">
          <div class="mb-6 flex flex-col items-center text-center">
            <div class="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-tr from-primary to-primary/80 text-primary-foreground shadow-lg">
              <span class="material-symbols-outlined text-4xl">hub</span>
            </div>
            <div class="mb-1 flex items-center gap-2">
              <span class="text-2xl font-extrabold tracking-tight text-foreground">${translate("Skycom")}</span>
              <span class="rounded-md bg-primary/10 px-2 py-0.5 text-xs font-semibold uppercase tracking-wider text-primary">${translate("ERP")}</span>
            </div>
            <h1 class="mt-1 text-2xl font-bold tracking-tight text-foreground">${translate("Welcome back")}</h1>
            <p class="mt-1 max-w-xs text-sm text-muted-foreground">${translate("Sign in to access your workspace")}</p>
          </div>

          <div class="rounded-2xl border border-line bg-card p-6 shadow-lg">
            ${errors.length ? `
              <div class="mb-4 flex items-start gap-2 rounded-lg border border-danger/20 bg-danger/10 p-3">
                <span class="material-symbols-outlined text-lg text-danger">error</span>
                <p class="text-sm font-medium text-danger">${escapeHtml(errors.join(", "))}</p>
              </div>
            ` : ""}

            ${form({
              action: Helpers.mobile_sign_in_path(),
              method: "POST",
              attributes: `data-turbo="false" class="flex flex-col gap-4"`,
              html: `
                <div class="flex flex-col gap-1.5">
                  <label for="email" class="text-xs font-semibold text-foreground">${translate("Email")}</label>
                  <div class="relative flex items-center">
                    <span class="material-symbols-outlined pointer-events-none absolute left-3 text-xl text-muted-foreground">mail</span>
                    <input id="email" name="email" type="email" required autocomplete="email"
                      placeholder="${translate("name@company.com")}" value="${escapeHtml(emailValue)}"
                      class="h-12 w-full rounded-xl border border-line bg-background pl-11 pr-4 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground focus:border-primary/40 focus:bg-card" />
                  </div>
                </div>

                <div class="flex flex-col gap-1.5">
                  <label for="password" class="text-xs font-semibold text-foreground">${translate("Password")}</label>
                  <div class="relative flex items-center" data-controller="mobile--password-visibility">
                    <span class="material-symbols-outlined pointer-events-none absolute left-3 text-xl text-muted-foreground">lock</span>
                    <input id="password" name="password" type="password" required autocomplete="current-password"
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
                  class="mt-1 flex h-12 w-full cursor-pointer items-center justify-center gap-2 rounded-xl bg-primary px-6 text-base font-semibold text-primary-foreground shadow-sm transition-colors hover:bg-primary/90 active:scale-95">
                  ${translate("Sign In")}
                </button>
              `
            })}
          </div>

          <p class="mt-8 text-center text-xs text-muted-foreground">${translate("Protected by Skycom")}</p>
        </div>
      </main>
    `
  }
}
