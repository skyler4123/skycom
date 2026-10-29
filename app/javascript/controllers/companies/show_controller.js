// Depends on BE: CompaniesController#show (GET /companies/:id shell + JSON).
// Endpoints: GET /companies/:id.json — Owner-only; non-owners get 403 + errors key.
import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  company = null

  async connect() {
    super.connect()

    const id = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.company_path(id)}.json`)
      this.company = response.company

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load company.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const c = this.company
    if (!c) return `<div class="p-8 text-center">${translate("Company not found.")}</div>`

    const row = (icon, label, value) => `
      <div class="flex items-center gap-3">
        <div class="flex size-10 items-center justify-center rounded-lg bg-muted text-primary">
          <span class="material-symbols-outlined">${icon}</span>
        </div>
        <div class="min-w-0 flex-1">
          <p class="text-xs font-medium text-muted-foreground">${label}</p>
          <p class="text-sm font-semibold text-foreground break-words">${value || translate("N/A")}</p>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-primary/20 bg-primary/10 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-primary">storefront</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-foreground">${c.name}</h2>
              <p class="font-semibold text-primary">${c.description || ""}</p>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-line pt-6 sm:grid-cols-2">
            ${row("mail", translate("Email"), c.email)}
            ${row("phone", translate("Phone"), c.phone_number)}
            ${row("language", translate("Website"), c.website)}
            ${row("schedule", translate("Timezone"), c.timezone)}
            ${row("payments", translate("Currency"), (c.currency || "").toUpperCase())}
            ${row("public", translate("Country"), (c.country || "").toUpperCase())}
            ${row("category", translate("Business Type"), c.business_type)}
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_path(c.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Company")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
