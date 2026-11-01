import { Controller } from "@hotwired/stimulus"

export default class Companies_CompanyMigrations_NewModalController extends Controller {
  // Create-migration modal — a session shell; chunks upload on the show page.
  // On success navigates straight to the new migration's show page.
  // Depends on BE: Companies::CompanyMigrationsController#create
  // Endpoints: POST /companies/:id/company_migrations.json
  // Docs: docs/DATA_MIGRATION.md

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
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to create migration") })
    }
  }

  modalHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Migration")}</h2>
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Migration Name")}</label>
          <input type="text" name="company_migration[name]" required placeholder="e.g. Customers 2026-10"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm" />
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Migration")}
          </button>
        </div>
      </div>
    `

    return form({
      attributes: `
        class="p-8 bg-card rounded-2xl w-[500px] shadow-2xl"
        data-action="submit->${this.identifier}#handleSubmit"
      `,
      html: fields
    })
  }
}
