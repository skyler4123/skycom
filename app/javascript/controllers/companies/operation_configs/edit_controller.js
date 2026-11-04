import Companies_LayoutController from "controllers/companies/layout_controller"

// Companies_OperationConfigs_EditController — company-wide Operation metadata editor.
// Depends on BE: Companies::OperationConfigsController#show (load) + #update
// Endpoints: GET /companies/:company_id/operation_configs/:id(.json),
//            PATCH /companies/:company_id/operation_configs/:id
export default class Companies_OperationConfigs_EditController extends Companies_LayoutController {
  /** @type {any | null} */ operationConfig = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const companyId = pathParts[2]
    const operationConfigId = pathParts[4]

    try {
      const response = await fetchJson(`${Helpers.company_operation_config_path(companyId, operationConfigId)}.json`)
      this.operationConfig = response.operation_config

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load operation config.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const c = this.operationConfig
    if (!c) return `<div class="p-8 text-center">${translate("Operation config not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const metadata = JSON.stringify(c.metadata || {}, null, 2)

    const fields = `
      <div class="space-y-5">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Edit Config")}</h2>
          <p class="text-sm text-muted-foreground">${Helpers.escapeHtml(c.name || "")}</p>
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div class="rounded-lg border border-line bg-card p-3">
            <p class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Type")}</p>
            <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml((c.operation_type || "—").replace(/_/g, " ").toUpperCase())}</p>
          </div>
          <div class="rounded-lg border border-line bg-card p-3">
            <p class="text-[10px] font-bold text-muted-foreground uppercase">${translate("Resolution")}</p>
            <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml(c.resolution || "—")}</p>
          </div>
        </div>

        <div class="rounded-lg border border-warning/20 bg-warning/10 p-3 text-xs text-warning">
          ${translate("This config is company-wide and overrides every branch/warehouse appointment config.")}
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground">${translate("Metadata (JSON)")}</label>
          <textarea name="metadata" rows="10"
            class="w-full px-3 py-2 font-mono text-xs border border-line rounded-lg bg-card text-foreground focus:ring-2 focus:ring-primary outline-none">${Helpers.escapeHtml(metadata)}</textarea>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_operation_config_path(companyId, c.id)}"
            class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_operation_config_path(companyId, c.id),
          method: "PATCH",
          attributes: `class="p-6 bg-card rounded-xl border border-line max-w-3xl" data-action="submit->${this.identifier}#handleSubmit"`,
          html: fields
        })}
      </div>
    `
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

    const companyId = window.location.pathname.split("/")[2]
    const operationConfigId = window.location.pathname.split("/")[4]

    try {
      const response = await fetchJson(Helpers.company_operation_config_path(companyId, operationConfigId), {
        method: "PATCH",
        body: { operation: { metadata } }
      })
      navigateThenToast(Helpers.company_operation_config_path(companyId, operationConfigId), {
        type: "success",
        message: response.message
      })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to update operation config.") })
    }
  }
}
