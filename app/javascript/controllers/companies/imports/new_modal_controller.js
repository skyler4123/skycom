import { Controller } from "@hotwired/stimulus"

export default class Companies_Imports_NewModalController extends Controller {
  // Create-import modal — name + description only. The show page owns the
  // table/category picker, file upload, dry run, approve, and rollback.
  // On success navigates straight to the new import's show page.
  // Depends on BE: Companies::ImportsController#create
  // Endpoints: POST /companies/:id/imports.json
  // Docs: docs/IMPORT.md

  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  async handleSubmit(event) {
    event.preventDefault()

    try {
      const formData = new FormData(event.target)
      const response = await fetchJson(Helpers.company_imports_path(currentCompany().id), {
        method: "POST",
        body: {
          import: {
            name: formData.get("import[name]"),
            description: formData.get("import[description]")
          }
        }
      })

      window.location.href = Helpers.company_import_path(currentCompany().id, response.import.id)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to create import") })
    }
  }

  modalHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Import")}</h2>
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Import Name")}</label>
          <input type="text" name="import[name]" required placeholder="e.g. Products 2026-11"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm" />
        </div>
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Description")}</label>
          <textarea name="import[description]" rows="3" placeholder="Optional notes for this import"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm"></textarea>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Import")}
          </button>
        </div>
      </div>
    `

    return form({
      attributes: `
        class="p-8 bg-card rounded-2xl w-[520px] shadow-2xl"
        data-action="submit->${this.identifier}#handleSubmit"
      `,
      html: fields
    })
  }
}
