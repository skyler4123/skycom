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
        this.contentTarget.classList.add("flex", "flex-col", "flex-1")
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
      <div class="p-4 flex-1 flex flex-col">
        <div class="p-4 bg-card rounded-xl border border-line flex-1" data-storage-panel>
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-bold text-foreground">${translate("Folders")}</h2>
            <button type="button" data-action="click->${this.identifier}#openNewModal"
              class="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm font-medium cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">add</span>
              ${translate("New Folder")}
            </button>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            ${this.folders.map((f) => `
              <a href="${Helpers.company_folder_path(currentCompany().id, f.id)}"
                class="p-4 border border-line rounded-xl bg-muted hover:bg-muted flex items-center gap-2 cursor-pointer">
                <span class="material-symbols-outlined text-warning">folder</span>
                <span class="font-medium truncate flex-1">${escapeHtml(f.name)}</span>
              </a>
            `).join("")}
          </div>

          ${this.folders.length === 0 ? `<p class="mt-6 text-sm text-muted-foreground text-center">${translate("No data")}</p>` : ""}
        </div>
      </div>
    `
  }
}
