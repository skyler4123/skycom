import { Controller } from "@hotwired/stimulus"

export default class Companies_Folders_NewModalController extends Controller {
  // Create folder modal — parent defaults to ?parent_id= so children land in place.
  // Depends on BE: Companies::FoldersController#create
  // Endpoints: POST /companies/:id/folders.json

  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  async handleSubmit(event) {
    event.preventDefault()
    try {
      const response = await fetchJson(Helpers.create_company_folders_path(currentCompany().id), {
        method: "POST",
        body: JSON.stringify({
          folder: {
            name: new FormData(event.target).get("folder[name]"),
            parent_id: new FormData(event.target).get("folder[parent_id]") || null
          }
        })
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to create folder") })
    }
  }

  modalHTML() {
    const rawParentId = new URLSearchParams(window.location.search).get("parent_id") || ""
    const parentId = escapeHtml(rawParentId)
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("New Folder")}</h2>
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 uppercase">${translate("Folder Name")}</label>
          <input type="text" name="folder[name]" required placeholder="e.g. Contracts"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm" />
          <input type="hidden" name="folder[parent_id]" value="${parentId}" />
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Folder")}
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
