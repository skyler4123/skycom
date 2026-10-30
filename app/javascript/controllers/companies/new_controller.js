import { Controller } from "@hotwired/stimulus"

// Depends on BE: CompaniesController#new (GET /companies/new shell) + #create (POST /companies).
// Owner-only: both endpoints enforce User#can_create_company? (docs/HOMEPAGE.md §6).
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

    const countryOptions = [
      { value: "us", label: translate("United States") },
      { value: "vn", label: translate("Vietnam") },
    ].map(type =>
      `<option value="${type.value}">${type.label}</option>`
    ).join('')

    const fields = `
      <div class="space-y-6">
        <div class="border-b border-line px-6 py-4">
          <h1 class="text-xl font-bold text-foreground">${translate("New Company")}</h1>
          <p class="mt-1 text-sm text-muted-foreground">${translate("Set up a new business under your master account.")}</p>
        </div>

        <div class="px-6 space-y-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Company Name")}</label>
            <input type="text" name="company[name]" required placeholder="${translate("e.g. Acme Inc.")}"
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Business Type")}</label>
            <select name="company[business_type]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              <option value="">${translate("Select a business type")}</option>
              ${businessTypeOptions}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">${translate("Country")}</label>
            <select name="company[country]" required
              class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground focus:ring-2 focus:ring-primary outline-none">
              <option value="">${translate("Select a country")}</option>
              ${countryOptions}
            </select>
          </div>
        </div>

        <div class="flex justify-end gap-3 px-6 py-4 border-t border-line">
          <a href="/"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg transition-colors cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm transition-all shadow-lg shadow-primary/30 cursor-pointer">
            ${translate("Create Company")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="min-h-screen bg-background py-12 ">
        <div class="mx-auto w-full max-w-[520px] px-4">
          <a
            class="mb-8 flex items-center justify-center gap-2 cursor-pointer"
            href="/"
          >
            <img alt="Skycom Logo" class="h-8 w-auto object-contain" src="/icon.svg">
            <span class="text-lg font-bold tracking-tight text-foreground">Skycom</span>
          </a>
          ${form({
            action: Helpers.create_companies_path(),
            attributes: `
              class="bg-card rounded-2xl shadow-2xl border border-line overflow-hidden"
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
