import Companies_LayoutController from "controllers/companies/layout_controller"

// Companies_OperationConfigs_ShowController — company-wide Operation config details.
// Depends on BE: Companies::OperationConfigsController#show
// Endpoints: GET /companies/:company_id/operation_configs/:id(.json)
export default class Companies_OperationConfigs_ShowController extends Companies_LayoutController {
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
    const roles = Array.isArray(c.metadata?.roles) ? c.metadata.roles : []
    const appointmentCount = (c.branch_appointment_count || 0) + (c.operation_warehouse_appointment_count || 0)

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-card rounded-xl border border-line">
          <a href="${Helpers.company_operation_configs_path(companyId)}" class="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground mb-6">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Operation Configs")}
          </a>

          <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between mb-6">
            <div class="flex items-start gap-4">
              <div class="flex size-14 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary">
                <span class="material-symbols-outlined text-3xl">description</span>
              </div>
              <div>
                <p class="text-xs font-bold uppercase text-muted-foreground">${translate("Operation Config")}</p>
                <h2 class="text-2xl font-black text-foreground">${Helpers.escapeHtml(c.name || translate("Unnamed Operation"))}</h2>
                <p class="font-mono text-sm text-muted-foreground">${Helpers.escapeHtml(c.code || "—")}</p>
              </div>
            </div>
            <div class="flex flex-wrap gap-2">
              ${Helpers.statusBadge(c.workflow_status)}
            </div>
          </div>

          <div class="rounded-lg border border-warning/20 bg-warning/10 p-3 text-xs text-warning mb-6">
            ${translate("Saving config here resets every branch and warehouse config.")}
          </div>

          <div class="grid grid-cols-1 gap-4 border-t border-line pt-6 sm:grid-cols-2 lg:grid-cols-3">
            <div class="rounded-lg border border-line bg-background p-4">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Type")}</p>
              <p class="text-sm font-semibold text-foreground">${Helpers.escapeHtml((c.operation_type || "—").replace(/_/g, " ").toUpperCase())}</p>
            </div>


            <div class="rounded-lg border border-line bg-background p-4">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Locations")}</p>
              <p class="text-sm font-semibold text-foreground">${appointmentCount}</p>
            </div>

            <div class="rounded-lg border border-line bg-background p-4">
              <p class="text-[10px] font-bold uppercase text-muted-foreground">${translate("Access Roles")}</p>
              <div class="mt-1 flex flex-wrap gap-1">
                ${roles.length === 0
                  ? `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-muted text-muted-foreground border border-line">${translate("All roles")}</span>`
                  : roles.map(role => `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary">${Helpers.escapeHtml(role)}</span>`).join("")}
              </div>
            </div>
          </div>

          <div class="mt-8 flex justify-end gap-3 pt-6 border-t border-line">
            <a href="${Helpers.edit_company_operation_config_path(companyId, c.id)}"
              class="inline-flex items-center px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-medium text-sm transition-colors cursor-pointer">
              ${translate("Edit Config")}
            </a>
          </div>
        </div>
      </div>
    `
  }
}
