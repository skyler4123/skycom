import { Controller } from "@hotwired/stimulus"

export default class Companies_Folders_NewModalController extends Controller {
  // Create folder modal — parent preset by the opener via
  // window.pendingFolderParentId (index sets null for roots, show sets its
  // own id for children). Falls back to ?parent_id= for deep links.
  // Depends on BE: Companies::FoldersController#create
  // Endpoints: POST /companies/:id/folders.json

  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  async handleSubmit(event) {
    event.preventDefault()
    try {
      // NOTE: pass an object — fetchJson stringifies it AND sets
      // Content-Type: application/json. Pre-stringifying skips the header
      // and Rails raises ParameterMissing (400) for params[:folder].
      const formData = new FormData(event.target)
      const response = await fetchJson(Helpers.create_company_folders_path(currentCompany().id), {
        method: "POST",
        body: {
          folder: {
            name: formData.get("folder[name]"),
            parent_id: formData.get("folder[parent_id]") || null
          }
        }
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to create folder") })
    }
  }

  modalHTML() {
    const rawParentId = window.pendingFolderParentId
      || new URLSearchParams(window.location.search).get("parent_id") || ""
    window.pendingFolderParentId = null
    const parentId = escapeHtml(rawParentId)
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-foreground">${translate("New Folder")}</h2>
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Folder Name")}</label>
          <input type="text" name="folder[name]" required placeholder="e.g. Contracts"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm" />
          <input type="hidden" name="folder[parent_id]" value="${parentId}" />
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Folder")}
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
