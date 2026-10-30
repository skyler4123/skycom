import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Folders_NewModalController from "controllers/companies/folders/new_modal_controller"

export default class Companies_Folders_ShowController extends Companies_LayoutController {
  // Folder detail — breadcrumb, children + files browser, upload zone and
  // the single guarded Delete button for this folder.
  // Depends on BE: Companies::FoldersController#show (folder + subfolders + files + breadcrumbs), #destroy
  //               Companies::StoredFilesController#create (multipart)
  // Endpoints: GET <pathname>.json, DELETE <pathname>.json, POST /stored_files
  // Docs: docs/STORAGE.md

  static targets = ["fileInput"]

  /** @type {Folder | null} */ folder = null
  /** @type {Folder[]} */ subfolders = []
  /** @type {StoredFile[]} */ files = []
  /** @type {Folder[]} */ breadcrumbs = []

  async connect() {
    super.connect()

    try {
      /** @type {{ folder: Folder, subfolders: Folder[], files: StoredFile[], breadcrumbs: Folder[] }} */
      const response = await fetchJson(`${pathname()}.json`)
      this.folder = response.folder
      this.subfolders = response.subfolders || []
      this.files = response.files || []
      this.breadcrumbs = response.breadcrumbs || []
    } catch (error) {
      toast({ type: "error", message: `${translate("Failed to load folder")}: ${error.errors?.join(", ") || error.message}` })
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
    window.pendingFolderParentId = this.folder?.id || null
    openModal({ html: `<div data-controller="${identifier(Companies_Folders_NewModalController)}"></div>` })
  }

  browse(event) {
    // Programmatic input.click() bubbles back to the zone handler — ignore it.
    if (!this.hasFileInputTarget || event.target === this.fileInputTarget) return
    this.fileInputTarget.click()
  }

  async handleUpload() {
    if (!this.folder) {
      toast({ type: "error", message: translate("Select a folder before uploading") })
      return
    }
    const input = this.fileInputTarget
    if (!input.files || input.files.length === 0) return
    let uploaded = 0

    for (const file of input.files) {
      const data = new FormData()
      data.append("stored_file[folder_id]", this.folder.id)
      data.append("stored_file[name]", file.name)
      data.append("stored_file[file]", file)
      try {
        const response = await fetchJson(Helpers.create_company_stored_files_path(currentCompany().id), {
          method: "POST",
          body: data
        })
        uploaded += 1
        toast({ type: "success", message: response.message })
      } catch (error) {
        toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to upload file") })
      }
    }
    input.value = "" // allow re-picking the same file after a failure
    if (uploaded > 0) reloadThenToast({ type: "success", message: translate("Upload Files") })
  }

  async deleteFolder(event) {
    event.preventDefault()
    if (!confirm(`${this.folder?.name}?`)) return
    try {
      await fetchJson(`${pathname()}.json`, { method: "DELETE" })
      const crumbs = this.breadcrumbs.filter((b) => b.id !== this.folder?.id)
      const parent = crumbs[crumbs.length - 1]
      window.location.href = parent
        ? Helpers.company_folder_path(currentCompany().id, parent.id)
        : Helpers.company_folders_path(currentCompany().id)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete folder") })
    }
  }

  breadcrumbHTML() {
    const home = `<a href="${Helpers.company_folders_path(currentCompany().id)}" class="text-primary hover:underline cursor-pointer">${translate("Home")}</a>`
    const trail = this.breadcrumbs.map((b) => {
      const current = b.id === this.folder?.id
      const label = escapeHtml(b.name)
      return current
        ? `<span class="text-foreground font-medium">${label}</span>`
        : `<a href="${Helpers.company_folder_path(currentCompany().id, b.id)}" class="text-primary hover:underline cursor-pointer">${label}</a>`
    }).join(`<span class="text-muted-foreground/60 mx-1">/</span>`)
    return `<nav class="flex items-center gap-1 text-sm mb-4">${home}<span class="text-muted-foreground/60 mx-1">/</span>${trail}</nav>`
  }

  contentHTML() {
    if (!this.folder) return `<div class="p-4 text-sm text-muted-foreground">${translate("Loading...")}</div>`
    const f = this.folder

    return `
      <div class="p-4 flex-1 flex flex-col">
        <div class="p-4 bg-card rounded-xl border border-line flex-1" data-storage-panel>
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center gap-3 min-w-0">
              <span class="material-symbols-outlined text-warning text-[28px]">folder</span>
              <div class="min-w-0">
                <h2 class="text-lg font-bold text-foreground truncate">${escapeHtml(f.name)}</h2>
                <p class="text-xs text-muted-foreground">${this.subfolders.length} ${translate("Folders").toLowerCase()} · ${this.files.length} ${translate("Files").toLowerCase()}</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <button type="button" data-action="click->${this.identifier}#openNewModal"
                class="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm font-medium cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("New Folder")}
              </button>
              <button type="button" data-action="click->${this.identifier}#deleteFolder"
                class="flex items-center gap-2 px-4 py-2 bg-danger hover:bg-danger/90 text-danger-foreground rounded-lg text-sm font-medium cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">delete</span>
                ${translate("Delete")}
              </button>
            </div>
          </div>

          ${this.breadcrumbHTML()}

          <div data-action="click->${this.identifier}#browse"
            class="mb-6 border-2 border-dashed border-line rounded-xl p-6 text-center cursor-pointer">
            <input type="file" name="file" multiple class="sr-only"
              data-${this.identifier}-target="fileInput"
              data-action="change->${this.identifier}#handleUpload" />
            <button type="button" class="px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm font-medium cursor-pointer">
              ${translate("Upload Files")}
            </button>
            <p class="mt-2 text-xs text-muted-foreground">${translate("Drop files here or click to upload")}</p>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            ${this.subfolders.map((sf) => `
              <a href="${Helpers.company_folder_path(currentCompany().id, sf.id)}"
                class="p-4 border border-line rounded-xl bg-muted hover:bg-muted flex items-center gap-2 cursor-pointer">
                <span class="material-symbols-outlined text-warning">folder</span>
                <span class="font-medium truncate flex-1">${escapeHtml(sf.name)}</span>
              </a>
            `).join("")}
            ${this.files.map((file) => `
              <a href="${Helpers.company_stored_file_path(currentCompany().id, file.id)}"
                class="p-4 border border-line rounded-xl bg-card hover:bg-muted flex items-center gap-2 cursor-pointer">
                <span class="material-symbols-outlined text-primary">description</span>
                <span class="min-w-0 flex-1">
                  <span class="block font-medium text-foreground truncate">${escapeHtml(file.name)}</span>
                  <span class="text-xs text-muted-foreground">${this.humanSize(file.file_size)} · ${escapeHtml(file.extension || "")}</span>
                </span>
              </a>
            `).join("")}
          </div>

          ${this.subfolders.length === 0 && this.files.length === 0 ? `<p class="mt-6 text-sm text-muted-foreground text-center">${translate("No data")}</p>` : ""}
        </div>
      </div>
    `
  }

  humanSize(bytes) {
    const n = Number(bytes) || 0
    if (n < 1024) return `${n} B`
    if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`
    return `${(n / 1024 / 1024).toFixed(1)} MB`
  }
}
