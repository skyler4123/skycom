import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Folders_NewModalController from "controllers/companies/folders/new_modal_controller"

export default class Companies_Folders_IndexController extends Companies_LayoutController {
  // Storage roots — buckets list, navigation only. Inside-folder browsing,
  // upload and delete live on the folder show page.
  // Depends on BE: Companies::FoldersController#index (roots)
  // Endpoints: GET <pathname>.json
  // Docs: docs/STORAGE.md

  /** @type {Folder[]} */ folders = []

  async connect() {
    super.connect()

    try {
      /** @type {{ folders: Folder[] }} */
      const response = await fetchJson(`${pathname()}.json`)
      this.folders = response.folders || []
    } catch (error) {
      toast({ type: "error", message: `${translate("Failed to load folders")}: ${error.errors?.join(", ") || error.message}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  openNewModal() {
    window.pendingFolderParentId = null
    openModal({ html: `<div data-controller="${identifier(Companies_Folders_NewModalController)}"></div>` })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-bold text-slate-900 dark:text-white">${translate("Folders")}</h2>
            <button type="button" data-action="click->${this.identifier}#openNewModal"
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("New Folder")}
            </button>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            ${this.folders.map((f) => `
              <a href="${Helpers.company_folder_path(currentCompany().id, f.id)}"
                class="p-4 border border-slate-200 dark:border-slate-700 rounded-xl bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center gap-2 cursor-pointer">
                <span class="material-symbols-outlined text-amber-500">folder</span>
                <span class="font-medium truncate flex-1">${escapeHtml(f.name)}</span>
              </a>
            `).join("")}
          </div>

          ${this.folders.length === 0 ? `<p class="mt-6 text-sm text-slate-400 text-center">${translate("No data")}</p>` : ""}
        </div>
      </div>
    `
  }
}
