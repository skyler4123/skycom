import { Controller } from "@hotwired/stimulus"

export default class Companies_OperationConfigs_EditModalController extends Controller {
  /** @type {any | null} */ operationConfig = null

  connect() {
    this.operationConfig = window.currentOperationConfig
    if (this.operationConfig) this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    const operationConfig = this.operationConfig
    const metadata = JSON.stringify(operationConfig.metadata || {}, null, 2)
    const url = Helpers.company_operation_config_path(currentCompany().id, operationConfig.id)

    const fields = `
      <div class="space-y-5">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Edit Config")}</h2>
          <p class="text-sm text-muted-foreground">${Helpers.escapeHtml(operationConfig.name || "")}</p>
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div class="rounded-lg border border-line bg-card p-3">
            <p class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Type")}</p>
            <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml((operationConfig.operation_type || "—").replace(/_/g, " ").toUpperCase())}</p>
          </div>
          <div class="rounded-lg border border-line bg-card p-3">
            <p class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Resolution")}</p>
            <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml(operationConfig.resolution || "—")}</p>
          </div>
        </div>

        <div class="rounded-lg border border-warning/20 bg-warning/10 p-3 text-xs text-warning">
          ${translate("This config is company-wide and overrides every branch/warehouse appointment config.")}
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Metadata (JSON)")}</label>
          <textarea name="metadata" rows="8"
            class="w-full px-3 py-2 font-mono text-xs border border-line rounded-lg bg-card text-foreground focus:ring-2 focus:ring-primary outline-none">${Helpers.escapeHtml(metadata)}</textarea>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->${this.identifier}#close"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </button>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save")}
          </button>
        </div>
      </div>
    `

    return form({
      action: url,
      method: "PATCH",
      attributes: `class="p-6 bg-card rounded-xl border border-line w-[520px] max-w-full" data-action="submit->${this.identifier}#handleSubmit"`,
      html: fields
    })
  }

  async handleSubmit(event) {
    event.preventDefault()

    let metadata
    try {
      metadata = JSON.parse(new FormData(event.target).get("metadata") || "{}")
    } catch {
      toast({ type: "error", message: translate("Invalid JSON") })
      return
    }

    try {
      const response = await fetchJson(Helpers.company_operation_config_path(currentCompany().id, this.operationConfig.id), {
        method: "PATCH",
        body: { operation: { metadata } }
      })
      reloadThenToast({ type: "success", message: response.message })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update operation config.") })
    }
  }

  close(event) {
    event.preventDefault()
    closeModal()
  }
}
