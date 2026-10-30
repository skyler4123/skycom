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
        this.contentTarget.classList.add("flex", "flex-col", "flex-1")
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
    if (!this.storedFile) return `<div class="p-4 text-sm text-muted-foreground">${translate("Loading...")}</div>`
    const sf = this.storedFile

    const row = (label, value) => `
      <div class="flex items-center justify-between py-2 border-b border-line last:border-0">
        <span class="text-xs font-bold text-muted-foreground uppercase">${label}</span>
        <span class="text-sm text-foreground">${value}</span>
      </div>`

    return `
      <div class="p-4 flex-1 flex flex-col">
        <div class="p-6 bg-card rounded-xl border border-line flex-1" data-storage-panel>
          <div class="flex items-center gap-3 mb-2">
            <span class="material-symbols-outlined text-primary text-[32px]">description</span>
            <h2 class="text-lg font-bold text-foreground break-all">${escapeHtml(sf.name)}</h2>
          </div>
          <a href="${Helpers.company_folder_path(currentCompany().id, sf.folder_id)}"
            class="inline-block text-sm text-primary hover:underline cursor-pointer mb-4">← ${translate("Folders")}</a>

          <div class="mb-6">
            ${row(translate("Size"), escapeHtml(this.humanSize(sf.file_size)))}
            ${row(translate("Type"), escapeHtml(`${sf.extension || "—"} · ${sf.content_type || ""}`))}
            ${row(translate("Created"), escapeHtml(Helpers.timeFormat(sf.created_at)))}
          </div>

          <div class="flex items-center gap-2">
            <a href="${Helpers.download_company_stored_file_path(currentCompany().id, sf.id)}"
              class="flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg text-sm font-medium cursor-pointer">
              <span class="material-symbols-outlined text-[20px]">download</span>
              ${translate("Download")}
            </a>
            <button type="button" data-action="click->${this.identifier}#deleteFile"
              class="flex items-center gap-2 px-4 py-2 bg-danger hover:bg-danger/90 text-danger-foreground rounded-lg text-sm font-medium cursor-pointer">
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
