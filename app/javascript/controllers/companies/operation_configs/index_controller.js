import Companies_LayoutController from "controllers/companies/layout_controller"

// Companies_OperationConfigs_IndexController — company-wide Operation config list.
// Depends on BE: Companies::OperationConfigsController#index
// Endpoints: GET /companies/:company_id/operation_configs(.json?q=&operation_type=&workflow_status=&resolution=)
export default class Companies_OperationConfigs_IndexController extends Companies_LayoutController {
  /** @type {any[]} */ operationConfigs = []

  /** @type {any} */ filters = {}

  async connect() {
    super.connect()

    try {
      const urlParams = new URLSearchParams(window.location.search)
      const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
      this.operationConfigs = response.operation_configs || []
      this.filters = response.filters || {}
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load operation configs")}${detail ? ": " + detail : ""}` })
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  translatedOptions(options) {
    return (options || []).map(option => ({ value: option.value, name: translate(option.name) }))
  }

  contentHTML() {
    const urlParams = new URLSearchParams(window.location.search)

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-4 bg-card rounded-xl border border-line flex flex-col gap-5">
          <div class="flex flex-col gap-1">
            <h2 class="text-xl font-bold text-foreground">${translate("Operation Configs")}</h2>
            <p class="text-sm text-muted-foreground">${translate("Company-wide operation settings. Saving a config here resets every branch and warehouse config.")}</p>
          </div>

          <form method="get" action="${pathname()}" class="flex flex-wrap items-end gap-3">
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Search")}</label>
              <input type="text" name="q" value="${Helpers.escapeHtml(urlParams.get("q") || "")}" placeholder="${translate("Search operation configs...")}" class="pl-3 pr-3 py-2 text-sm border border-line rounded-lg bg-card text-foreground">
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Type")}</label>
              <select name="operation_type" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                ${selectOptionsHTML(this.translatedOptions(this.filters.operation_types), urlParams.get("operation_type"), translate("All"))}
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Status")}</label>
              <select name="workflow_status" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                ${selectOptionsHTML(this.translatedOptions(this.filters.statuses), urlParams.get("workflow_status"), translate("All"))}
              </select>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-[10px] font-bold text-muted-foreground uppercase ml-1">${translate("Resolution")}</label>
              <select name="resolution" class="pl-3 pr-10 py-2 text-sm border border-line rounded-lg bg-card text-muted-foreground">
                ${selectOptionsHTML(this.translatedOptions(this.filters.resolutions), urlParams.get("resolution"), translate("All"))}
              </select>
            </div>
            <button type="submit" class="h-[38px] px-6 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm flex items-center gap-2 cursor-pointer">
              <span class="material-symbols-outlined text-[18px]!">search</span>
              ${translate("Search")}
            </button>
          </form>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-line">
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Operation")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Type")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Resolution")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Access Roles")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Status")}</th>
                  <th class="text-left py-4 px-6 font-semibold text-foreground">${translate("Locations")}</th>
                  <th class="text-right py-4 px-6 font-semibold text-foreground w-24">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody>
                ${this.operationConfigs.length === 0
                  ? `<tr><td colspan="7" class="py-8 text-center text-muted-foreground">${translate("No operation configs found.")}</td></tr>`
                  : this.operationConfigs.map(operationConfig => this.rowHTML(operationConfig)).join("")}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `
  }

  rowHTML(operationConfig) {
    const companyId = currentCompany().id
    const roles = Array.isArray(operationConfig.metadata?.roles) ? operationConfig.metadata.roles : []
    const appointmentCount = (operationConfig.branch_appointment_count || 0) + (operationConfig.operation_warehouse_appointment_count || 0)

    return `
      <tr class="border-b border-line hover:bg-muted/50">
        <td class="py-4 px-6">
          <a href="${Helpers.company_operation_config_path(companyId, operationConfig.id)}"
            class="font-medium text-foreground hover:text-primary transition-colors cursor-pointer">
            ${Helpers.escapeHtml(operationConfig.name || translate("Unnamed Operation"))}
          </a>
          <p class="font-mono text-xs text-muted-foreground">${Helpers.escapeHtml(operationConfig.code || "—")}</p>
        </td>
        <td class="py-4 px-6 text-muted-foreground">${Helpers.escapeHtml((operationConfig.operation_type || "—").replace(/_/g, " ").toUpperCase())}</td>
        <td class="py-4 px-6 text-muted-foreground">${Helpers.escapeHtml(operationConfig.resolution || "—")}</td>
        <td class="py-4 px-6">
          ${roles.length === 0
            ? `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-muted text-muted-foreground border border-line">${translate("All roles")}</span>`
            : roles.map(role => `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary mr-1">${Helpers.escapeHtml(role)}</span>`).join("")}
        </td>
        <td class="py-4 px-6">${Helpers.statusBadge(operationConfig.workflow_status)}</td>
        <td class="py-4 px-6 text-muted-foreground">${appointmentCount}</td>
        <td class="py-4 px-6 text-right whitespace-nowrap">
          <a href="${Helpers.edit_company_operation_config_path(companyId, operationConfig.id)}"
            class="inline-flex items-center justify-center p-2 text-muted-foreground hover:text-primary hover:bg-primary/10 rounded-lg cursor-pointer" ${tooltip(translate("Edit Config"))}>
            <span class="material-symbols-outlined text-[20px]">edit</span>
          </a>
        </td>
      </tr>
    `
  }
}
