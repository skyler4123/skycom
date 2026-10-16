import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Folders_NewModalController from "controllers/companies/folders/new_modal_controller"

export default class Companies_Folders_ShowController extends Companies_LayoutController {
  // Folder detail — breadcrumb, children + files browser, upload zone and
  // the single guarded Delete button for this folder.
  // Depends on BE: Companies::FoldersController#show (folder + subfolders + files + breadcrumbs), #destroy
  //               Companies::StoredFilesController#create (multipart)
  // Endpoints: GET <pathname>.json, DELETE <pathname>.json, POST /stored_files
  // Docs: docs/STORAGE.md

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

  async handleUpload(event) {
    event.preventDefault()
    if (!this.folder) {
      toast({ type: "error", message: translate("Select a folder before uploading") })
      return
    }
    const input = event.target.querySelector('input[type="file"]')
    if (!input?.files || input.files.length === 0) return

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
        toast({ type: "success", message: response.message })
      } catch (error) {
        toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to upload file") })
      }
    }
    reloadThenToast({ type: "success", message: translate("Upload Files") })
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
    const home = `<a href="${Helpers.company_folders_path(currentCompany().id)}" class="text-blue-600 hover:underline cursor-pointer">${translate("Home")}</a>`
    const trail = this.breadcrumbs.map((b) => {
      const current = b.id === this.folder?.id
      const label = escapeHtml(b.name)
      return current
        ? `<span class="text-slate-900 dark:text-white font-medium">${label}</span>`
        : `<a href="${Helpers.company_folder_path(currentCompany().id, b.id)}" class="text-blue-600 hover:underline cursor-pointer">${label}</a>`
    }).join(`<span class="text-slate-300 mx-1">/</span>`)
    return `<nav class="flex items-center gap-1 text-sm mb-4">${home}<span class="text-slate-300 mx-1">/</span>${trail}</nav>`
  }

  contentHTML() {
    if (!this.folder) return `<div class="p-4 text-sm text-slate-400">${translate("Loading...")}</div>`
    const f = this.folder

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center gap-3 min-w-0">
              <span class="material-symbols-outlined text-amber-500 text-[28px]">folder</span>
              <div class="min-w-0">
                <h2 class="text-lg font-bold text-slate-900 dark:text-white truncate">${escapeHtml(f.name)}</h2>
                <p class="text-xs text-slate-400">${this.subfolders.length} ${translate("Folders").toLowerCase()} · ${this.files.length} ${translate("Files").toLowerCase()}</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <button type="button" data-action="click->${this.identifier}#openNewModal"
                class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">add</span>
                ${translate("New Folder")}
              </button>
              <button type="button" data-action="click->${this.identifier}#deleteFolder"
                class="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-medium cursor-pointer">
                <span class="material-symbols-outlined text-[20px]">delete</span>
                ${translate("Delete")}
              </button>
            </div>
          </div>

          ${this.breadcrumbHTML()}

          <form data-action="submit->${this.identifier}#handleUpload" class="mb-6 border-2 border-dashed border-slate-200 dark:border-slate-700 rounded-xl p-6 text-center">
            <input type="file" name="file" multiple class="block w-full text-sm text-slate-500 mb-3" />
            <button type="submit" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium cursor-pointer">
              ${translate("Upload Files")}
            </button>
            <p class="mt-2 text-xs text-slate-400">${translate("Drop files here or click to upload")}</p>
          </form>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            ${this.subfolders.map((sf) => `
              <a href="${Helpers.company_folder_path(currentCompany().id, sf.id)}"
                class="p-4 border border-slate-200 dark:border-slate-700 rounded-xl bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center gap-2 cursor-pointer">
                <span class="material-symbols-outlined text-amber-500">folder</span>
                <span class="font-medium truncate flex-1">${escapeHtml(sf.name)}</span>
              </a>
            `).join("")}
            ${this.files.map((file) => `
              <a href="${Helpers.company_stored_file_path(currentCompany().id, file.id)}"
                class="p-4 border border-slate-200 dark:border-slate-700 rounded-xl bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800 flex items-center gap-2 cursor-pointer">
                <span class="material-symbols-outlined text-blue-500">description</span>
                <span class="min-w-0 flex-1">
                  <span class="block font-medium text-slate-900 dark:text-white truncate">${escapeHtml(file.name)}</span>
                  <span class="text-xs text-slate-400">${this.humanSize(file.file_size)} · ${escapeHtml(file.extension || "")}</span>
                </span>
              </a>
            `).join("")}
          </div>

          ${this.subfolders.length === 0 && this.files.length === 0 ? `<p class="mt-6 text-sm text-slate-400 text-center">${translate("No data")}</p>` : ""}
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
