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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load company.")}</div>`
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
        <div class="flex size-10 items-center justify-center rounded-lg bg-slate-100 dark:bg-gray-800 text-blue-600 dark:text-blue-400">
          <span class="material-symbols-outlined">${icon}</span>
        </div>
        <div class="min-w-0 flex-1">
          <p class="text-xs font-medium text-slate-500 dark:text-gray-400">${label}</p>
          <p class="text-sm font-semibold text-slate-900 dark:text-white break-words">${value || translate("N/A")}</p>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start mb-6">
            <div class="size-24 shrink-0 overflow-hidden rounded-xl border-4 border-blue-100 dark:border-blue-900/30 bg-blue-100 dark:bg-gray-800 shadow-lg flex items-center justify-center">
              <span class="material-symbols-outlined text-4xl text-blue-600 dark:text-blue-400">storefront</span>
            </div>
            <div class="flex flex-1 flex-col text-center sm:text-left">
              <h2 class="text-2xl font-black text-slate-900 dark:text-white">${c.name}</h2>
              <p class="font-semibold text-blue-600 dark:text-blue-400">${c.description || ""}</p>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 border-t border-slate-200 dark:border-gray-800 pt-6 sm:grid-cols-2">
            ${row("mail", translate("Email"), c.email)}
            ${row("phone", translate("Phone"), c.phone_number)}
            ${row("language", translate("Website"), c.website)}
            ${row("schedule", translate("Timezone"), c.timezone)}
            ${row("payments", translate("Currency"), (c.currency || "").toUpperCase())}
            ${row("public", translate("Country"), (c.country || "").toUpperCase())}
            ${row("category", translate("Business Type"), c.business_type)}
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-slate-200 dark:border-gray-800">
            <a href="${Helpers.edit_company_path(c.id)}"
              class="inline-flex items-center px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Company")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
