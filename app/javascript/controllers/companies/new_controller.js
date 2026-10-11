import { Controller } from "@hotwired/stimulus"

// Depends on BE: CompaniesController#new (GET /companies/new shell) + #create (POST /companies).
// Company creation page — renders its form client-side (Shell-First), ported
// from the former new-company modal so the homepage can stay fully static HTML.
export default class Companies_NewController extends Controller {
  connect() {
    this.element.innerHTML = this.pageHTML()
  }

  handleSubmit() {
    toast({
      type: "info",
      message: translate("Creating your company, please wait..."),
      duration: 10000
    })
  }

  pageHTML() {
    const businessTypes = [
      { value: "retail", label: translate("Retail") },
      { value: "education", label: translate("Education") },
      { value: "hospital", label: translate("Hospital") },
      { value: "restaurant", label: translate("Restaurant") },
      { value: "shop", label: translate("Shop") },
      { value: "fitness", label: translate("Fitness") },
    ]

    const businessTypeOptions = businessTypes.map(type =>
      `<option value="${type.value}">${type.label}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <div class="border-b border-slate-200 dark:border-gray-800 px-6 py-4">
          <h1 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Company")}</h1>
          <p class="mt-1 text-sm text-slate-600 dark:text-slate-400">${translate("Set up a new business under your master account.")}</p>
        </div>

        <div class="px-6 space-y-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Company Name")}</label>
            <input type="text" name="company[name]" required placeholder="${translate("e.g. Acme Inc.")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Business Type")}</label>
            <select name="company[business_type]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none">
              <option value="">${translate("Select a business type")}</option>
              ${businessTypeOptions}
            </select>
          </div>
        </div>

        <div class="flex justify-end gap-3 px-6 py-4 border-t border-slate-200 dark:border-gray-800">
          <a href="/"
            class="px-4 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm transition-all shadow-lg shadow-blue-500/30 cursor-pointer">
            ${translate("Create Company")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="min-h-screen bg-gray-50 py-12 dark:bg-gray-950">
        <div class="mx-auto w-full max-w-[520px] px-4">
          <a
            class="mb-8 flex items-center justify-center gap-2 cursor-pointer"
            href="/"
          >
            <img alt="Skycom Logo" class="h-8 w-auto object-contain" src="/icon.svg">
            <span class="text-lg font-bold tracking-tight text-slate-900 dark:text-white">Skycom</span>
          </a>
          ${form({
            action: Helpers.create_companies_path(),
            attributes: `
              class="bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-100 dark:border-slate-800 overflow-hidden"
              data-action="submit->${this.identifier}#handleSubmit"
              data-turbo="false"
            `,
            html: fields
          })}
        </div>
      </div>
    `
  }
}
