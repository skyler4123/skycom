import { Controller } from "@hotwired/stimulus"

export default class Companies_CompanyMigrations_NewModalController extends Controller {
  // Create-import modal — a session shell; chunks upload on the show page.
  // On success navigates straight to the new migration's show page.
  // Depends on BE: Companies::CompanyMigrationsController#create
  // Endpoints: POST /companies/:id/company_migrations.json
  // Docs: docs/DATA_IMPORT.md

  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  async handleSubmit(event) {
    event.preventDefault()

    try {
      const formData = new FormData(event.target)
      const response = await fetchJson(Helpers.company_company_migrations_path(currentCompany().id), {
        method: "POST",
        body: {
          company_migration: {
            name: formData.get("company_migration[name]")
          }
        }
      })

      window.location.href = Helpers.company_company_migration_path(currentCompany().id, response.company_migration.id)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to create import") })
    }
  }

  modalHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Import")}</h2>
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Import Name")}</label>
          <input type="text" name="company_migration[name]" required placeholder="e.g. Customers 2026-10"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm" />
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Import")}
          </button>
        </div>
      </div>
    `

    return form({
      attributes: `
        class="p-8 bg-white dark:bg-slate-900 rounded-2xl w-[500px] shadow-2xl"
        data-action="submit->${this.identifier}#handleSubmit"
      `,
      html: fields
    })
  }
}
