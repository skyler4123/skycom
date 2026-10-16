import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Folders_NewModalController from "controllers/companies/folders/new_modal_controller"

export default class Companies_Folders_IndexController extends Companies_LayoutController {
  // Storage browser — roots act as buckets, files live only inside folders.
  // Depends on BE: Companies::FoldersController#index/show (folders + files + breadcrumbs), #destroy
  //               Companies::StoredFilesController#create (multipart), #download, #destroy
  // Endpoints: GET <pathname>.json?parent_id, POST /stored_files, GET /stored_files/:id/download, DELETE ...
  // Docs: docs/STORAGE.md

  /** @type {Folder[]} */ folders = []
  /** @type {StoredFile[]} */ files = []
  /** @type {Folder | null} */ currentFolder = null
  /** @type {Folder[]} */ breadcrumbs = []

  async connect() {
    super.connect()

    try {
      const params = new URLSearchParams(window.location.search)
      const query = params.get("parent_id") ? `?parent_id=${encodeURIComponent(params.get("parent_id"))}` : ""
      /** @type {{ folders: Folder[], current_folder: Folder | null, breadcrumbs: Folder[] }} */
      const foldersRes = await fetchJson(`${pathname()}.json${query}`)
      this.folders = foldersRes.folders || []
      this.currentFolder = foldersRes.current_folder || null
      this.breadcrumbs = foldersRes.breadcrumbs || []

      if (this.currentFolder) {
        /** @type {{ files: StoredFile[] }} */
        const showRes = await fetchJson(Helpers.company_folder_path(currentCompany().id, this.currentFolder.id) + ".json")
        this.files = showRes.files || []
        if (showRes.breadcrumbs) this.breadcrumbs = showRes.breadcrumbs
      } else {
        this.files = []
      }
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
    openModal({ html: `<div data-controller="${identifier(Companies_Folders_NewModalController)}"></div>` })
  }

  async handleUpload(event) {
    event.preventDefault()
    const input = event.target.querySelector('input[type="file"]')
    const fileList = event.params?.files || input?.files
    if (!fileList || fileList.length === 0) return
    if (!this.currentFolder) {
      toast({ type: "error", message: translate("Select a folder before uploading") })
      return
    }    for (const file of fileList) {
      const data = new FormData()
      data.append("stored_file[folder_id]", this.currentFolder.id)
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
    const { folderId, folderName } = event.params
    if (!confirm(`${folderName}?`)) return
    try {
      const response = await fetchJson(Helpers.company_folder_path(currentCompany().id, folderId) + ".json", { method: "DELETE" })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete folder") })
    }
  }

  async deleteFile(event) {
    event.preventDefault()
    const { fileId, fileName } = event.params
    if (!confirm(`${fileName}?`)) return
    try {
      const response = await fetchJson(Helpers.company_stored_file_path(currentCompany().id, fileId) + ".json", { method: "DELETE" })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete file") })
    }
  }

  breadcrumbHTML() {
    const home = `<a href="${Helpers.company_folders_path(currentCompany().id)}" class="text-blue-600 hover:underline cursor-pointer">${translate("Home")}</a>`
    const trail = this.breadcrumbs.map((b, i) => {
      const last = i === this.breadcrumbs.length - 1
      const label = escapeHtml(b.name)
      return last
        ? `<span class="text-slate-900 dark:text-white font-medium">${label}</span>`
        : `<a href="${Helpers.company_folders_path(currentCompany().id)}?parent_id=${b.id}" class="text-blue-600 hover:underline cursor-pointer">${label}</a>`
    }).join(`<span class="text-slate-300 mx-1">/</span>`)
    return `<nav class="flex items-center gap-1 text-sm mb-4">${home}${this.breadcrumbs.length ? `<span class="text-slate-300 mx-1">/</span>${trail}` : ""}</nav>`
  }

  contentHTML() {
    const parentId = this.currentFolder?.id || new URLSearchParams(window.location.search).get("parent_id") || ""
    const uploadZone = this.currentFolder ? `
      <form data-action="submit->${this.identifier}#handleUpload" class="mb-6 border-2 border-dashed border-slate-200 dark:border-slate-700 rounded-xl p-6 text-center">
        <input type="file" multiple class="block w-full text-sm text-slate-500 mb-3" />
        <button type="submit" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium cursor-pointer">
          ${translate("Upload Files")}
        </button>
        <p class="mt-2 text-xs text-slate-400">${translate("Drop files here or click to upload")}</p>
      </form>
    ` : ""

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

          ${this.breadcrumbHTML()}
          ${uploadZone}

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            ${this.folders.map((f) => `
              <div class="p-4 border border-slate-200 dark:border-slate-700 rounded-xl bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center gap-2">
                <span class="material-symbols-outlined text-amber-500">folder</span>
                <a href="${Helpers.company_folders_path(currentCompany().id)}?parent_id=${f.id}" class="font-medium truncate flex-1 cursor-pointer">${escapeHtml(f.name)}</a>
                <button type="button" data-action="click->${this.identifier}#deleteFolder"
                  data-${this.identifier}-folder-id-param="${f.id}" data-${this.identifier}-folder-name-param="${escapeHtml(f.name)}"
                  class="p-1 text-slate-400 hover:text-red-600 cursor-pointer" ${tooltip(translate("Delete"))}>
                  <span class="material-symbols-outlined text-[18px]">delete</span>
                </button>
              </div>
            `).join("")}
            ${this.files.map((sf) => `
              <div class="p-4 border border-slate-200 dark:border-slate-700 rounded-xl bg-white dark:bg-slate-900 flex items-center gap-2">
                <span class="material-symbols-outlined text-blue-500">description</span>
                <div class="min-w-0 flex-1">
                  <a href="${Helpers.download_company_stored_file_path(currentCompany().id, sf.id)}" class="block font-medium text-blue-600 truncate cursor-pointer">${escapeHtml(sf.name)}</a>
                  <span class="text-xs text-slate-400">${this.humanSize(sf.file_size)} · ${escapeHtml(sf.extension || "")}</span>
                </div>
                <button type="button" data-action="click->${this.identifier}#deleteFile"
                  data-${this.identifier}-file-id-param="${sf.id}" data-${this.identifier}-file-name-param="${escapeHtml(sf.name)}"
                  class="p-1 text-slate-400 hover:text-red-600 cursor-pointer" ${tooltip(translate("Delete"))}>
                  <span class="material-symbols-outlined text-[18px]">delete</span>
                </button>
              </div>
            `).join("")}
          </div>

          ${this.folders.length === 0 && this.files.length === 0 ? `<p class="mt-6 text-sm text-slate-400 text-center">${translate("No data")}</p>` : ""}
          <input type="hidden" id="current-parent-id" value="${parentId}" />
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
