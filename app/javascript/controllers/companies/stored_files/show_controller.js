import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_StoredFiles_ShowController extends Companies_LayoutController {
  // File detail — metadata, download and the single guarded Delete button.
  // Depends on BE: Companies::StoredFilesController#show, #destroy
  // Endpoints: GET <pathname>.json, DELETE <pathname>.json
  // Docs: docs/STORAGE.md

  /** @type {StoredFile | null} */ storedFile = null

  async connect() {
    super.connect()

    try {
      /** @type {{ stored_file: StoredFile }} */
      const response = await fetchJson(`${pathname()}.json`)
      this.storedFile = response.stored_file
    } catch (error) {
      toast({ type: "error", message: `${translate("Failed to load file")}: ${error.errors?.join(", ") || error.message}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  async deleteFile(event) {
    event.preventDefault()
    if (!confirm(`${this.storedFile?.name}?`)) return
    try {
      await fetchJson(`${pathname()}.json`, { method: "DELETE" })
      window.location.href = Helpers.company_folder_path(currentCompany().id, this.storedFile.folder_id)
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to delete file") })
    }
  }

  contentHTML() {
    if (!this.storedFile) return `<div class="p-4 text-sm text-slate-400">${translate("Loading...")}</div>`
    const sf = this.storedFile

    const row = (label, value) => `
      <div class="flex items-center justify-between py-2 border-b border-slate-100 dark:border-slate-800 last:border-0">
        <span class="text-xs font-bold text-slate-400 uppercase">${label}</span>
        <span class="text-sm text-slate-900 dark:text-white">${value}</span>
      </div>`

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 max-w-2xl">
          <div class="flex items-center gap-3 mb-2">
            <span class="material-symbols-outlined text-blue-500 text-[32px]">description</span>
            <h2 class="text-lg font-bold text-slate-900 dark:text-white break-all">${escapeHtml(sf.name)}</h2>
          </div>
          <a href="${Helpers.company_folder_path(currentCompany().id, sf.folder_id)}"
            class="inline-block text-sm text-blue-600 hover:underline cursor-pointer mb-4">← ${translate("Folders")}</a>

          <div class="mb-6">
            ${row(translate("Size"), escapeHtml(this.humanSize(sf.file_size)))}
            ${row(translate("Type"), escapeHtml(`${sf.extension || "—"} · ${sf.content_type || ""}`))}
            ${row(translate("Created"), escapeHtml(Helpers.timeFormat(sf.created_at)))}
          </div>

          <div class="flex items-center gap-2">
            <a href="${Helpers.download_company_stored_file_path(currentCompany().id, sf.id)}"
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">download</span>
              ${translate("Download")}
            </a>
            <button type="button" data-action="click->${this.identifier}#deleteFile"
              class="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-medium cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">delete</span>
              ${translate("Delete")}
            </button>
          </div>
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
